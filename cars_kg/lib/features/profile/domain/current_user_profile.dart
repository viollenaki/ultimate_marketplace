class CurrentUserProfile {
  const CurrentUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
  });

  final int id;
  final String email;
  final String fullName;
  final String? profileImageUrl;

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return CurrentUserProfile(
      id: idRaw is int ? idRaw : (idRaw as num).toInt(),
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}
