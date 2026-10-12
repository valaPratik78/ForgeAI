class GenerationRequest {
  final String applicationType;
  final String projectName;
  final String description;
  final String category;
  final List<String> sections;
  final String themeColor;
  final String aiModel;
  final List<String>? selectedPages;
  final Map<String, String>? pageContents;
  final String? template;
  final String? imageTheme;

  GenerationRequest({
    required this.applicationType,
    required this.projectName,
    required this.description,
    required this.category,
    required this.sections,
    required this.themeColor,
    required this.aiModel,
    this.selectedPages,
    this.pageContents,
    this.template,
    this.imageTheme,
  });

  Map<String, dynamic> toJson() {
    // Derive hex color from theme name for the AI to use directly
    final Map<String, String> colorHexMap = {
      'Blue': '#007BFF',
      'Cyan': '#00C8FF',
      'Green': '#00B87A',
      'Purple': '#7B2FFF',
      'Red': '#FF3B3B',
      'Orange': '#FF8C00',
      'Pink': '#FF2D78',
      'Indigo': '#4F46E5',
    };
    final hexColor = colorHexMap[themeColor] ?? themeColor;
    return {
      'projectName': projectName,
      'description': description,
      'category': category,
      'sections': sections,
      'themeColor': themeColor.startsWith('#') ? themeColor : '$themeColor ($hexColor)',
      'template': template ?? category.toLowerCase().replaceAll(' ', '-'),
      'aiModel': aiModel,
      if (selectedPages != null) 'selectedPages': selectedPages,
      if (pageContents != null) 'pageContents': pageContents,
      if (imageTheme != null) 'imageTheme': imageTheme,
    };
  }
}

class TemplateInfo {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> availablePages;
  final List<String> tags;
  final String previewUrl;

  TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.availablePages,
    required this.tags,
    required this.previewUrl,
  });

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      availablePages: List<String>.from(json['availablePages'] as List? ?? []),
      tags: List<String>.from(json['tags'] as List? ?? []),
      previewUrl: json['previewUrl'] as String? ?? '',
    );
  }
}

class GenerationResponse {
  final String? jobId;
  final String? projectId;
  final String status; // "QUEUED" | "PROCESSING" | "COMPLETED" | "FAILED"
  final String? message;
  final String? previewUrl;
  final String? zipUrl;
  final String? error;

  GenerationResponse({
    this.jobId,
    this.projectId,
    required this.status,
    this.message,
    this.previewUrl,
    this.zipUrl,
    this.error,
  });

  factory GenerationResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested result from backend GenerationJob
    final result = json['result'] as Map<String, dynamic>?;

    return GenerationResponse(
      jobId: json['jobId'] as String?,
      projectId: json['projectId'] as String? ?? result?['projectId'],
      status: json['status'] as String? ?? 'QUEUED',
      message: json['errorMessage'] as String? ?? result?['message'],
      previewUrl: result?['previewUrl'],
      zipUrl: result?['zipUrl'],
      error: json['errorMessage'] as String? ?? result?['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'projectId': projectId,
      'status': status,
      if (message != null) 'message': message,
      if (previewUrl != null) 'previewUrl': previewUrl,
      if (zipUrl != null) 'zipUrl': zipUrl,
      if (error != null) 'error': error,
    };
  }

  bool get isProcessing => status == 'QUEUED' || status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}
