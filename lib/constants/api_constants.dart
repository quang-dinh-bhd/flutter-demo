class ApiConstants {
  static const String baseUrl = 'https://api.sandboxes.xyz/v1/danet';

  static Map<String, String> getHeaders(String deviceId) {
    return {
      'x-api-key': 'cc614dc7-64c3-4a35-8933-fe5ee3f4f0f3',
      'x-platform': 'android',
      'x-device-id': deviceId,
      'Content-Type': 'application/json',
    };
  }
}
