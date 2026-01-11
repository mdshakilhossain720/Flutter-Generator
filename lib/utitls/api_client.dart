import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launguage_service.dart';
import 'request_handler.dart';
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  
  // Automatically update Accept-Local-Language from Hive
  ref.listen<AsyncValue<String>>(currentLanguageProvider, (previous, next) {
    next.whenData((lang) {
      client.updateLocalLanguage(language: lang);
    });
  });

  return client;
});

class ApiClient {
  final Dio _dio = Dio();

  ApiClient() {
    ApiInterceptors.addInterceptors(_dio);
  }

  Map<String, dynamic> defaultHeaders = {
    HttpHeaders.authorizationHeader: null,
    HttpHeaders.acceptLanguageHeader: null,
    'Accept-Local-Language': 'en',
  };

  Future<Response> get(String url, {Map<String, dynamic>? query}) async {
    return _dio.get(
      url,
      queryParameters: query,
      options: Options(headers: defaultHeaders),
    );
  }

  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    return _dio.post(
      url,
      data: data,
      options: Options(
        headers: headers ?? defaultHeaders,
        followRedirects: false,
        validateStatus: ((status) {
          return status! <= 500;
        }),
      ),
    );
  }

  Future<Response> put(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
  }) async {
    return _dio.put(
      url,
      data: data,
      options: Options(
        headers: headers ?? defaultHeaders,
        followRedirects: false,
        validateStatus: ((status) {
          return status! <= 500;
        }),
      ),
    );
  }

  Future<Response> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    return _dio.delete(
      url,
      data: data,
      queryParameters: query,
      options: Options(
        headers: headers ?? defaultHeaders,
        followRedirects: false,
        validateStatus: ((status) {
          return status! <= 500;
        }),
      ),
    );
  }

  void updateToken({required String token}) {
    defaultHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';
    debugPrint(
      'Update Token:${defaultHeaders[HttpHeaders.authorizationHeader]}',
    );
  }

  void updateLocalLanguage({required String language}) {
  defaultHeaders['Accept-Local-Language'] = language;
  debugPrint('Update Local Language: ${defaultHeaders['Accept-Local-Language']}');
}


  void updateLanguage({required String language}) {
    defaultHeaders[HttpHeaders.acceptLanguageHeader] = language;
    debugPrint(
      'Update language:${defaultHeaders[HttpHeaders.acceptLanguageHeader]}',
    );
  }
}

//final apiClientProvider = Provider((ref) => ApiClient());
