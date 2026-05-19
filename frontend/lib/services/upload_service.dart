import 'package:dio/dio.dart';
import 'api_config.dart';

class UploadService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
  ));

  /// Uploads a file dynamically supporting both memory bytes (Web) and filesystem paths (Mobile).
  Future<void> uploadFile({
    String? filePath,
    List<int>? bytes,
    required String fileName,
    required String endpoint, // /upload/pdf or /upload/csv
    required Function(double) onProgress,
  }) async {
    FormData formData;

    if (bytes != null) {
      print("[DEBUG] [UploadService] Web Ingestion: Uploading '$fileName' (${bytes.length} bytes) to $endpoint");
      formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: fileName),
      });
    } else if (filePath != null) {
      print("[DEBUG] [UploadService] Mobile Ingestion: Uploading '$fileName' from path '$filePath' to $endpoint");
      formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });
    } else {
      throw Exception("Invalid Ingestion Parameters: Either bytes or filePath must be populated.");
    }

    await _dio.post(
      endpoint,
      data: formData,
      onSendProgress: (int sent, int total) {
        if (total > 0) {
          onProgress(sent / total);
        }
      },
    );
    
    print("[DEBUG] [UploadService] Ingestion transfer complete for '$fileName'.");
  }

  /// Sends a URL scrap intelligence request.
  Future<void> analyzeUrl(String url) async {
    print("[DEBUG] [UploadService] Ingesting URL: $url");
    await _dio.post(
      "/analyze/url",
      data: {"url": url},
    );
    print("[DEBUG] [UploadService] URL Ingestion complete.");
  }

  /// Sends a manual logistics event directly to the live feed.
  Future<void> sendLiveFeed({
    required String source,
    required String content,
    double credibility = 0.5,
  }) async {
    print("[DEBUG] [UploadService] Sending Live Feed Event. Source: $source, Credibility: $credibility");
    await _dio.post(
      "/live-feed",
      data: {
        "source": source,
        "content": content,
        "credibility": credibility,
      },
    );
    print("[DEBUG] [UploadService] Live Feed Event broadcast completed.");
  }
}
