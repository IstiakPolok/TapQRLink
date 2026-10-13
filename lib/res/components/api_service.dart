import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as client;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../app_url/app_url.dart';

class ApiService extends GetxService {
  Future<Map<String, dynamic>> updateSubscriptionDate(
    String token,
    String? date,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrl.expiryUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"expired_date": date ?? ""}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getGuides() async {
    try {
      final response = await http.get(
        Uri.parse(AppUrl.guideUrl),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to fetch guides: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> registerFcmToken({
    required String accessToken,
    required String fcmToken,
  }) async {
    try {
      final url = AppUrl.registerFcmTokenUrl;
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'token': fcmToken});
      debugPrint('Request: POST $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      if (response.statusCode == 404) {
        return {
          'statusCode': 404,
          'data': {'detail': 'FCM registration endpoint not found'},
        };
      }
      return {
        'statusCode': response.statusCode,
        'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return {
        'statusCode': 500,
        'data': {'detail': 'Network error: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrl.refreshUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      debugPrint(
        'url _____________________ ${AppUrl.refreshUrl} _____________',
      );
      debugPrint(
        "refresh token _____________________ $refreshToken _________________",
      );
      if (response.statusCode == 200) {
        debugPrint("status______ ${response.statusCode}");
        return {'statusCode': 200, 'data': jsonDecode(response.body)};
      } else {
        debugPrint("status______ ${response.statusCode}");
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  Future<Map<String, dynamic>> updateHistory(
    String link,
    DateTime scannedAt,
    String token,
  ) async {
    try {
      final Map<String, dynamic> payload = {
        'link': link,
        'scanned_at': scannedAt.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(AppUrl.scanFreeUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      debugPrint('url ${AppUrl.scanFreeUrl}');
      debugPrint('token $token');
      debugPrint('payload $payload');
      debugPrint('updateHistory Response status: ${response.statusCode}');
      debugPrint('updateHistory Response body: ${response.body}');

      if (response.statusCode == 201) {
        return {
          'statusCode': response.statusCode,
          'data': jsonDecode(response.body),
        };
      } else {
        throw Exception(
          'Failed to update history. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating history: $e');
    }
  }

  Future<http.Response> signUpWithOther(
    String email,
    String fcmToken, {
    String? firstName,
    String? lastName,
  }) async {
    final url = Uri.parse(AppUrl.signUpWithOtherUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final Map<String, dynamic> body = {
      'email': email,
      'fcm_token': fcmToken,
    };
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['first_name'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['last_name'] = lastName.trim();
    }
    try {
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode(body)}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return response;
    } catch (e) {
      debugPrint('API error: $e');
      rethrow;
    }
  }

  Future<http.Response> fcmRegister(String fcmToken, String token) async {
    final url = Uri.parse(AppUrl.profileUrl);
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = {'fcm_token': fcmToken};
    try {
      final response = await client.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode(body)}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return response;
    } catch (e) {
      debugPrint('API error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> scanImage(File image, String token) async {
    final uri = Uri.parse(AppUrl.scanUrl);
    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      debugPrint('token $token');
      debugPrint('image ${image.path}');
      debugPrint('request $request');
      debugPrint('request files ${request.files}');
      debugPrint('request headers ${request.headers}');
      final response = await request.send();

      debugPrint('response $response');
      debugPrint('→ HTTP Status: ${response.statusCode}');
      debugPrint('→ Headers: ${response.headers}');
      final responseBody = await response.stream.bytesToString();
      debugPrint('response body $responseBody');
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(responseBody),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Image scan failed: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> scanImage1(File image) async {
    final uri = Uri.parse(AppUrl.scan1Url);
    try {
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('url ${AppUrl.scan1Url}');
      debugPrint('image ${image.path}');
      return {
        'statusCode': response.statusCode == 200 || response.statusCode == 201
            ? response.statusCode
            : 500,
        'data': response.statusCode == 200 || response.statusCode == 201
            ? jsonDecode(responseBody)
            : {},
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Image scan failed: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getHistory(String token, {String? url}) async {
    try {
      final response = await http.get(
        Uri.parse(url ?? AppUrl.historyUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to fetch history: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getHistoryById(int id, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrl.historyUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to fetch history details: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> deleteHistory(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppUrl.historyUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to delete history: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getNotifications(
    String token, {
    String? url,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url ?? AppUrl.notificationsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to fetch notifications: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> getNotificationById(int id, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrl.notificationsUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to fetch notification details: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppUrl.notificationsUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Failed to delete notification: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(AppUrl.loginUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email, 'password': password})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> signup(
    String firstName,
    String lastName,
    String email,
    String mobile,
  ) async {
    final url = Uri.parse(AppUrl.registerUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          if (mobile.isNotEmpty) 'mobile': mobile,
        }),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email})}');
      debugPrint(
        'first_name ______________ $firstName ___________\n last_name _______________ $lastName __________________\n email:_________________ $email _______________________\n mobile:____________________________ $mobile _________________',
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200 || response.statusCode == 201
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    final url = Uri.parse(AppUrl.verifyOtpUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'code': otpCode}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email, 'code': otpCode})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> verifyPasswordOtp(
    String email,
    String otpCode,
  ) async {
    final url = Uri.parse(AppUrl.verifyPasswordOtpUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'code': otpCode}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email, 'code': otpCode})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    final url = Uri.parse(AppUrl.resandUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> resendForgetOtp(String email) async {
    final url = Uri.parse(AppUrl.changePasswordUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> setPassword(
    String password,
    String confirmPassword,
    String token,
  ) async {
    final url = Uri.parse(AppUrl.setPasswordUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'new_password': password,
          'confirm_password': confirmPassword,
        }),
      );
      debugPrint('Request: POST $url');
      debugPrint('Token _____________ $token');
      debugPrint(
        'Body: ${jsonEncode({'new_password': password, 'confirm_password': confirmPassword})}',
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200 || response.statusCode == 201
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String email,
    String password,
    String confirmPassword,
  ) async {
    final url = Uri.parse(AppUrl.changePasswordUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'new_password': password,
          'confirm_password': confirmPassword,
        }),
      );
      debugPrint('Request: POST $url');
      debugPrint(
        'Body: ${jsonEncode({'email': email, 'new_password': password, 'confirm_password': confirmPassword})}',
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200 || response.statusCode == 201
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> forget(String email) async {
    final url = Uri.parse(AppUrl.forgetUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      debugPrint('Request: POST $url');
      debugPrint('Body: ${jsonEncode({'email': email})}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': response.statusCode == 200
            ? jsonDecode(response.body)
            : jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(AppUrl.profileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Request: GET ${AppUrl.getProfileByIdUrl}');
      debugPrint(
        'Headers: {Authorization: Bearer $token, Content-Type: application/json}',
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body.isNotEmpty ? response.body : '{}'),
      };
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'detail': 'Error: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    File? picture,
    required String picture1,
    required String token,
  }) async {
    final url = Uri.parse(AppUrl.profileUrl);
    debugPrint('url __________________________ $url ___________________');

    if (picture == null && picture1.isEmpty) {
      return {
        'statusCode': 400,
        'data': {'error': 'Profile photo is required'},
      };
    }

    try {
      final multipartRequest = http.MultipartRequest('PUT', url);
      multipartRequest.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      multipartRequest.fields['first_name'] = firstName;
      multipartRequest.fields['last_name'] = lastName;
      multipartRequest.fields['email'] = email;
      multipartRequest.fields['mobile_number'] = mobile;

      if (picture != null && picture.path.isNotEmpty) {
        final mimeType =
            lookupMimeType(picture.path) ?? 'application/octet-stream';
        final photoFile = await http.MultipartFile.fromPath(
          'profile_picture',
          picture.path,
          contentType: MediaType.parse(mimeType),
        );
        multipartRequest.files.add(photoFile);
        debugPrint('Added profile photo file: ${photoFile.filename}');
      } else {
        multipartRequest.fields['profile_photo'] = picture1;
        debugPrint('Added profile photo string: $picture1');
      }

      debugPrint('Request fields: ${multipartRequest.fields}');
      debugPrint(
        'Request files: ${multipartRequest.files.map((f) => f.filename).toList()}',
      );

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
      return {'statusCode': response.statusCode, 'data': responseData};
    } catch (e) {
      debugPrint('API error: $e');
      return {
        'statusCode': 500,
        'data': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> updateProfileNames({
    required String firstName,
    required String lastName,
    required String token,
  }) async {
    final url = Uri.parse(AppUrl.profileUrl);
    try {
      final multipartRequest = http.MultipartRequest('PUT', url);
      multipartRequest.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      multipartRequest.fields['first_name'] = firstName;
      multipartRequest.fields['last_name'] = lastName;
      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('updateProfileNames status: ${response.statusCode}');
      debugPrint('updateProfileNames body: ${response.body}');
      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
      return {'statusCode': response.statusCode, 'data': responseData};
    } catch (e) {
      debugPrint('updateProfileNames error: $e');
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }
}
