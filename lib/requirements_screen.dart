import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pitch_perfect/constants.dart';
import 'package:pitch_perfect/l10n/app_localizations.dart';
import 'package:pitch_perfect/main.dart';
import 'package:pitch_perfect/prompt_gemini.dart';
import 'package:pitch_perfect/widgets/requirement.dart';

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key, required this.topic});
  final String topic;

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<AnimationController> _slideControllers;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _slideAnimations;
  bool _showButton = false;
  var requirements = ["", "", ""];
  var dataLoaded = false;
  int _currentRequirement = 0;

  @override
  void initState() {
    super.initState();

    // Initialize fade controller for the title
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);

    // Initialize slide controllers for each requirement
    _slideControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    // Create slide animations
    _slideAnimations = _slideControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    loadData();
  }

  Future<void> loadData() async {
    final ideas = await promptGemini(content: [
      Content.text(
          "Give me three commonly known ideas that are 3-5 words long or less separated by commas and each one starting with a capital letter with no periods that should be covered in a presentation about $presentationTopic")
    ]);
    setState(() {
      requirements = ideas.toString().split(',');
      dataLoaded = true;
    });

    // Start initial animations
    _fadeController.forward();
    _showNextRequirement();
  }

  void _showNextRequirement() {
    if (_currentRequirement < 3) {
      _slideControllers[_currentRequirement].forward();
      _currentRequirement++;

      if (_currentRequirement == 3) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _showButton = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _slideControllers) {
      controller.dispose();
    }
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
            localeContext.threeIdeas,
            style: const TextStyle(
              fontSize: 18,
              color: largeTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _showNextRequirement,
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
          child: dataLoaded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      return Stack(
                        children: [
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _slideControllers[index].isCompleted
                                  ? 0.0
                                  : 1.0,
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: largeTextColor,
                                size: 24,
                              ),
                            ),
                          ),
                          SlideTransition(
                            position: _slideAnimations[index],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 40,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 80,
                                  ),
                                  child: Requirement(
                                    requirementTitle: requirements[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 40),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _showButton ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 500),
                        offset:
                            _showButton ? Offset.zero : const Offset(0, 0.5),
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
                            onPressed: () => context.go("/timerScreen"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonAndAppBarColor,
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
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
                )
              : Center(
                  child: LoadingAnimationWidget.inkDrop(
                    color: largeTextColor,
                    size: 100,
                  ),
                ),
        ),
      ),
    );
  }
}
