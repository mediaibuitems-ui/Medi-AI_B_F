import 'dart:async';
import 'package:dio/dio.dart';
// import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
// import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:logger/logger.dart';
// import 'package:path_provider/path_provider.dart';
import '../../config/app_config.dart';
import '../data/models/api_response.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final _logger = Logger();
  final _storageService = Get.find<StorageService>();
  bool _isRefreshing = false;

  Future<ApiService> init() async {
    // Setup Dio
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) =>
          status! < 400, // Throw for 4xx and 5xx so interceptors can catch 401
    ));

    // Log current Dio configuration for easier debugging
    _logger.i(
        'Dio configured: baseUrl=${AppConfig.baseUrl}, connectTimeout=${AppConfig.connectionTimeout}, receiveTimeout=${AppConfig.receiveTimeout}');

    // Setup cache (disabled for web compatibility)
    // final cacheDir = await getTemporaryDirectory();
    // final cacheStore = HiveCacheStore(cacheDir.path);
    // final cacheOptions = CacheOptions(
    //   store: cacheStore,
    //   maxStale: AppConfig.cacheMaxAge,
    //   priority: CachePriority.normal,
    // );

    // Add interceptors
    _dio.interceptors.addAll([
      // DioCacheInterceptor(options: cacheOptions),
      _AuthInterceptor(_storageService, _dio),
      _LoggingInterceptor(_logger),
    ]);

    return this;
  }

  // GET Request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // POST Request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    bool requiresAuth = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final options = Options();

      if (requiresAuth) {
        final token = await _storageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers = {
            'Authorization': 'Bearer $token',
          };
        }
      }

      final response = await _dio.post(endpoint, data: data, options: options);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // PUT Request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // PATCH Request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    bool requiresAuth = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final options = Options();

      if (requiresAuth) {
        final token = await _storageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers = {
            'Authorization': 'Bearer $token',
          };
        }
      }

      final response =
          await _dio.delete(endpoint, data: data, options: options);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // Handle successful response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return ApiResponse.fromJson(response.data, fromJson);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Request failed with status: ${response.statusCode}',
      );
    }
  }

  // Handle errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    // Use dynamic to catch both DioException and others if needed
    String message = 'An error occurred';
    DioException? dioError;

    if (error is DioException) {
      dioError = error;
    }

    if (dioError != null && dioError.response != null) {
      final data = dioError.response!.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          message = data['message'];
        } else if (data.containsKey('errors')) {
          // Handle ASP.NET Core validation errors
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            final errorList = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorList.addAll(value.map((e) => e.toString()));
              } else {
                errorList.add(value.toString());
              }
            });
            message = errorList.join('\n');
          } else {
            message = 'Validation error occurred';
          }
        } else if (data.containsKey('title')) {
          message = data['title'];
        }
      } else {
        message = 'Server error: ${dioError.response!.statusCode}';
      }
    } else if (dioError != null) {
      // Map Dio exception types to friendly messages
      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        case DioExceptionType.badCertificate:
          message = 'SSL certificate error';
          break;
        case DioExceptionType.unknown:
        default:
          message = error.message ?? 'Unexpected error';
      }
    }

    // Include request URI and error type for debugging (guard if non-Dio error)
    Uri? uri;
    String? errType;
    try {
      if (error is DioException) {
        uri = error.requestOptions.uri;
        errType = error.type.toString();
      }
    } catch (_) {
      // ignore
    }

    _logger.e(
        'API Error: $message | uri=${uri ?? 'unknown'} | type=${errType ?? 'unknown'}',
        error: error);

    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
    );
  }

  // Refresh token
  Future<bool> refreshToken() async {
    if (_isRefreshing) return false;

    try {
      _isRefreshing = true;
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null) {
        return false;
      }

      final accessToken = await _storageService.getAccessToken();
      final response = await _dio.post(
        '/Auth/refresh-token',
        data: {'accessToken': accessToken, 'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storageService.saveAccessToken(data['accessToken']);
        await _storageService.saveRefreshToken(data['refreshToken']);
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Dio get dio => _dio;
}

// Auth Interceptor (Auto token refresh on 401)
class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _refreshQueue = [];

  _AuthInterceptor(this._storageService, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add access token to headers
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 - Unauthorized with silent refresh
    if (err.response?.statusCode == 401) {
      final req = err.requestOptions;

      // Don't attempt refresh if the failing request was the refresh call itself
      if (req.path.contains('refresh-token') ||
          req.uri.path.contains('refresh-token')) {
        await _storageService.clearAuthData();
        Get.offAllNamed('/login');
        return;
      }

      // If already refreshing, queue this request and wait
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _refreshQueue.add({'options': req, 'completer': completer});
        try {
          final response = await completer.future;
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      }

      _isRefreshing = true;
      try {
        final didRefresh = await Get.find<ApiService>().refreshToken();

        if (didRefresh) {
          // Get latest token
          final newToken = await _storageService.getAccessToken();

          // Retry original request
          req.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(req);

          // Drain queue: retry queued requests
          for (var item in _refreshQueue) {
            final RequestOptions queuedOptions = item['options'];
            final Completer<Response> c = item['completer'];
            try {
              queuedOptions.headers['Authorization'] = 'Bearer $newToken';
              final queuedResp = await _dio.fetch(queuedOptions);
              c.complete(queuedResp);
            } catch (e) {
              c.completeError(e);
            }
          }
          _refreshQueue.clear();

          handler.resolve(response);
          return;
        } else {
          // Refresh failed -> clear auth and redirect to login
          _refreshQueue.clear();
          await _storageService.clearAuthData();
          Get.offAllNamed('/login');
          handler.next(err);
          return;
        }
      } catch (e) {
        _refreshQueue.clear();
        await _storageService.clearAuthData();
        Get.offAllNamed('/login');
        handler.next(err);
        return;
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('REQUEST[${options.method}] => ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri} | type=${err.type} | message=${err.message}',
      error: err,
    );
    handler.next(err);
  }
}
