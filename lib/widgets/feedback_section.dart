import 'package:flutter/material.dart';
import 'package:pitch_perfect/constants.dart';

class FeedbackSection extends StatefulWidget {
  const FeedbackSection(
      {super.key,
      required this.feedbackTitle,
      required this.percent,
      required this.feedback});

  final String feedbackTitle;
  final String percent;
  final String feedback;

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  bool alreadyShowingFeedback = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
            color: buttonAndAppBarColor,
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                Text(
                  widget.feedbackTitle,
                  style: const TextStyle(
                    color: smallTextColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.percent,
                    style: const TextStyle(
                        color: largeTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                        if (alreadyShowingFeedback) {
                          alreadyShowingFeedback = false;
                        } else {
                          alreadyShowingFeedback = true;
                        }
                      });
                    },
                    icon: Icon(
                      alreadyShowingFeedback
                          ? Icons.arrow_drop_down
                          : Icons.arrow_right,
                      color: smallTextColor,
                    )),
              ]),
              alreadyShowingFeedback
                  ? Text(
                      widget.feedback,
                      style:
                          const TextStyle(color: smallTextColor, fontSize: 12),
                    )
                  : const Text("")
            ],
          ),
        ),
      ),
    );
  }
}
