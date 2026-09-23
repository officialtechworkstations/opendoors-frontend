import 'package:dio/dio.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/reel.dart';
import 'package:opendoors/utils/app_logger.dart';

class ReelsApiException implements Exception {
  const ReelsApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class ReelsApiService {
  ReelsApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Options get _authenticatedOptions {
    final token = (getData.read('accessToken') ?? getData.read('access_token'))
        ?.toString()
        .trim();
    final expiresAt = int.tryParse(
      getData.read('accessTokenExpiresAt')?.toString() ?? '',
    );
    final expired =
        expiresAt != null && DateTime.now().millisecondsSinceEpoch >= expiresAt;
    return Options(
      headers: token == null || token.isEmpty || expired
          ? null
          : <String, String>{'Authorization': 'Bearer $token'},
    );
  }

  void _requireAccessToken() {
    final headers = _authenticatedOptions.headers;
    if (headers == null || !headers.containsKey('Authorization')) {
      final hasToken =
          (getData.read('accessToken') ?? getData.read('access_token'))
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true;
      final expiresAt = int.tryParse(
        getData.read('accessTokenExpiresAt')?.toString() ?? '',
      );
      AppLogger.warning('ReelsApi', 'No usable API session', data: {
        'token_present': hasToken,
        'expiry_present': expiresAt != null,
        'expired': expiresAt != null &&
            DateTime.now().millisecondsSinceEpoch >= expiresAt,
      });
      throw const ReelsApiException(
        'Your session has expired. Please sign in again.',
        code: 'AUTH_TOKEN_INVALID',
        statusCode: 401,
      );
    }
  }

  Future<Reel> create({
    required String propertyId,
    required String videoPath,
    String? thumbnailPath,
    void Function(int sent, int total)? onProgress,
  }) async {
    _requireAccessToken();
    if (thumbnailPath == null || thumbnailPath.isEmpty) {
      throw const ReelsApiException('A reel thumbnail is required.');
    }
    final form = FormData.fromMap({
      'prop_id': propertyId,
      'video': await MultipartFile.fromFile(videoPath),
      'thumbnail': await MultipartFile.fromFile(thumbnailPath),
    });
    final response = await _request(
      () => _dio.post(
        '${Config.path}${Config.reelCreate}',
        data: form,
        options: _authenticatedOptions,
        onSendProgress: onProgress,
      ),
    );
    return Reel.fromJson(_requiredMap(response!, 'reel'));
  }

  Future<Reel> update({
    required String reelId,
    required String videoPath,
    required String thumbnailPath,
    void Function(int sent, int total)? onProgress,
  }) async {
    _requireAccessToken();
    final form = FormData.fromMap({
      'reel_id': reelId,
      'video': await MultipartFile.fromFile(videoPath),
      'thumbnail': await MultipartFile.fromFile(thumbnailPath),
    });
    final response = await _request(
      () => _dio.post(
        '${Config.path}${Config.reelUpdate}',
        data: form,
        options: _authenticatedOptions,
        onSendProgress: onProgress,
      ),
    );
    return Reel.fromJson(_requiredMap(response!, 'reel'));
  }

  Future<Reel?> read({String? reelId, String? propertyId}) async {
    _requireAccessToken();
    final response = await _request(
      () => _dio.get(
        '${Config.path}${Config.reelRead}',
        queryParameters: {
          if (reelId != null) 'reel_id': reelId,
          if (propertyId != null) 'prop_id': propertyId,
        },
        options: _authenticatedOptions,
      ),
      allowNotFound: true,
    );
    if (response == null || response['reel'] == null) return null;
    return Reel.fromJson(_requiredMap(response, 'reel'));
  }

  Future<ReelProperty?> propertyDetails(String propertyId) async {
    final response = await _request(
      () => _dio.post(
        '${Config.path}${Config.propertyDetails}',
        data: {
          'pro_id': propertyId,
          'uid': getData.read('UserLogin')?['id']?.toString() ?? '0',
        },
        options: _authenticatedOptions,
      ),
    );
    if (response == null) return null;
    final raw = response['propetydetails'] ?? response['property'];
    if (raw is! Map) return null;
    return ReelProperty.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<ReelsPage> list({int cursor = 0, int limit = 10}) async {
    _requireAccessToken();
    final response = await _request(
      () => _dio.get(
        '${Config.path}${Config.reelsList}',
        queryParameters: {'last_id': cursor, 'limit': limit},
        options: _authenticatedOptions,
      ),
    );
    return _parsePage(response!);
  }

  Future<ReelsPage> liked({int cursor = 0, int limit = 10}) =>
      _filteredFeed(Config.likedReels, cursor, limit);

  Future<ReelsPage> saved({int cursor = 0, int limit = 10}) =>
      _filteredFeed(Config.savedReels, cursor, limit);

  Future<ReelsPage> _filteredFeed(
      String endpoint, int cursor, int limit) async {
    _requireAccessToken();
    final response = await _request(() => _dio.get(
          '${Config.path}$endpoint',
          queryParameters: {'last_id': cursor, 'limit': limit},
          options: _authenticatedOptions,
        ));
    return _parsePage(response!);
  }

  ReelsPage _parsePage(Map<String, dynamic> response) {
    final pagination = _requiredMap(response, 'pagination');
    final rawReels = response['reels'] as List<dynamic>? ?? const [];
    return ReelsPage(
      reels: rawReels
          .whereType<Map<String, dynamic>>()
          .map(Reel.fromJson)
          .where((reel) => !reel.isPropertyUnpublished)
          .toList(),
      nextCursor:
          int.tryParse(pagination['next_cursor']?.toString() ?? '') ?? 0,
      hasMore: pagination['has_more'] == true ||
          pagination['has_more']?.toString() == 'true',
    );
  }

  Future<({bool active, int count})> toggleLike(String reelId) async {
    _requireAccessToken();
    final data = (await _request(() => _dio.post(
          '${Config.path}${Config.reelLike}',
          data: {'reel_id': reelId},
          options: _authenticatedOptions.copyWith(
              contentType: Headers.formUrlEncodedContentType),
        )))!;
    return (active: _asBool(data['liked']), count: _asInt(data['likes_count']));
  }

  Future<({bool active, int count})> toggleSave(String reelId) async {
    _requireAccessToken();
    final data = (await _request(() => _dio.post(
          '${Config.path}${Config.reelSave}',
          data: {'reel_id': reelId},
          options: _authenticatedOptions.copyWith(
              contentType: Headers.formUrlEncodedContentType),
        )))!;
    return (active: _asBool(data['saved']), count: _asInt(data['saves_count']));
  }

  Future<int> addView(String reelId) async {
    final data = (await _request(() => _dio.post(
          '${Config.path}${Config.reelViews}',
          data: {'reel_id': reelId},
          options: Options(contentType: Headers.formUrlEncodedContentType),
        )))!;
    return _asInt(data['views_count']);
  }

  Future<ReelCommentsPage> comments(String reelId,
      {int cursor = 0, int limit = 20}) async {
    final data = (await _request(() => _dio.get(
          '${Config.path}${Config.reelComments}',
          queryParameters: {
            'reel_id': reelId,
            'last_id': cursor,
            'limit': limit
          },
        )))!;
    final pagination = _requiredMap(data, 'pagination');
    return ReelCommentsPage(
      comments: (data['comments'] as List? ?? [])
          .whereType<Map>()
          .map((item) => ReelComment.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      nextCursor: _asInt(pagination['next_cursor']),
      hasMore: _asBool(pagination['has_more']),
    );
  }

  Future<ReelComment> addComment(String reelId, String comment) async {
    _requireAccessToken();
    final data = (await _request(() => _dio.post(
          '${Config.path}${Config.reelComments}',
          data: {'reel_id': reelId, 'comment': comment},
          options: _authenticatedOptions.copyWith(
              contentType: Headers.formUrlEncodedContentType),
        )))!;
    return ReelComment.fromJson(_requiredMap(data, 'comment'));
  }

  Future<ReelComment> editComment(String commentId, String comment) async {
    _requireAccessToken();
    final data = (await _request(() => _dio.post(
          '${Config.path}${Config.reelComments}',
          data: {'comment_id': commentId, 'comment': comment},
          options: _authenticatedOptions.copyWith(
              contentType: Headers.formUrlEncodedContentType),
        )))!;
    return ReelComment.fromJson(_requiredMap(data, 'comment'));
  }

  Future<void> deleteComment(String commentId) async {
    _requireAccessToken();
    await _request(() => _dio.delete('${Config.path}${Config.reelComments}',
        queryParameters: {'comment_id': commentId},
        options: _authenticatedOptions));
  }

  int _asInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
  bool _asBool(Object? value) =>
      value == true || value?.toString() == 'true' || value?.toString() == '1';

  Future<void> delete(String reelId) async {
    _requireAccessToken();
    await _request(
      () => _dio.post(
        '${Config.path}${Config.reelDelete}',
        data: {
          'reel_id': reelId,
        },
        options: _authenticatedOptions.copyWith(
          contentType: Headers.formUrlEncodedContentType,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _request(
    Future<Response<dynamic>> Function() request, {
    bool allowNotFound = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await request();
      AppLogger.info('ReelsApi', 'Request completed', data: {
        'method': response.requestOptions.method,
        'path': response.requestOptions.path,
        'status': response.statusCode,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['Result']?.toString() != 'true') {
        throw ReelsApiException(
          data['ResponseMsg']?.toString() ?? 'Unable to complete request.',
          code: data['error_code']?.toString(),
          statusCode: response.statusCode,
        );
      }
      return data;
    } on DioException catch (error) {
      AppLogger.error(
        'ReelsApi',
        'Request failed',
        error: error,
        stackTrace: error.stackTrace,
        data: {
          'method': error.requestOptions.method,
          'path': error.requestOptions.path,
          'status': error.response?.statusCode,
          'error_code': error.response?.data is Map
              ? (error.response?.data as Map)['error_code']
              : null,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
      if (allowNotFound && error.response?.statusCode == 404) return null;
      final body = error.response?.data;
      final data = body is Map ? Map<String, dynamic>.from(body) : null;
      final statusCode = error.response?.statusCode;
      final serverMessage = data?['ResponseMsg']?.toString().trim();
      throw ReelsApiException(
        serverMessage != null && serverMessage.isNotEmpty
            ? serverMessage
            : statusCode != null && statusCode >= 500
                ? 'Reels are temporarily unavailable. Please try again later.'
                : statusCode == 401 || statusCode == 403
                    ? 'Your session has expired. Please sign in again.'
                    : 'Unable to load reels. Check your connection and try again.',
        code: data?['error_code']?.toString(),
        statusCode: statusCode,
      );
    }
  }

  Map<String, dynamic> _requiredMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ReelsApiException('The server returned an invalid $key response.');
  }
}
