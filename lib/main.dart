import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp(this.cameras);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Mobile OBS')),
        body: StreamScreen(cameras),
      ),
    );
  }
}

class StreamScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  StreamScreen(this.cameras);

  @override
  _StreamScreenState createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    await _cameraController?.initialize();
    setState(() {});
  }

  Future<void> startRecording() async {
    setState(() {
      _isRecording = true;
    });

    Timer(const Duration(seconds: 6), () {
      if (_isRecording) {
        recordChunk(0).then((_) {
          startRecording();
        });
      }
    });
  }

  Future<void> stopRecording() async {
    setState(() {
      _isRecording = false;
    });
    await _cameraController?.stopVideoRecording();
  }

  Future<void> recordChunk(int chunkIndex) async {
    try {
      // Get directory for temporary files
      Directory tempDir = await getTemporaryDirectory();
      String outputPath = '${tempDir.path}/output_$chunkIndex.mp4';

      // Start recording a video chunk
      await _cameraController?.startVideoRecording();

      // Wait for 6 seconds
      await Future.delayed(Duration(seconds: 6));

      // Stop recording
      XFile videoFile = await _cameraController!.stopVideoRecording();
      await videoFile.saveTo(outputPath);

      // Stream the chunk to RTMP server
      await streamChunk(outputPath);

      // Clean up the chunk file
      File(outputPath).delete();
    } catch (e) {
      print("Error recording chunk: $e");
    }
  }

  Future<void> streamChunk(String filePath) async {
    print("Sending to Go server");

    var uri = Uri.parse('http://192.168.1.68:8082/upload');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('video', filePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Uploaded successfully");
    } else {
      print("Upload failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: CameraPreview(_cameraController!),
        ),
        ElevatedButton(
          onPressed: _isRecording ? stopRecording : startRecording,
          child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Recording in progress...'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
