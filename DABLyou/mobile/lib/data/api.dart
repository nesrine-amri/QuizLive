import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/device_info.dart';

class Api {
  final Dio _dio;
  Api(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required String birthDate,
    String? city,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'gender': gender,
      'birthDate': birthDate,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> media({required String type}) async {
    final res = await _dio.get('/media', queryParameters: {'type': type});
    return (res.data as List).cast<dynamic>();
  }

  Future<void> selectMedia(String mediaId) async {
    await _dio.post('/media/select', data: {'mediaId': mediaId});
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required String selectedAnswer,
    required int responseTimeMs,
  }) async {
    final res = await _dio.post('/gameplay/answer', data: {
      'questionId':    questionId,
      'selectedAnswer': selectedAnswer,
      'responseTimeMs': responseTimeMs,
      'deviceOs':      DeviceInfo.os,  // "android" | "ios" | "web" — auto-detected
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> rewards() async {
    final res = await _dio.get('/rewards');
    return (res.data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> redeem(String rewardId) async {
    final res = await _dio.post('/rewards/redeem', data: {'rewardId': rewardId});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> myCoupons() async {
    final res = await _dio.get('/coupons/mine');
    return (res.data as List).cast<dynamic>();
  }

  Future<List<dynamic>> pointsHistory() async {
    final res = await _dio.get('/points/history');
    return (res.data as List).cast<dynamic>();
  }
}

