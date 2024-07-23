import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:quiver/async.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool recording = false;
  Timer? _recordingTimer;
  int _time = 0;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  Future<void> requestPermissions() async {
    final status = await [
      Permission.storage,
      Permission.photos,
      Permission.microphone,
    ].request();

    if (status[Permission.storage] != PermissionStatus.granted ||
        status[Permission.photos] != PermissionStatus.granted ||
        status[Permission.microphone] != PermissionStatus.granted) {
      // Handle permission not granted scenario
      print("Some permissions are not granted.");
    }
  }

  void startTimer() {
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: 1000),
      new Duration(seconds: 1),
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() => _time++);
    });

    sub.onDone(() {
      print("Done");
      sub.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Screen Recording'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Time: $_time\n'),
            !recording
                ? Center(
                    child: ElevatedButton(
                      child: Text("Record Screen & Audio"),
                      onPressed: () => startScreenRecord(true),
                    ),
                  )
                : Center(
                    child: ElevatedButton(
                      child: Text("Stop Live Stream"),
                      onPressed: stopLiveStream,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> startScreenRecord(bool audio) async {
    bool start = false;

    // Start recording
    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio("Title");
    } else {
      start = await FlutterScreenRecording.startRecordScreen("Title");
    }

    if (start) {
      setState(() => recording = true);

      // Timer to stop and restart recording every 6 seconds
      _recordingTimer = Timer.periodic(Duration(seconds: 6), (timer) async {
        if (recording) {
          await stopScreenRecord();
          bool restarted = audio
              ? await FlutterScreenRecording.startRecordScreenAndAudio("Title")
              : await FlutterScreenRecording.startRecordScreen("Title");
          if (!restarted) {
            // If restarting failed, cancel the timer and stop recording
            timer.cancel();
            setState(() => recording = false);
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    print("Video saved at: $path");

    if (path.isNotEmpty) {
      await streamChunk(path);
    }
  }

  Future<void> stopLiveStream() async {
    setState(() {
      recording = false;
    });
    _recordingTimer?.cancel();
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
}
