import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';
import 'package:pitch_perfect/main.dart';
import 'package:pitch_perfect/video_audio_recorder.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Timer _timer;
  final VideoAudioRecorder _audioRecorder = VideoAudioRecorder();
  int timerValue = 60;
  int quarterTurns = 1;
  bool stopButtonPressed = false;
  bool isRecording = false;

  // Animation controller for timer pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    initializeCamera();

    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() {
        timerValue--;
      });
      // Pulse animation on each second
      _pulseController.forward().then((_) => _pulseController.reset());

      if (timerValue == 0) {
        _timer.cancel();
        onStopButtonPressed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
      enableAudio: true,
    );

    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.lockCaptureOrientation();
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors
            break;
          default:
            // Handle other errors
            break;
        }
      }
    }
  }

  Future<void> startRecordingVideo() async {
    if (_controller.value.isRecordingVideo) {
      return;
    }

    try {
      await _controller.startVideoRecording();
      await _audioRecorder.startRecording();
    } catch (_) {
      return;
    }
  }

  void onVideoRecordButtonPressed() {
    if (!isRecording) {
      startRecordingVideo().then((_) {
        if (mounted) {
          setState(() {
            isRecording = true;
          });
        }
      });
      _startTimer();
    } else {
      // Stop recording if already recording
      setState(() {
        isRecording = false;
        stopButtonPressed = true;
      });
      _timer.cancel();
      stopVideoRecording().then((XFile? file) {
        if (mounted) {
          setState(() {});
        }
        if (file != null) {
          videoFile = file;
        }
      });
    }
  }

  void onStopButtonPressed() {
    setState(() {
      stopButtonPressed = true;
    });

    stopVideoRecording().then((XFile? file) {
      if (mounted) {
        setState(() {});
      }
      if (file != null) {
        videoFile = file;
      }
    });
  }

  Future<XFile?> stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return null;
    }

    try {
      final videoFile = await _controller.stopVideoRecording();
      await _audioRecorder.stopRecording();
      return videoFile;
    } catch (e) {
      return null;
    }
  }

  Future<void> changeCameraLens() async {
    // Determine the new lens direction.
    final isFront =
        _controller.description.lensDirection == CameraLensDirection.front;
    final newLens =
        isFront ? CameraLensDirection.back : CameraLensDirection.front;

    // Get the corresponding camera.
    final newCamera =
        cameras.firstWhere((camera) => camera.lensDirection == newLens);

    // Dispose the old controller.
    await _controller.dispose();

    // Create a new controller with the selected camera.
    _controller =
        CameraController(newCamera, ResolutionPreset.max, enableAudio: true);

    try {
      await _controller.initialize();
      // Optionally, lock orientation if needed:
      await _controller.lockCaptureOrientation();
    } catch (e) {
      // Handle errors here.
    }

    setState(() {});
  }

  Widget buildCameraPreview() {
    if (!_controller.value.isInitialized) {
      return LoadingAnimationWidget.inkDrop(
        color: largeTextColor,
        size: 100,
      );
    }

    Widget preview = CameraPreview(_controller);

    // If using the front camera, apply a rotation or flip.
    if (_controller.description.lensDirection == CameraLensDirection.front) {
      // For example, rotate 180 degrees if needed:
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.1416), // or adjust the angle as required
        child: preview,
      );
    }

    return RotatedBox(
      quarterTurns: quarterTurns,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: preview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeContext = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          localeContext.camera,
          style: const TextStyle(
            fontSize: 20,
            color: largeTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: buttonAndAppBarColor,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                buildCameraPreview(),
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCameraButton(
                        onPressed: changeCameraLens,
                        icon: Icons.cameraswitch,
                      ),
                      stopButtonPressed
                          ? _buildNextButton(localeContext.next)
                          : _buildRecordButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.all(55),
                  child: Text(
                    "${(timerValue / 60).floor()} : ${(timerValue % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 50,
                      color: smallTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: buttonAndAppBarColor,
        elevation: 4,
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          largeTextColor.withAlpha(26),
        ),
      ),
      child: Icon(
        icon,
        color: smallTextColor,
        size: 30,
      ),
    );
  }

  Widget _buildRecordButton() {
    return ElevatedButton(
      onPressed: onVideoRecordButtonPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: buttonAndAppBarColor,
        elevation: 4,
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          largeTextColor.withAlpha(26),
        ),
      ),
      child: Icon(
        isRecording ? Icons.stop : Icons.videocam_sharp,
        color: smallTextColor,
        size: 30,
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return ElevatedButton(
      onPressed: () => context.go("/feedbackScreen"),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonAndAppBarColor,
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 4,
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          largeTextColor.withAlpha(26),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: smallTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
