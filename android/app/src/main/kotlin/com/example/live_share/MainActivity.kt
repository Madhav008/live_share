package com.example.live_share

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.Surface
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.live_share/screen_recording"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var mediaCodec: MediaCodec? = null
    private var recordingSurface: Surface? = null
    private var outputPath: String = ""
    private val handler = Handler(Looper.getMainLooper())
    private val REQUEST_CODE_MEDIA_PROJECTION = 1002
    private var resultCode: Int = 0
    private var data: Intent? = null

    private val recordingRunnable = object : Runnable {
        override fun run() {
            if (mediaProjection != null) {
                stopRecordingAndSave()
                startRecording()
                handler.postDelayed(this, 6000) // 6 seconds delay
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Start MediaProjection permission request
        if (resultCode == 0 && data == null) {
            val intent = mediaProjectionManager.createScreenCaptureIntent()
            startActivityForResult(intent, REQUEST_CODE_MEDIA_PROJECTION)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    if (resultCode != 0 && data != null) {
                        startRecording()
                        result.success("Recording started")
                    } else {
                        result.error("MEDIA_PROJECTION_NOT_READY", "MediaProjection permissions not granted", null)
                    }
                }
                "stopRecording" -> {
                    stopRecording()
                    result.success("Recording stopped")
                }
                "getVideoChunkPath" -> {
                    result.success(outputPath)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording() {
        // Configure MediaCodec
        mediaCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        val mediaFormat = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, 1280, 720)
        mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE, 1000000)
        mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE, 30)
        mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
        mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        mediaCodec?.configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)

        recordingSurface = mediaCodec?.createInputSurface()
        mediaCodec?.start()

        // Obtain a MediaProjection instance
        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data!!)

        mediaProjection?.createVirtualDisplay(
            "ScreenRecord",
            1280, 720, 1,
            Display.DEFAULT_DISPLAY,
            recordingSurface, null, null
        )

        // Save the video to Downloads directory
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        outputPath = "${downloadsDir.absolutePath}/output_${System.currentTimeMillis()}.mp4"

        // Start periodic recording
        handler.postDelayed(recordingRunnable, 6000) // 6 seconds delay
    }

    private fun stopRecording() {
        handler.removeCallbacks(recordingRunnable)
        mediaProjection?.stop()
        mediaCodec?.stop()
        mediaCodec?.release()
        mediaProjection?.stop()
    }

    private fun stopRecordingAndSave() {
        mediaProjection?.stop()
        mediaCodec?.stop()
        mediaCodec?.release()
        mediaProjection?.stop()

        // Save the file path
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        outputPath = "${downloadsDir.absolutePath}/output_${System.currentTimeMillis()}.mp4"
        Log.d("ScreenRecord", "Recording saved to $outputPath")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK) {
                this.resultCode = resultCode
                this.data = data
                Log.d("ScreenRecord", "MediaProjection permission granted")
            } else {
                Log.e("ScreenRecord", "MediaProjection permission denied")
            }
        }
    }
}
