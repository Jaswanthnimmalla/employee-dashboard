class HolidayModel {
  final String name;
  final String date;
  final String day;
  final String type;

  HolidayModel({
    required this.name,
    required this.date,
    required this.day,
    required this.type,
    required description,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      name: json['name'] ?? 'Holiday',
      date: json['date'] ?? '2024-03-25',
      day: json['day'] ?? 'Monday',
      type: json['type'] ?? 'Public Holiday',
      description: null,
    );
  }
}
