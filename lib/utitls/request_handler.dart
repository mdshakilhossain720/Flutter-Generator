import 'dart:io';

import 'package:dio/dio.dart';


class ApiInterceptors {
  static void addInterceptors(Dio dio) {
    dio.options.connectTimeout = const Duration(seconds: 50);
    dio.options.receiveTimeout = const Duration(seconds: 50);
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers['Content-Type'] = 'application/json';

    _addLoggerInterceptor(dio);
    _addResponseHandlerInterceptor(dio);
    // _addSSLPinningInterceptor(dio);
  }

  static void _addLoggerInterceptor(Dio dio) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  static void _addResponseHandlerInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authBox = Hive.box(AppConstants.authBox);
          final token = authBox.get(AppConstants.authToken);
          if (token != null) {
            options.headers['Authorization'] = "Bearer $token";
          }
          // Add Accept-Local-Language dynamically from Hive
          final settingsBox = Hive.box(AppConstants.appSettingsBox);
          final language = settingsBox.get(
            AppConstants.appLocal,
            defaultValue: 'en',
          );
          options.headers['Accept-Local-Language'] = language;
          options.headers[HttpHeaders.acceptLanguageHeader] = language;
          options.headers['Accept-Language'] = language;
          options.headers['Accept-Local-Language'] = language;

          handler.next(options);
        },
        onResponse: (response, handler) {
          final message = response.data['message'];

          switch (response.statusCode) {
            case 401:
              Box authBox = Hive.box(AppConstants.authBox);
              authBox.delete(AppConstants.authToken);
              GlobalFunction.showCustomSnackbar(
                message: message,
                isSuccess: false,
              );

              _handleUnauthorized();
              break;
            case 302:
            case 400:
            case 403:
            case 404:
            case 409:
            case 422:
            case 500:
              GlobalFunction.showCustomSnackbar(
                message: message,
                isSuccess: false,
                //context: GlobalFunction.navigatorKey.currentState!.context,
              );
              break;
            default:
              break;
          }
          handler.next(response); // Forward the response
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          } else {
            handleError(error);
          }
          handler.reject(error); // Forward the error
        },
      ),
    );
  }

  static String handleError(DioException exception) {
    String errorMessage = 'Something went wrong. Please try again.';
    switch (exception.type) {
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        errorMessage = 'Network error. Please check your connection.';
        break;
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
        errorMessage = 'Server error. Please try again later.';
        break;
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        break;
      default:
        break;
    }
    GlobalFunction.showCustomSnackbar(message: errorMessage, isSuccess: false);
    return errorMessage;
  }

  static void _addSSLPinningInterceptor(Dio dio) {
    dio.interceptors.add(
      CertificatePinningInterceptor(
        allowedSHAFingerprints: [AppConstants.sslPinnigSHA256],
        // timeout: 5000,
        // callFollowingErrorInterceptor: true,
      ),
    );
  }

  static void _handleUnauthorized() async {
    // GlobalFunction.showCustomSnackbar(
    //   message: 'Unauthorized',
    //   isSuccess: false,
    // );

    // // Delete the auth token
    // Box authBox = Hive.box(AppConstants.authBox);
    // authBox.delete(AppConstants.authToken);

    await GlobalFunction.providerContainer
        .read(hiveServiceProvider)
        .removeAllData();

    // Access the BuildContext
    final context = GlobalFunction.rootNavigatorKey.currentContext;
    if (context != null) {
      // Navigate to the login screen using GoRouter
      context.go(Routes.login);
    }
  }
}
