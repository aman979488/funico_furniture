import '../../shared/enums/user_role.dart';

class FirestoreCollections {
  FirestoreCollections._();

  // Primary Collections
  static const String customers = 'customers';
  static const String vendors = 'vendors';
  static const String staff = 'staff';

  // Admin specific references
  static const String admins = 'admins';
  static const String superAdmins = 'super_admins';

  // Business & Product Collections
  static const String products = 'products';
  static const String orders = 'orders';
  static const String categories = 'categories';
  static const String carts = 'carts';
  static const String wishlists = 'wishlists';

  /// Resolves the appropriate Firestore collection name for a given [UserRole].
  static String getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customers;
      case UserRole.vendor:
        return vendors;
      case UserRole.admin:
      case UserRole.superAdmin:
        return staff;
    }
  }
}
