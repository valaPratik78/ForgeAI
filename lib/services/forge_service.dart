import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/generation_model.dart';
import '../config/api_config.dart';

/// Specialized service for handling generation-specific API calls.
/// Maps backend JSON responses to the [GenerationResponse] model.
class ForgeService {
  Future<GenerationResponse> generateApplication(
      GenerationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return GenerationResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to generate application. Status: ${response.statusCode}, '
            'Response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to ForgeAI backend: $e');
    }
  }

  /// Poll the status of a project generation
  Future<GenerationResponse> getJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.jobUrl(jobId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return GenerationResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to get job status. Status: ${response.statusCode}, '
            'Response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching job status: $e');
    }
  }

  /// Poll the status of a project generation (Deprecated: Use getJobStatus)
  Future<GenerationResponse> getProjectStatus(String projectId) async {
    // Legacy support or redirects if needed
    return getJobStatus(projectId);
  }

  /// Fetch list of available pre-built templates
  Future<List<TemplateInfo>> fetchTemplates() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.templatesUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((item) => TemplateInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        return _getDefaultTemplates();
      }
    } catch (_) {
      return _getDefaultTemplates();
    }
  }

  List<TemplateInfo> _getDefaultTemplates() {
    const allPages = [
      'index.html',
      'about.html',
      'services.html',
      'features.html',
      'pricing.html',
      'projects.html',
      'articles.html',
      'contact.html',
    ];

    return [
      TemplateInfo(
        id: 'startup',
        name: 'Startup & SaaS',
        description:
            'High-conversion modern SaaS landing page with vibrant gradients, metrics, feature cards, and CTA.',
        category: 'SaaS / Startup',
        availablePages: allPages,
        tags: ['Light Theme', 'Animated Gradients', 'Multi-Page', 'Modern SaaS'],
        previewUrl: ApiConfig.templatePreviewUrl('startup'),
      ),
      TemplateInfo(
        id: 'portfolio',
        name: 'Modern Portfolio',
        description:
            'Ultra-sleek dark theme creative portfolio showcasing projects, skill radar, biography, and inquiries.',
        category: 'Portfolio',
        availablePages: allPages,
        tags: ['Dark Aesthetic', 'Project Gallery', 'Skills Display', 'Personal Brand'],
        previewUrl: ApiConfig.templatePreviewUrl('portfolio'),
      ),
      TemplateInfo(
        id: 'business',
        name: 'Corporate Business',
        description:
            'Clean enterprise corporate presence emphasizing trust, organizational impact, leadership, and services.',
        category: 'Business',
        availablePages: allPages,
        tags: ['Clean Corporate', 'Enterprise', 'High Trust', 'Minimalist'],
        previewUrl: ApiConfig.templatePreviewUrl('business'),
      ),
      TemplateInfo(
        id: 'landing-page',
        name: 'Conversion Funnel',
        description:
            'Focused landing page with compelling hero, feature matrix, pricing tiers, and direct conversion hooks.',
        category: 'Landing Page',
        availablePages: allPages,
        tags: ['High Conversion', 'Pricing Table', 'Sales Funnel', 'Lead Capture'],
        previewUrl: ApiConfig.templatePreviewUrl('landing-page'),
      ),
      TemplateInfo(
        id: 'product-page',
        name: 'Product Showcase',
        description:
            'Interactive hardware and digital product showcase with technical specifications, benefits, and pricing.',
        category: 'Product Page',
        availablePages: allPages,
        tags: ['Product Focus', 'Spec Breakdown', 'Modern UI', 'Interactive'],
        previewUrl: ApiConfig.templatePreviewUrl('product-page'),
      ),
      TemplateInfo(
        id: 'blog',
        name: 'Editorial & Blog',
        description:
            'Typography-focused publication theme with article showcases, author profiles, and reading layout.',
        category: 'Blog',
        availablePages: allPages,
        tags: ['Editorial', 'Article Index', 'Clean Typography', 'Content First'],
        previewUrl: ApiConfig.templatePreviewUrl('blog'),
      ),
    ];
  }
}
