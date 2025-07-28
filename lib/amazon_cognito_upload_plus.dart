library amazon_cognito_upload_plus;

import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum StorageType { s3, r2 }

class AWSWebClient {
  const AWSWebClient();

  /// Upload file to AWS S3 or Cloudflare R2
  static Future<String?> uploadFile({
    required String uploadUrl, // Full endpoint URL (S3 or R2)
    required String secretKey, // AWS or R2 secret key
    required String region, // AWS region (for R2 use 'auto')
    required String accessKey, // AWS or R2 access key
    required String bucketName, // Bucket name
    required String folderName, // Folder name inside the bucket
    required String fileName, // File name
    required Uint8List fileBytes, // File bytes
    StorageType storageType = StorageType.s3, // 's3' or 'r2'
  }) async {
    final length = fileBytes.length;
    Map<String, String> headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Credentials": "true",
      "Access-Control-Allow-Headers":
          "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
      "Access-Control-Allow-Methods": "POST, OPTIONS"
    };

    final uri = Uri.parse(uploadUrl);
    final req = http.MultipartRequest("POST", uri);
    final multipartFile = http.MultipartFile(
        'file', http.ByteStream.fromBytes(fileBytes), length,
        filename: fileName);

    /// ✅ For Cloudflare R2, region must be 'auto'
    final effectiveRegion = (storageType == StorageType.r2) ? 'auto' : region;

    /// ✅ Create Policy & Signature
    final policy = Policy.fromS3PresignedPost('$folderName/$fileName',
        bucketName, accessKey, 15, length, effectiveRegion);

    final key = SigV4.calculateSigningKey(
        secretKey, policy.datetime, effectiveRegion, 's3');
    final signature = SigV4.calculateSignature(key, policy.encode());

    /// ✅ Add headers & fields
    req.headers.addAll(headers);
    req.files.add(multipartFile);
    req.fields['key'] = policy.key;

    /// ⚠️ ACL is optional for R2 (bucket policy usually handles public access)
    if (storageType == StorageType.s3) {
      req.fields['acl'] = 'public-read';
    }

    req.fields['X-Amz-Credential'] = policy.credential;
    req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
    req.fields['X-Amz-Date'] = policy.datetime;
    req.fields['Policy'] = policy.encode();
    req.fields['X-Amz-Signature'] = signature;

    try {
      final res = await req.send();
      final response = await http.Response.fromStream(res);

      if (response.statusCode == 204 || response.statusCode == 200) {
        /// ✅ Construct URL based on storage type
        final fileUrl = (storageType == StorageType.r2)
            ? '$uploadUrl/$folderName/$fileName'
            : 'https://$bucketName.s3.$region.amazonaws.com/$folderName/$fileName';

        debugPrint('✅ Upload successful: $fileUrl');
        return fileUrl;
      } else {
        debugPrint(
            '❌ Upload failed. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Error uploading file: $e');
      return null;
    }
  }
}

/// ✅ Updated Policy class (works for both S3 & R2)
class Policy {
  String expiration;
  String region;
  String bucket;
  String key;
  String credential;
  String datetime;
  int maxFileSize;

  Policy(this.key, this.bucket, this.datetime, this.expiration, this.credential,
      this.maxFileSize, this.region);

  factory Policy.fromS3PresignedPost(String key, String bucket,
      String accessKeyId, int expiryMinutes, int maxFileSize, String region) {
    final datetime = SigV4.generateDatetime();
    final expiration = (DateTime.now())
        .add(Duration(minutes: expiryMinutes))
        .toUtc()
        .toString()
        .split(' ')
        .join('T');
    final cred =
        '$accessKeyId/${SigV4.buildCredentialScope(datetime, region, 's3')}';
    return Policy(key, bucket, datetime, expiration, cred, maxFileSize, region);
  }

  String encode() {
    final bytes = utf8.encode(toString());
    return base64.encode(bytes);
  }

  @override
  String toString() {
    return '''
{ "expiration": "$expiration",
  "conditions": [
    {"bucket": "$bucket"},
    ["starts-with", "\$key", "$key"],
    {"acl": "public-read"},
    ["content-length-range", 1, $maxFileSize],
    {"x-amz-credential": "$credential"},
    {"x-amz-algorithm": "AWS4-HMAC-SHA256"},
    {"x-amz-date": "$datetime" }
  ]
}
''';
  }
}
