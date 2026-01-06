/// Building entity (Domain layer - pure Dart, no dependencies)
/// Represents a physical property containing rental units
class Building {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? postalCode;
  final String country;
  final int totalUnits;
  final String? photoUrl;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Building({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.postalCode,
    this.country = "Côte d'Ivoire",
    this.totalUnits = 0,
    this.photoUrl,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Full formatted address for display
  String get fullAddress {
    final parts = <String>[address, city];
    if (postalCode != null && postalCode!.isNotEmpty) {
      parts.add(postalCode!);
    }
    parts.add(country);
    return parts.join(', ');
  }

  /// Short address (street and city only)
  String get shortAddress => '$address, $city';

  /// Check if building has units (prevents deletion)
  bool get hasUnits => totalUnits > 0;

  /// Check if building has a photo
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Copy with modified fields
  Building copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    int? totalUnits,
    String? photoUrl,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Building(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      totalUnits: totalUnits ?? this.totalUnits,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Building &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          city == other.city &&
          postalCode == other.postalCode &&
          country == other.country &&
          totalUnits == other.totalUnits &&
          photoUrl == other.photoUrl &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      city.hashCode ^
      totalUnits.hashCode;

  @override
  String toString() {
    return 'Building{id: $id, name: $name, city: $city, totalUnits: $totalUnits}';
  }
}
