import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';
import 'package:pitch_perfect/main.dart';

// ignore: must_be_immutable
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => TimerScreenState();
}

class TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _fiveMinutesFromNow;
  late final ValueNotifier<String> _countdownValueNotifier;
  late Timer _timer;
  bool buttonClickable = false;

  // Animation controller for the pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5, seconds: 1));
    _countdownValueNotifier = ValueNotifier(_getCurrentCountdownValue());

    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster pulse
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2), // Bigger pulse
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

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _countdownValueNotifier.value = _getCurrentCountdownValue();
      // Trigger pulse animation on each second
      _pulseController.forward().then((_) => _pulseController.reset());

      if (DateTime.now().isAfter(_fiveMinutesFromNow)) {
        _timer.cancel();
        setState(() {
          buttonClickable = true;
        });
        // Move notification creation to build method or create a separate method
        await _showTimeUpNotification(context);
      }
    });
  }

  Future<void> _showTimeUpNotification(BuildContext context) async {
    final localeContext = AppLocalizations.of(context)!;
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, localeContext.timeToPresent,
        localeContext.your5MinutesAreUp, notificationDetails);
  }

  String _getCurrentCountdownValue() {
    final now = DateTime.now();
    final difference = now.difference(_fiveMinutesFromNow).abs();
    return "${difference.inMinutes} : ${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _countdownValueNotifier.dispose();
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeContext = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localeContext.fiveMinutes,
          style: const TextStyle(
            fontSize: 12.5,
            color: largeTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: buttonAndAppBarColor,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              backgroundColor.withAlpha(204), // 0.8 * 255 ≈ 204
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _countdownValueNotifier,
                        builder: (context, value, child) {
                          return Text(
                            value,
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: largeTextColor,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: buttonClickable ? 1.0 : 0.7,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: buttonAndAppBarColor
                            .withAlpha(77), // 0.3 * 255 ≈ 77
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go("/cameraScreen"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonAndAppBarColor,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        largeTextColor.withAlpha(26), // 0.1 * 255 ≈ 26
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buttonClickable
                              ? localeContext.next
                              : localeContext.skipToPresentation,
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
