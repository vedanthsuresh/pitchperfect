import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pitch_perfect/camera_screen.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:pitch_perfect/feedback_screen.dart';
import 'package:pitch_perfect/presentation_topic_screen.dart';
import 'package:pitch_perfect/prompt_gemini.dart';
import 'package:pitch_perfect/requirements_screen.dart';
import 'package:pitch_perfect/timer_screen.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

String presentationTopic = "";
String ideas = "";
XFile? videoFile;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();
const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin);
late List<CameraDescription> cameras;

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'presentationTopicScreen',
          builder: (BuildContext context, GoRouterState state) {
            return PresentationTopicScreen(topic: presentationTopic);
          },
        ),
        GoRoute(
          path: 'requirementsScreen',
          builder: (BuildContext context, GoRouterState state) {
            return RequirementsScreen(topic: presentationTopic);
          },
        ),
        GoRoute(
          path: 'timerScreen',
          builder: (BuildContext context, GoRouterState state) {
            return const TimerScreen();
          },
        ),
        GoRoute(
          path: 'cameraScreen',
          builder: (BuildContext context, GoRouterState state) {
            return const CameraScreen();
          },
        ),
        GoRoute(
          path: 'feedbackScreen',
          builder: (BuildContext context, GoRouterState state) {
            return FeedbackScreen(
                topic: presentationTopic, videoFile: videoFile);
          },
        )
      ],
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  cameras = await availableCameras();

  presentationTopic = await promptGemini(content: [
    Content.text(
        "Give me a random simple commonly known presentation topic that is 3 words or less that can be covered in 60 seconds with no periods, first letter capital and the rest lowercase")
  ]);
  runApp(const MyApp());
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.topic});

  final String? topic;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp.router(
      routerConfig: _router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoaded = false;
  bool _hasShownText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _isLoaded = true;
        _hasShownText = true;
      });
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeContext = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 4,
        title: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _isLoaded ? 1.0 : 0.0,
          child: Text(
            localeContext.pitchPerfect,
            style: const TextStyle(
              fontSize: 24,
              color: largeTextColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: buttonAndAppBarColor,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                Color.lerp(backgroundColor, Colors.transparent, 0.2)!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buttonAndAppBarColor
                          .withAlpha(((_isLoaded ? 0.1 : 0) * 255).toInt()),
                    ),
                    child: Hero(
                      tag: 'mic_icon',
                      child: Icon(
                        Icons.mic_rounded,
                        size: 80,
                        color: largeTextColor
                            .withAlpha(((_isLoaded ? 1.0 : 0) * 255).toInt()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Modified Welcome Text
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _isLoaded ? 1.0 : 0.0,
                  child: _hasShownText
                      ? Text(
                          localeContext.letsPresent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: largeTextColor,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Color(0x29000000),
                              ),
                            ],
                          ),
                        )
                      : AnimatedTextKit(
                          onFinished: () {
                            setState(() {
                              _hasShownText = true;
                            });
                          },
                          animatedTexts: [
                            FadeAnimatedText(
                              localeContext.letsPresent,
                              textAlign: TextAlign.center,
                              textStyle: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: largeTextColor,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Color(0x29000000),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                ),
                const SizedBox(height: 50),
                // Animated Button
                AnimatedSlide(
                  duration: const Duration(milliseconds: 800),
                  offset: _isLoaded ? Offset.zero : const Offset(0, 2),
                  curve: Curves.easeOutQuart,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: _isLoaded ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: buttonAndAppBarColor
                                .withAlpha((0.3 * 255).toInt()),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Add button press animation
                          ScaffoldMessenger.of(context).clearSnackBars();
                          context.go("/presentationTopicScreen");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonAndAppBarColor,
                          minimumSize: const Size(220, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.all(
                            largeTextColor.withAlpha((0.1 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localeContext.present,
                              style: const TextStyle(
                                color: smallTextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: smallTextColor,
                            ),
                          ],
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
    );
  }
}
