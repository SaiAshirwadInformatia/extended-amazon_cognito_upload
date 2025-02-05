import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:amazon_cognito_upload_plus/amazon_cognito_upload_plus.dart';
import 'package:flutter/services.dart';

void main() {
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (dynamic error, dynamic stack) {
    developer.log("Something went wrong!", error: error, stackTrace: stack);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? imageBytes;
  String? uploadedFileUrl;

  // Example function to simulate file as byte (replace with actual file byte)
  Future<void> loadExampleImage() async {
    // Simulating an image byte (replace with actual file byte conversion)
    // Example: Convert an image from assets or local storage into bytes
    final imageBytes = await loadImageData();
    setState(() {
      this.imageBytes = imageBytes;
    });
  }

  // Load an image from assets (replace this with real file loading)
  Future<Uint8List> loadImageData() async {
    // Example: Load an image from assets
    // Replace with real image byte data in production (i.e., from file, network, etc.)
    final byteData = await rootBundle.load('assets/example_image.png');
    return byteData.buffer.asUint8List();
  }

  // Upload file to S3
  Future<void> uploadFile() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please load an image first.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Uploading... Please wait")),
    );

    String? fileUrl = await AWSWebClient.uploadFile(
      s3UploadUrl: 'S3_UPLOAD_URL', // Your bucket URL
      s3SecretKey:
          'S3_SECRET_KEY', // Your secret key (should be stored securely!)
      s3Region: 'S3_REGION', // Your region
      s3AccessKey: 'S3_ACCESS_KEY', // Your access key
      s3BucketName: 'S3_BUCKET', // Your bucket name
      folderName: 'profile', // Auto-generate folder in your bucket
      fileName: 'imagedata.png', // Your file name
      fileBytes: imageBytes!, // Convert file to bytes
    );

    if (fileUrl != null) {
      setState(() {
        uploadedFileUrl = fileUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Upload successful! File URL: $fileUrl")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed. Please try again.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadExampleImage(); // Load the example image on app start
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Amazon S3 Bucket Image Upload'),
          elevation: 4,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Example image loaded. Click to upload it.'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadFile,
                child: Text('Upload Example Image'),
              ),
              SizedBox(height: 20),
              if (uploadedFileUrl != null)
                Column(
                  children: [
                    Text('✅ File Uploaded Successfully!'),
                    SelectableText(uploadedFileUrl!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
