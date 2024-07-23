import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quiver/async.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool recording = false;
  int _time = 0;

  requestPermissions() async {
    if (await Permission.storage.request().isDenied) {
      await Permission.storage.request();
    }
    if (await Permission.photos.request().isDenied) {
      await Permission.photos.request();
    }
    if (await Permission.microphone.request().isDenied) {
      await Permission.microphone.request();
    }
    // await PermissionHandler().requestPermissions([
    //   PermissionGroup.storage,
    //   PermissionGroup.photos,
    //   PermissionGroup.microphone,
    // ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    startTimer();
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
                      child: Text("Record Screen & audio"),
                      onPressed: () => startScreenRecord(true),
                    ),
                  )
                : Center(
                    child: ElevatedButton(
                      child: Text("Stop Live Stream"),
                      onPressed: () => stopLiveStream(),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  startScreenRecord(bool audio) async {
    bool start = false;

      start = await FlutterScreenRecording.startRecordScreenAndAudio("Title");
    

    if (start) {
      setState(() => recording = !recording);
      Timer.periodic(Duration(seconds: 6), (timer) async {
        if (recording) {
          stopScreenRecord();
          start =
              await FlutterScreenRecording.startRecordScreenAndAudio("Title");
        } else {
          timer.cancel();
        }
      });
    }

    return start;
  }

  stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    print("Opening video");
    print(path);
    // OpenFile.open(path);

    await streamChunk(path);
  }

  stopLiveStream() async {
    setState(() {
      recording = !recording;
    });
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
