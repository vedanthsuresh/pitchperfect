import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';

class PresentationTopicScreen extends StatefulWidget {
  const PresentationTopicScreen({super.key, required this.topic});
  final String topic;

  @override
  State<PresentationTopicScreen> createState() =>
      _PresentationTopicScreenState();
}

class _PresentationTopicScreenState extends State<PresentationTopicScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    ));

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    // Show button after topic animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() => _showButton = true);
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
        backgroundColor: buttonAndAppBarColor,
        elevation: 4,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            localeContext.yourPresentationTopicIs,
            style: const TextStyle(
              color: largeTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              backgroundColor.withAlpha(204),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: largeTextColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          widget.topic,
                          speed: const Duration(milliseconds: 100),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _showButton ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                offset: _showButton ? Offset.zero : const Offset(0, 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: buttonAndAppBarColor.withAlpha(77),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go("/requirementsScreen"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonAndAppBarColor,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        largeTextColor.withAlpha(26),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localeContext.next,
                          style: const TextStyle(
                            color: smallTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
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
    );
  }
}
