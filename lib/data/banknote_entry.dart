class BanknoteEntry {
  final String id;
  final String countryCode; // like "TR", "JP"
  final String imagePath;   // local file path to the saved image
  final DateTime date;      // when collected
  final String circulationStart; // ISO date when banknote began circulation (optional)
  final String circulationEnd; // ISO date when banknote ended circulation (optional)
  final String notes;       // description / details
  final String denomination; // New: Optional (e.g., "100 USD")

  BanknoteEntry({
    required this.id,
    required this.countryCode,
    required this.imagePath,
    required this.date,
    this.circulationStart = '',
    this.circulationEnd = '',
    required this.notes,
    this.denomination = '', // New: default to empty string
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryCode': countryCode,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'circulationStart': circulationStart,
      'circulationEnd': circulationEnd,
      'notes': notes,
      'denomination': denomination, // New
    };
  }

  factory BanknoteEntry.fromMap(Map map) {
    return BanknoteEntry(
      id: map['id'],
      countryCode: map['countryCode'],
      imagePath: map['imagePath'],
      date: DateTime.parse(map['date']),
      circulationStart: map['circulationStart'] ?? '',
      circulationEnd: map['circulationEnd'] ?? '',
      notes: map['notes'],
      denomination: map['denomination'] ?? '', // Handle older entries
    );
  }
}