import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String? token})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          ),
        );
}

