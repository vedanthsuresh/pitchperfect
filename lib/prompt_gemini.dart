import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<String> promptGemini({required List<Content> content}) async {
  await dotenv.load();

  final model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: dotenv.env['PITCH_PERFECT_API_KEY']!,
  );

  final response = await model.generateContent(content);

  return response.text!;
}
