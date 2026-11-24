import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { randomUUID } from 'node:crypto';
import { existsSync } from 'node:fs';
import { readdir, stat } from 'node:fs/promises';
import path from 'node:path';

const packages = [
  {
    id: 'basic',
    folder: 'Basic',
    title: 'Basic Package',
    order: 0,
    ratePerSqFt: 1000,
    description:
      'Essential woodwork, standard laminates, and clean finishes.',
  },
  {
    id: 'modern',
    folder: 'Modern',
    title: 'Modern Package',
    order: 1,
    ratePerSqFt: 1500,
    description:
      'Contemporary TV wall, designer ceiling, and ambient lighting.',
  },
  {
    id: 'deluxe',
    folder: 'Deluxe',
    title: 'Deluxe Package',
    order: 2,
    ratePerSqFt: 2000,
    description:
      'High-gloss acrylics, custom mandir/cabinetry, and luxury lights.',
  },
  {
    id: 'premium',
    folder: 'Premium',
    title: 'Premium Package',
    order: 3,
    ratePerSqFt: 2500,
    description:
      'Back-lit marble TV backdrop, fluted panels, and velvet seating.',
  },
  {
    id: 'luxury',
    folder: 'Luxury',
    title: 'Luxury Package',
    order: 4,
    ratePerSqFt: 3000,
    description:
      'Ultra-luxurious veneer, Italian marble, and motorized modular elements.',
  },
];

const imageExtensions = new Set([
  '.avif',
  '.bmp',
  '.gif',
  '.jpeg',
  '.jpg',
  '.png',
  '.webp',
]);

const contentTypes = {
  '.avif': 'image/avif',
  '.bmp': 'image/bmp',
  '.gif': 'image/gif',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

async function findImages(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const images = [];

  for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      images.push(...(await findImages(entryPath)));
    } else if (
      entry.isFile() &&
      imageExtensions.has(path.extname(entry.name).toLowerCase())
    ) {
      images.push(entryPath);
    }
  }

  return images;
}

async function main() {
  const sourceRoot = process.env.ESTIMATOR_IMAGES_DIR;
  const credentialPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!sourceRoot) {
    throw new Error('Set ESTIMATOR_IMAGES_DIR to the extracted Drive folder.');
  }
  if (!credentialPath || !existsSync(credentialPath)) {
    throw new Error(
      'Set GOOGLE_APPLICATION_CREDENTIALS to a local service-account JSON file.',
    );
  }

  const projectId = process.env.GCLOUD_PROJECT ?? 'funica-9a16a';
  const bucketName =
    process.env.FIREBASE_STORAGE_BUCKET ?? 'funica-9a16a.firebasestorage.app';
  const app = initializeApp({
    credential: applicationDefault(),
    projectId,
    storageBucket: bucketName,
  });
  const bucket = getStorage(app).bucket();
  const firestore = getFirestore(app);
  const resolvedSourceRoot = path.resolve(sourceRoot);

  for (const packageConfig of packages) {
    const packageFolder = path.join(resolvedSourceRoot, packageConfig.folder);
    const folderInfo = await stat(packageFolder).catch(() => null);
    if (!folderInfo?.isDirectory()) {
      throw new Error(`Missing package folder: ${packageFolder}`);
    }

    const localImages = await findImages(packageFolder);
    if (localImages.length === 0) {
      throw new Error(`No image files found under ${packageFolder}`);
    }

    const imagePaths = [];
    for (const localImage of localImages) {
      const relativePath = path
        .relative(packageFolder, localImage)
        .split(path.sep)
        .join('/');
      const storagePath = `estimator_packages/${packageConfig.id}/${relativePath}`;
      const extension = path.extname(localImage).toLowerCase();
      const downloadToken = randomUUID();

      await bucket.upload(localImage, {
        destination: storagePath,
        metadata: {
          contentType: contentTypes[extension],
          cacheControl: 'private, max-age=31536000',
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
          },
        },
      });
      imagePaths.push(storagePath);
    }

    await firestore
      .collection('estimator_packages')
      .doc(packageConfig.id)
      .set(
        {
          title: packageConfig.title,
          ratePerSqFt: packageConfig.ratePerSqFt,
          description: packageConfig.description,
          order: packageConfig.order,
          coverImagePath: imagePaths[0],
          imagePaths,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    console.log(
      `Uploaded ${imagePaths.length} images for ${packageConfig.title}.`,
    );
  }

  console.log(
    `Finished uploading estimator images to gs://${bucket.name}/estimator_packages.`,
  );
}

main().catch((error) => {
  console.error('Estimator image upload failed:', error);
  process.exitCode = 1;
});
