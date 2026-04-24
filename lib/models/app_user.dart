enum UserRole { manager, seller }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String storeId; // The glue that binds the team together

  AppUser({
    required this.uid, 
    required this.email, 
    required this.role, 
    required this.storeId
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      role: data['role'] == 'manager' ? UserRole.manager : UserRole.seller,
      storeId: data['storeId'] ?? 'unassigned',
    );
  }
}