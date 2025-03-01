import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoAudioRecorder {
  AudioRecorder? _record; // Make nullable and private
  String? audioPath;
  bool _isRecording = false;

  // Initialize recorder when needed
  Future<void> _initializeRecorder() async {
    _record ??= AudioRecorder();
  }

  Future<void> startRecording() async {
    await _initializeRecorder();

    // Get the temporary directory for storing audio
    final directory = await getTemporaryDirectory();
    audioPath = '${directory.path}/audio_recording.m4a';

    // Check and request audio permissions
    if (await _record!.hasPermission()) {
      // Start audio recording with configuration
      await _record!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 2,
        ),
        path: audioPath!,
      );
      _isRecording = true;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording || _record == null) return null;

    try {
      if (await _record!.isRecording()) {
        await _record!.stop();
        _isRecording = false;
        
        // Close the recorder to release the file handle
        await _record!.dispose();
        _record = null;
        
        // Verify the file exists and is accessible
        final file = File(audioPath!);
        if (await file.exists()) {
          return audioPath;
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
    return null;
  }

  void dispose() {
    _record?.dispose();
    _record = null;
  }
}
