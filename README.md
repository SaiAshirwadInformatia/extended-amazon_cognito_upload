# amazon_cognito_upload_plus

`amazon_cognito_upload_plus` is a Dart library designed to simplify and streamline file uploads to **Amazon S3** using **pre-signed URLs** and **Amazon Cognito authentication**.

## Features

- ✅ **Easy File Uploads**: Upload files directly to **Amazon S3** using pre-signed URLs.
- ✅ **Secure with AWS Cognito**: Authenticate users via **Amazon Cognito**.
- ✅ **Customizable**: Supports **custom configurations** for flexibility.

## 🚀 Installation

Add the **amazon_cognito_upload_plus** package to your `pubspec.yaml`:

Super simple to use

```yaml
dependencies:
  amazon_cognito_upload_plus: ^0.0.3
```

```dart

import 'package:amazon_cognito_upload_plus/amazon_cognito_upload_plus.dart';
import 'dart:typed_data';

Future<void> uploadFile(Uint8List fileBytes) async {
  String? uploadedUrl = await AWSWebClient.uploadFile(
    s3UploadUrl: 'https://yourBucketName.s3.region.amazonaws.com/',
    s3SecretKey: 'your-secret-key',
    s3Region: 'your-region',
    s3AccessKey: 'your-access-key',
    s3BucketName: 'your-bucket-name',
    folderName: 'uploads',
    fileName: 'example.jpg',
    fileBytes: fileBytes,
  );

  if (uploadedUrl != null) {
    print("✅ File uploaded successfully: $uploadedUrl");
  } else {
    print("❌ Upload failed.");
  }
}

```

## Important

Remember that enabling CORS for public access temporary when you upload file to S3 bucket.
the security implications of allowing cross-origin requests. Make sure to only allow the origins
that you trust.

