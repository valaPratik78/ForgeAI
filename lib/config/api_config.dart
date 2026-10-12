/// Configuration class for API-related constants
library;

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// The base URL for the backend API
  /// Publicly deployed URL: https://breakable-hedwig-bb121-194c7ef8.koyeb.app/
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://breakable-hedwig-bb121-194c7ef8.koyeb.app';
    }
    // Use localhost for local development.
    // Note: For Android Emulator, you might need to use 'http://10.0.2.2:8080'
    return 'http://localhost:8080';
  }

  /// Endpoint for generating a project
  static const String generateEndpoint = '/api/generate';

  /// Get the full URL for the generate project endpoint
  static String get generateUrl => '$baseUrl$generateEndpoint';

  /// Get the preview URL for a project (always points to index.html)
  static String previewUrl(String projectId) =>
      '$baseUrl/api/projects/$projectId/preview/index.html';

  /// Get the edit endpoint for a project
  static String editUrl(String projectId) =>
      '$baseUrl/api/projects/$projectId/edit';

  /// Get the status endpoint for polling project generation status
  static String statusUrl(String projectId) =>
      '$baseUrl/api/project/$projectId/status';

  /// Get the job status endpoint
  static String jobUrl(String jobId) => '$baseUrl/api/jobs/$jobId';

  /// Get the download URL (ZIP) for a project
  static String downloadUrl(String projectId) =>
      '$baseUrl/api/projects/$projectId/download';

  /// Endpoint for fetching available pre-built templates
  static String get templatesUrl => '$baseUrl/api/templates';

  /// Get the preview URL for a pre-built template
  static String templatePreviewUrl(String templateId) =>
      '$baseUrl/api/templates/$templateId/preview/index.html';
}
