import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'package:flutter/material.dart';

class MainServices {
  Future<Map<String, dynamic>?> getLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/releases/latest'),
        headers: ApiConstants.getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> checkVersionExists(int version) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/releases/$version'),
        headers: ApiConstants.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getMenu() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/menu/main-menu'),
        headers: ApiConstants.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['items'] ?? [];
      }
      return [];
    } catch (e) {
      print("Lỗi lấy menu: $e");
      return [];
    }
  }

  Future<List<dynamic>> getFeaturedVideos(String moduleId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/carousels?module_id=$moduleId&page=1&limit=20',
        ),
        headers: ApiConstants.getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi: $e");
      return [];
    }
  }

  Future<List<dynamic>> getPlaylists(String moduleId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/movie-playlists?module_id=$moduleId&page=1&limit=10',
        ),
        headers: ApiConstants.getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi lấy playlists: $e");
      return [];
    }
  }

  Future<List<dynamic>> getVideosByPlaylist(String playlistId, int page) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/movie-playlists/$playlistId/movies?page=$page&limit=10',
        ),
        headers: ApiConstants.getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['results'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi lấy movies playlist $playlistId: $e");
      return [];
    }
  }
}
