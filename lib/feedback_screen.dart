import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';
import 'package:pitch_perfect/prompt_gemini.dart';
import 'package:pitch_perfect/widgets/feedback_section.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as thumbnail;
import 'package:path_provider/path_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.videoFile,
    required this.topic,
  });

  final XFile? videoFile;
  final String topic;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  List<String> feedback = [];
  Uint8List? audioBytes;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    getFeedback();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> getFeedback() async {
    try {
      final audioFile =
          File('${(await getTemporaryDirectory()).path}/audio_recording.m4a');

      // Check if file exists
      if (!await audioFile.exists()) {
        return;
      }

      audioBytes = await audioFile.readAsBytes();

      // Check if audioBytes is empty
      if (audioBytes == null || audioBytes!.isEmpty) {
        return;
      }


      final timestamps = [
        5000,
        10000,
        15000,
        20000,
        25000,
        30000,
        35000,
        40000,
        45000,
        50000,
        55000,
        60000
      ];

      final List<File> snapshots = [];
      final String languageCode = Localizations.localeOf(context).languageCode;

      List<Part> eyeContactPrompt = [
        TextPart("""
          In what percentage of these images is the person looking at the camera? Give me the response as ONLY a json. Structure the json like this:
          {
            "percentage": "Just the percentage of images in which the person is looking at the camera.",
            "feedbackForPerson": "2-3 sentences of constructive feedback on what they did well and what they can improve on. Don't mention images."
          }
          
          Give me the feedbackForPerson as ${languageCode == 'es' ? 'Spanish' : 'English'}
          """),
      ];

      for (final timestamp in timestamps) {
        final String? snapshotPath =
            await thumbnail.VideoThumbnail.thumbnailFile(
          video: widget.videoFile!.path,
          imageFormat: thumbnail.ImageFormat.JPEG,
          timeMs: timestamp,
          maxHeight: 512,
          quality: 75,
        );

        if (snapshotPath != null) {
          snapshots.add(File(snapshotPath));
        }
      }

      for (final snapshot in snapshots) {
        eyeContactPrompt
            .add(DataPart('image/jpeg', snapshot.readAsBytesSync()));
      }

      String eyeContactFeedback =
          await promptGemini(content: [Content.multi(eyeContactPrompt)]);


      String contentFeedback = await promptGemini(content: [
        Content.data("audio/m4a", audioBytes!),
        Content.text("""
            Based on this audio, analyze how well the presenter covered these key points:
            ${widget.topic}
            1. Introduction of themselves and their topic
            2. Clear explanation of main ideas
            3. Conclusion or call to action
            
            Give me the response as ONLY a json. Structure the json like this:
            {
              "percentage": "Amount of points covered with a percent symbol at the end",
              "feedbackForPerson": "2-3 sentences of constructive feedback on what they did well and what they can improve on."
            }

            Give me the feedbackForPerson as ${languageCode == 'es' ? 'Spanish' : 'English'}
            """)
      ]);


      String enthusiasmFeedback = await promptGemini(content: [
        Content.data("audio/m4a", audioBytes!),
        Content.text("""
          Based on this audio, evaluate the speaker's enthusiasm and energy level. Consider:
          - Vocal variety and tone
          - Pace and energy
          - Engagement and passion for the topic
          
          Give me the response as ONLY a json. Structure the json like this:
          {
            "percentage": "Score for enthusiasm with a percent symbol at the end",
            "feedbackForPerson": "2-3 sentences of constructive feedback on what they did well and what they can improve on."
          }

          Give me the feedbackForPerson as ${languageCode == 'es' ? 'Spanish' : 'English'}
          """)
      ]);

      setState(() {
        feedback.add(eyeContactFeedback);
        feedback.add(contentFeedback);
        feedback.add(enthusiasmFeedback);
      });
      // ignore: empty_catches
    } catch (e) {
      debugPrint("Error in getFeedback: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeContext = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          localeContext.yourFeedback,
          style: const TextStyle(
            fontSize: 28,
            color: largeTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: buttonAndAppBarColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              backgroundColor.withAlpha(217),
              backgroundColor.withAlpha(179),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: feedback.isNotEmpty
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 25),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, (1 - _controller.value) * 20),
                              child: Opacity(
                                opacity: _controller.value,
                                child: FeedbackSection(
                                  feedbackTitle: localeContext.eyeContact,
                                  percent: jsonDecode(feedback[0]
                                      .replaceAll("```", "")
                                      .replaceAll("json", ""))['percentage'],
                                  feedback: jsonDecode(feedback[0]
                                      .replaceAll("```", "")
                                      .replaceAll(
                                          "json", ""))['feedbackForPerson'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, (1 - _controller.value) * 40),
                              child: Opacity(
                                opacity: _controller.value,
                                child: FeedbackSection(
                                  feedbackTitle: localeContext.content,
                                  percent: jsonDecode(feedback[1]
                                      .replaceAll("```", "")
                                      .replaceAll("json", ""))['percentage'],
                                  feedback: jsonDecode(feedback[1]
                                      .replaceAll("```", "")
                                      .replaceAll(
                                          "json", ""))['feedbackForPerson'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, (1 - _controller.value) * 60),
                              child: Opacity(
                                opacity: _controller.value,
                                child: FeedbackSection(
                                  feedbackTitle: localeContext.enthusiasm,
                                  percent: jsonDecode(feedback[2]
                                      .replaceAll("```", "")
                                      .replaceAll("json", ""))['percentage'],
                                  feedback: jsonDecode(feedback[2]
                                      .replaceAll("```", "")
                                      .replaceAll(
                                          "json", ""))['feedbackForPerson'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, (1 - _controller.value) * 80),
                              child: Opacity(
                                opacity: _controller.value,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 25),
                                  decoration: BoxDecoration(
                                    color: buttonAndAppBarColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            buttonAndAppBarColor.withAlpha(102),
                                        spreadRadius: 2,
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24.0,
                                      horizontal: 20.0,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          localeContext.overallPerformance,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: largeTextColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "${_calculateAverageScore()}%",
                                          style: const TextStyle(
                                            fontSize: 48,
                                            color: largeTextColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: LoadingAnimationWidget.inkDrop(
                  color: largeTextColor,
                  size: 100,
                ),
              ),
      ),
    );
  }

  String _calculateAverageScore() {
    double eyeContactScore = double.parse(
        jsonDecode(feedback[0].replaceAll("```", "").replaceAll("json", ""))[
                'percentage']
            .replaceAll('%', ''));

    double contentScore = double.parse(
        jsonDecode(feedback[1].replaceAll("```", "").replaceAll("json", ""))[
                'percentage']
            .replaceAll('%', ''));

    double enthusiasmScore = double.parse(
        jsonDecode(feedback[2].replaceAll("```", "").replaceAll("json", ""))[
                'percentage']
            .replaceAll('%', ''));

    double average = (eyeContactScore + contentScore + enthusiasmScore) / 3;
    return average.toStringAsFixed(1);
  }
}
