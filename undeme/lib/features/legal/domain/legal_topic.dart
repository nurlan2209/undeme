class LegalTopic {
  LegalTopic({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
  });

  final String id;
  final String category;
  final String title;
  final String description;

  factory LegalTopic.fromJson(Map<String, dynamic> json) {
    return LegalTopic(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
