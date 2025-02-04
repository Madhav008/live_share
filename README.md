# Live Share

A new Flutter project to stream screen recordings to a Go server, which then uploads the videos to YouTube Live
![Backend Project](https://github.com/Madhav008/Live-Server)
## Getting Started

This project demonstrates how to create a Flutter app that records the screen, sends video chunks to a Go server, and streams live to YouTube.

### Prerequisites

- Flutter SDK
- Dart SDK
- Go programming language
- FFmpeg
- YouTube Live Stream key

### Steps to Set Up and Run the Project

## 1. Setting Up the Go Server

### Step 1: Install Go

Download and install Go from the [official website](https://golang.org/dl/).

### Step 2: Install FFmpeg

FFmpeg is required to handle video processing. Download and install FFmpeg from the [official website](https://ffmpeg.org/download.html).

### Step 3: Configure YouTube Live Stream

Obtain your YouTube Live Stream key from the YouTube dashboard.
![image](https://github.com/user-attachments/assets/b3a1b600-29e5-4384-96d3-1397b57acca9)


### Step 4: Set Up the Backend

Navigate to the `backend` folder in the project directory and follow the instructions provided in the `README.md` file to set up and run the Go server.
Open the main.go and replace the RTMP url to stream on your own youtube/facebook channel 
![image](https://github.com/user-attachments/assets/a7704db8-414b-4e82-9e88-3315b1897e81)

## 2. Setting Up the Flutter App

### Step 1: Install Flutter

Download and install Flutter from the [official website](https://flutter.dev/docs/get-started/install).

### Step 2: Request Permissions

Ensure that your app requests the necessary permissions for storage, microphone, and photos.

### Step 3: Start Screen Recording

The app uses the `flutter_screen_recording` package to record the screen and audio. 

### Step 4: Send Video Chunks to the Server
Before sending to the server change the server url from the App then run the App
![image](https://github.com/user-attachments/assets/2bea09e8-8b0f-42f8-83e0-77d6f77bfce8)

The app records 6-second video chunks and sends them to the Go server at regular intervals. The server processes these chunks and streams them to YouTube.

### Step 5: Stop Live Stream

Provide functionality in the app to stop the live stream by stopping the screen recording and uploading process.

## 3. Running the Flutter App

### Step 1: Install Dependencies

Navigate to the project directory and run:

```sh
flutter pub get
```

### Step 2: Run the App

Connect your device and run:

```sh
flutter run
```

## DEMO
![Live Stream URL](https://www.youtube.com/watch?v=o_Dld1ePbfc)
![Video Demo Link](https://youtu.be/-NQQB6x_J_s)

