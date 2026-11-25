import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/estimator_model.dart';

class EstimatorRepository {
  static const _quotesKey = 'saved_interior_quotes_cache';

  /// Fetches package configs from Firestore `estimator_packages` collection.
  /// If Firestore is empty, attempts to dynamically load images from Firebase Storage `packages/`
  /// and seeds Firestore for subsequent loads.
  /// Falls back to [PackageConfig.allPackages] if offline or unavailable.
  Future<List<PackageConfig>> fetchPackages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('estimator_packages')
          .orderBy('order')
          .get()
          .timeout(const Duration(seconds: 6));

      if (snapshot.docs.isNotEmpty) {
        final results = <PackageConfig>[];
        for (final doc in snapshot.docs) {
          try {
            final package = PackageConfig.fromFirestore(doc.id, doc.data());
            final fallback = PackageConfig.allPackages.firstWhere(
              (item) => item.id == package.id,
              orElse: () => PackageConfig.allPackages.first,
            );
            final coverImage = await _resolveStorageImage(
              package.imageAsset,
              fallback: fallback.imageAsset,
            );
            final images = <String>[];
            for (var index = 0; index < package.images.length; index++) {
              final resolved = await _resolveStorageImage(
                package.images[index],
                fallback: fallback.images[index % fallback.images.length],
              );
              images.add(resolved);
            }

            results.add(
              PackageConfig(
                id: package.id,
                title: package.title,
                ratePerSqFt: package.ratePerSqFt,
                imageAsset: coverImage,
                images: images.isEmpty ? [coverImage] : images,
                description: package.description,
                order: package.order,
              ),
            );
          } catch (e) {
            debugPrint('Failed to parse package doc ${doc.id}: $e');
          }
        }

        if (results.isNotEmpty) {
          if (results.any((package) => package.images.length <= 1)) {
            final storagePackages = await _fetchPackagesFromStorageDirectly();
            final storagePackagesById = {
              for (final package in storagePackages)
                if (package.images.any(_isRemoteImage)) package.id: package,
            };

            return results.map((package) {
              final storagePackage = storagePackagesById[package.id];
              if (storagePackage == null) return package;

              final images = <String>{
                ...storagePackage.images,
                ...package.images.where(_isRemoteImage),
              }.toList();
              return PackageConfig(
                id: package.id,
                title: package.title,
                ratePerSqFt: package.ratePerSqFt,
                imageAsset: images.first,
                images: images,
                description: package.description,
                order: package.order,
              );
            }).toList();
          }
          return results;
        }
      }
    } on FirebaseException catch (error) {
      debugPrint('Firestore fetch packages failed, trying Storage: $error');
      if (error.code == 'no-app') {
        return List<PackageConfig>.from(PackageConfig.allPackages);
      }
    } catch (error) {
      debugPrint('Firestore fetch packages failed, trying Storage: $error');
    }

    // Firestore was empty or failed — try loading directly from Firebase Storage `packages/`
    return await _fetchPackagesFromStorageDirectly();
  }

  /// Dynamically inspects package folders in Firebase Storage and seeds
  /// Firestore with every image found in each package folder.
  Future<List<PackageConfig>> _fetchPackagesFromStorageDirectly() async {
    if (!Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
      return List<PackageConfig>.from(PackageConfig.allPackages);
    }

    try {
      final results = <PackageConfig>[];
      final packageFolders = await _findPackageStorageFolders();
      for (var index = 0; index < PackageConfig.allPackages.length; index++) {
        final basePackage = PackageConfig.allPackages[index];
        final packageFolder = packageFolders[basePackage.id];
        if (packageFolder == null) {
          results.add(basePackage);
          continue;
        }

        final imageItems = await _listPackageImages(packageFolder);
        final imageUrls = await Future.wait(
          imageItems.map((item) async {
            try {
              return await item.getDownloadURL();
            } catch (error) {
              debugPrint('Failed to get URL for ${item.fullPath}: $error');
              return null;
            }
          }),
        );
        final images = imageUrls.whereType<String>().toList();
        if (images.isEmpty) {
          results.add(basePackage);
          continue;
        }

        final package = PackageConfig(
          id: basePackage.id,
          title: basePackage.title,
          ratePerSqFt: basePackage.ratePerSqFt,
          imageAsset: images.first,
          images: images,
          description: basePackage.description,
          order: index,
        );
        results.add(package);
        _seedPackageToFirestore(package);
      }

      return results.isNotEmpty
          ? results
          : List<PackageConfig>.from(PackageConfig.allPackages);
    } catch (e) {
      debugPrint('Failed to load packages directly from Storage: $e');
      return List<PackageConfig>.from(PackageConfig.allPackages);
    }
  }

  Future<Map<String, Reference>> _findPackageStorageFolders() async {
    final storage = FirebaseStorage.instance;
    final searchRoots = [
      storage.ref('estimator_packages'),
      storage.ref('packages'),
      storage.ref(),
    ];
    final matches = <String, Reference>{};

    void collectMatches(List<Reference> folders) {
      for (final package in PackageConfig.allPackages) {
        if (matches.containsKey(package.id)) continue;
        final folder = _findMatchingPackageFolder(folders, package.id);
        if (folder != null) matches[package.id] = folder;
      }
    }

    for (final root in searchRoots) {
      try {
        final result = await root.listAll().timeout(
          const Duration(seconds: 10),
        );
        collectMatches(result.prefixes);

        for (final wrapper in result.prefixes.where(
          (folder) => _isPackageWrapper(folder.name),
        )) {
          if (matches.length == PackageConfig.allPackages.length) break;
          try {
            final nested = await wrapper.listAll().timeout(
              const Duration(seconds: 10),
            );
            collectMatches(nested.prefixes);
          } catch (error) {
            debugPrint(
              'Failed to inspect Storage folder ${wrapper.fullPath}: $error',
            );
          }
        }
      } catch (error) {
        debugPrint('Failed to list Storage folder ${root.fullPath}: $error');
      }
      if (matches.length == PackageConfig.allPackages.length) break;
    }

    return matches;
  }

  Reference? _findMatchingPackageFolder(
    List<Reference> folders,
    String packageId,
  ) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final normalizedId = normalize(packageId);
    for (final folder in folders) {
      final name = normalize(folder.name);
      if (name == normalizedId || name == '${normalizedId}package') {
        return folder;
      }
    }
    return null;
  }

  bool _isPackageWrapper(String name) {
    final normalized = name.toLowerCase();
    return normalized.contains('package') ||
        normalized.contains('furniture') ||
        normalized.contains('interior') ||
        normalized.contains('fi');
  }

  Future<List<Reference>> _listPackageImages(Reference folder) async {
    const imageExtensions = {
      '.avif',
      '.bmp',
      '.gif',
      '.jpeg',
      '.jpg',
      '.png',
      '.webp',
    };
    const categoryPriority = [
      'sofa',
      'tv unit',
      'tv',
      'bed',
      'kitchen',
      'dining',
      'wardrobe',
      'temple',
      'center table',
      'dressing table',
      'study table',
    ];

    final contents = await folder.listAll().timeout(
      const Duration(seconds: 10),
    );
    final images =
        contents.items
            .where(
              (item) => imageExtensions.any(
                (extension) => item.name.toLowerCase().endsWith(extension),
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final subfolders = List<Reference>.from(contents.prefixes)
      ..sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aIndex = categoryPriority.indexWhere(aName.contains);
        final bIndex = categoryPriority.indexWhere(bName.contains);
        final aRank = aIndex == -1 ? categoryPriority.length : aIndex;
        final bRank = bIndex == -1 ? categoryPriority.length : bIndex;
        final rankComparison = aRank.compareTo(bRank);
        return rankComparison != 0 ? rankComparison : aName.compareTo(bName);
      });

    for (final subfolder in subfolders) {
      images.addAll(await _listPackageImages(subfolder));
    }
    return images;
  }

  bool _isRemoteImage(String image) =>
      image.startsWith('http://') || image.startsWith('https://');

  void _seedPackageToFirestore(PackageConfig pkg) {
    FirebaseFirestore.instance
        .collection('estimator_packages')
        .doc(pkg.id)
        .set({
          'title': pkg.title,
          'ratePerSqFt': pkg.ratePerSqFt,
          'description': pkg.description,
          'order': pkg.order,
          'coverImagePath': pkg.imageAsset,
          'imagePaths': pkg.images,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((e) {
          debugPrint('Silent firestore seed error for ${pkg.id}: $e');
        });
  }

  Future<String> _resolveStorageImage(
    String imagePath, {
    required String fallback,
  }) async {
    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('assets/')) {
      return imagePath;
    }

    try {
      final storageReference = imagePath.startsWith('gs://')
          ? FirebaseStorage.instance.refFromURL(imagePath)
          : FirebaseStorage.instance.ref(imagePath);
      return await storageReference.getDownloadURL();
    } catch (_) {
      try {
        if (!imagePath.startsWith('packages/')) {
          return await FirebaseStorage.instance
              .ref('packages/$imagePath')
              .getDownloadURL();
        }
      } catch (_) {}
      debugPrint(
        'Failed to resolve estimator image "$imagePath" from Firebase Storage, using fallback.',
      );
      return fallback;
    }
  }

  EstimatorQuote calculateEstimate({
    required String quoteName,
    required String bhk,
    required String purpose,
    required String packageId,
    required List<PackageConfig> packages,
  }) {
    final bhkConfig = BhkConfig.allConfigs.firstWhere(
      (c) => c.bhk.toUpperCase() == bhk.toUpperCase(),
      orElse: () => BhkConfig.allConfigs.first,
    );

    final purposeInfo = EstimatorPurposeInfo.allPurposes.firstWhere(
      (p) => p.id.toLowerCase() == purpose.toLowerCase(),
      orElse: () => EstimatorPurposeInfo.allPurposes.first,
    );

    final availablePackages = packages.isNotEmpty
        ? packages
        : PackageConfig.allPackages;
    final package = availablePackages.firstWhere(
      (pkg) => pkg.id.toLowerCase() == packageId.toLowerCase(),
      orElse: () => availablePackages.length > 1
          ? availablePackages[1]
          : availablePackages.first,
    );

    final area = bhkConfig.approxAreaSqFt;
    final baseCost = area * package.ratePerSqFt;
    final multiplier = purposeInfo.multiplier;

    final estimatedAvg = baseCost * multiplier;
    final minCost = estimatedAvg * 0.90;
    final maxCost = estimatedAvg * 1.10;

    // Room breakdown (approximate percentage share)
    final roomBreakdown = <String, double>{
      'Modular Kitchen': estimatedAvg * 0.32,
      'Living & Dining': estimatedAvg * 0.28,
      'Bedrooms & Wardrobes': estimatedAvg * 0.25,
      'Bathrooms & Lighting': estimatedAvg * 0.10,
      'Civil, Paint & Electrical': estimatedAvg * 0.05,
    };

    return EstimatorQuote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      quoteName: quoteName.trim().isEmpty ? 'Quote 1' : quoteName.trim(),
      bhk: bhkConfig.bhk,
      purpose: purposeInfo.label,
      packageTitle: package.title,
      ratePerSqFt: package.ratePerSqFt,
      approxAreaSqFt: area,
      estimatedCostMin: minCost,
      estimatedCostMax: maxCost,
      createdAt: DateTime.now(),
      roomBreakdown: roomBreakdown,
    );
  }

  Future<List<EstimatorQuote>> loadSavedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_quotesKey);
      if (jsonList == null || jsonList.isEmpty) {
        // Return default starter quote for demo if empty
        return [
          EstimatorQuote(
            id: 'sample_quote_1',
            quoteName: 'Dream 2BHK Renovation',
            bhk: '2BHK',
            purpose: 'Renovate',
            packageTitle: 'Modern Package',
            ratePerSqFt: 1500,
            approxAreaSqFt: 960,
            estimatedCostMin: 1296000,
            estimatedCostMax: 1584000,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            itemsSummaryText: '14 items (Acrylic Kitchen, 3 Wardrobes...)',
            roomBreakdown: const {
              'Modular Kitchen': 460000,
              'Living & Dining': 403000,
              'Bedrooms & Wardrobes': 360000,
              'Bathrooms & Lighting': 144000,
              'Civil, Paint & Electrical': 73000,
            },
          ),
        ];
      }

      return jsonList.map((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final breakdownMap =
            (map['roomBreakdown'] as Map<String, dynamic>?) ?? {};
        final convertedBreakdown = breakdownMap.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );

        return EstimatorQuote(
          id: map['id'] as String,
          quoteName: map['quoteName'] as String,
          bhk: map['bhk'] as String,
          purpose: map['purpose'] as String,
          packageTitle: (map['packageTitle'] as String?) ?? 'Modern Package',
          ratePerSqFt: (map['ratePerSqFt'] as num?)?.toDouble() ?? 1500,
          approxAreaSqFt: (map['approxAreaSqFt'] as num?)?.toInt() ?? 960,
          estimatedCostMin: (map['estimatedCostMin'] as num).toDouble(),
          estimatedCostMax: (map['estimatedCostMax'] as num).toDouble(),
          createdAt:
              DateTime.tryParse(map['createdAt'] as String? ?? '') ??
              DateTime.now(),
          itemsSummaryText: map['itemsSummaryText'] as String?,
          roomBreakdown: convertedBreakdown,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQuote(EstimatorQuote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await loadSavedQuotes();
      // Remove any with same id
      quotes.removeWhere((q) => q.id == quote.id);
      quotes.insert(0, quote);

      final encoded = quotes
          .map(
            (q) => jsonEncode({
              'id': q.id,
              'quoteName': q.quoteName,
              'bhk': q.bhk,
              'purpose': q.purpose,
              'packageTitle': q.packageTitle,
              'ratePerSqFt': q.ratePerSqFt,
              'approxAreaSqFt': q.approxAreaSqFt,
              'estimatedCostMin': q.estimatedCostMin,
              'estimatedCostMax': q.estimatedCostMax,
              'createdAt': q.createdAt.toIso8601String(),
              'itemsSummaryText': q.itemsSummaryText,
              'roomBreakdown': q.roomBreakdown,
            }),
          )
          .toList();

      await prefs.setStringList(_quotesKey, encoded);
    } catch (error, stackTrace) {
      debugPrint('Failed to save estimator quote: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await loadSavedQuotes();
      quotes.removeWhere((q) => q.id == quoteId);

      final encoded = quotes
          .map(
            (q) => jsonEncode({
              'id': q.id,
              'quoteName': q.quoteName,
              'bhk': q.bhk,
              'purpose': q.purpose,
              'packageTitle': q.packageTitle,
              'ratePerSqFt': q.ratePerSqFt,
              'approxAreaSqFt': q.approxAreaSqFt,
              'estimatedCostMin': q.estimatedCostMin,
              'estimatedCostMax': q.estimatedCostMax,
              'createdAt': q.createdAt.toIso8601String(),
              'itemsSummaryText': q.itemsSummaryText,
              'roomBreakdown': q.roomBreakdown,
            }),
          )
          .toList();

      await prefs.setStringList(_quotesKey, encoded);
    } catch (_) {}
  }
}

final estimatorRepositoryProvider = Provider<EstimatorRepository>((ref) {
  return EstimatorRepository();
});
