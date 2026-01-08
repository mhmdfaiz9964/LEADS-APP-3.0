class BusinessProfile {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String workingHours;
  final String? logoUrl;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.workingHours,
    this.logoUrl,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> data, String id) {
    return BusinessProfile(
      id: id,
      businessName: data['businessName'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      workingHours: data['workingHours'] ?? '',
      logoUrl: data['logoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'workingHours': workingHours,
      'logoUrl': logoUrl,
    };
  }
}
