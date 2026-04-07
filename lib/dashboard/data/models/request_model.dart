class RequestModel {
  final String id;
  final String title;
  final String type;
  final String date;
  final String status;
  final String description;

  RequestModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.status,
    required this.description,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Request Title',
      type: json['type'] ?? 'General',
      date: json['date'] ?? '2024-03-10',
      status: json['status'] ?? 'Pending',
      description: json['description'] ?? 'No description provided',
    );
  }
}
