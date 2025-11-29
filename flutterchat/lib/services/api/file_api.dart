import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/logger_service.dart';

class UploadInfo {
  final String uploadUrl;
  final String objectKey;
  UploadInfo({required this.uploadUrl, required this.objectKey});
  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    return UploadInfo(
      uploadUrl: json['uploadUrl'],
      objectKey: json['objectKey'],
    );
  }
}

mixin FileApi on ApiBase {
  Future<UploadInfo> getUploadUrl(String fileName) async {
    try {
      final response = await dio.get(
        '/gateway/files/generate-upload-url',
        queryParameters: {'fileName': fileName},
      );
      return UploadInfo.fromJson(response.data);
    } on DioException catch (e) {
      throw handleError(e, 'getUploadUrl');
    }
  }

  Future<String> uploadFileAndGetObjectKey(XFile file) async {
    final uploadInfo = await getUploadUrl(file.name);
    await _uploadToMinioRaw(uploadInfo.uploadUrl, file);
    return uploadInfo.objectKey;
  }

  Future<void> _uploadToMinioRaw(String uploadUrl, XFile file) async {
    try {
      final fileBytes = await file.readAsBytes();
      final cleanDio = Dio(); // 纯净实例，不带 Token
      await cleanDio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileBytes.length,
            Headers.contentTypeHeader: 'image/jpeg',
          },
        ),
      );
      logger.i('MinIO Upload Success');
    } on DioException catch (e) {
      logger.e('MinIO Upload Failed', error: e);
      throw '文件上传失败';
    }
  }
}
