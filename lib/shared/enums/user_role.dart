enum UserRole {
  customer('customer'),
  vendor('vendor'),
  admin('admin'),
  superAdmin('superadmin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.customer;
    switch (role.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superAdmin;
      case 'vendor':
        return UserRole.vendor;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  bool get isStaff => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isAdmin => this == UserRole.admin;
  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isCustomer => this == UserRole.customer;
  bool get isVendor => this == UserRole.vendor;
}
