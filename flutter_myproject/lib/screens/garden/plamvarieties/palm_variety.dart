class PalmVariety {
  final String varietyId;
  final String varietyName;
  final String? scientificName;

  PalmVariety({
    required this.varietyId,
    required this.varietyName,
    this.scientificName,
  });

  factory PalmVariety.fromJson(Map<String, dynamic> json) => PalmVariety(
        varietyId: (json['variety_id'] ?? '').toString(),
        varietyName: (json['variety_name'] ?? '').toString(),
        scientificName: json['scientific_name']?.toString(),
      );
}