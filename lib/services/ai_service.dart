import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:rap_app/services/database_service.dart';

class AiService {
  final DatabaseService _db = DatabaseService();
  
  // Fallbacks in case Firestore fetch fails or isn't set yet
  static const String _defaultGeminiKey = "AIzaSyCob6dZZSd3_6gpDN8AMkuc_GHxyAQkFbA";
  static const String _defaultProvider = "gemini";

  Future<Map<String, dynamic>> _getSettings() async {
    try {
      return await _db.getAiSettings();
    } catch (e) {
      return {
        'active_provider': _defaultProvider,
        'gemini_key': _defaultGeminiKey,
        'openai_key': '',
      };
    }
  }

  // Step 1: Image Scan (Silently analyze)
  Future<Map<String, dynamic>> analyzeImage(String imageBase64) async {
    final settings = await _getSettings();
    String provider = settings['active_provider'] ?? _defaultProvider;
    final String openAiKey = (settings['openai_key'] ?? '').toString();
    
    // Auto-fallback if OpenAI is selected but no key is provided
    if (provider == 'openai' && openAiKey.isEmpty) {
      provider = 'gemini';
    }

    final prompt = "You are the RAP silent analyzer. Analyze this image and identify: object type, material, damage/build intent, and complexity. Return ONLY JSON.";

    if (provider == 'openai') {
      OpenAI.apiKey = openAiKey;
      final response = await OpenAI.instance.chat.create(
        model: "gpt-4o",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(imageBase64)],
          ),
        ],
        responseFormat: {"type": "json_object"},
      );
      return jsonDecode(response.choices.first.message.content!.first.text!);
    } else {
      // Gemini Logic
      String key = (settings['gemini_key'] ?? '').toString();
      if (key.isEmpty) key = _defaultGeminiKey;

      final model = GenerativeModel(
        model: 'gemini-flash-latest', // Alias to latest available Flash for this key
        apiKey: key,
      );
      
      final String pureBase64 = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
      final bytes = base64Decode(pureBase64);
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes), // Safer default for camera/gallery
        ])
      ];
      
      try {
        final response = await model.generateContent(content);
        String text = response.text ?? '{}';
        
        // Advanced cleanup for Gemini's potentially verbose JSON output
        if (text.contains('```json')) {
          text = text.split('```json').last.split('```').first;
        } else if (text.contains('```')) {
          text = text.split('```').last.split('```').first;
        }
        
        return jsonDecode(text.trim());
      } catch (e) {
        throw 'Gemini Analysis Failed: $e';
      }
    }
  }

  // Final Cost Estimation Logic
  Future<Map<String, dynamic>> getFinalEstimate({
    required Map<String, dynamic> imageAnalysis,
    required String dimensions,
    required String location,
    required String repairOrBuild,
    required String materialQuality,
  }) async {
    final settings = await _getSettings();
    String provider = settings['active_provider'] ?? _defaultProvider;
    final String openAiKey = (settings['openai_key'] ?? '').toString();

    // Auto-fallback if OpenAI is selected but no key is provided
    if (provider == 'openai' && openAiKey.isEmpty) {
      provider = 'gemini';
    }
    
    final systemPrompt = """
You are the core AI for RAP (Repair & Assembly Platform).
Your role: US-based cost estimation.

RULES:
1. CURRENCY: USD ONLY.
2. LABOR DISCOUNT: AUTOMATICALLY apply a FIXED 20% LABOR DISCOUNT.
3. OUTPUT: Strict JSON schema provided.

CONTEXT:
Object: ${imageAnalysis['object_type']}
Material: ${imageAnalysis['material']}
Dimensions: $dimensions
Location: $location
Intent: $repairOrBuild
Quality: $materialQuality

CALCULATION LOGIC:
1. Estimate standard US labor cost.
2. Apply 20% discount to labor (Original - 20% = Final).
3. Estimate material cost using US averages.
4. Calculate low/likely/high range.

JSON SCHEMA:
{
  "item_summary": "",
  "repair_or_build": "",
  "dimensions": "",
  "location": "",
  "materials": [
    {
      "name": "",
      "estimated_cost_usd": ""
    }
  ],
  "material_cost_total_usd": "",
  "labor_cost_original_usd": "",
  "labor_discount_percent": 20,
  "labor_cost_final_usd": "",
  "total_estimate_range_usd": {
    "low": "",
    "likely": "",
    "high": ""
  },
  "confidence_level": "Low | Medium | High",
  "repair_vs_replace_note": "",
  "disclaimer": "This is an AI-generated estimate based on visual input and user-provided information. Final costs may vary by location and technician."
}
""";

    if (provider == 'openai') {
      OpenAI.apiKey = openAiKey;
      final response = await OpenAI.instance.chat.create(
        model: "gpt-4o",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
          ),
        ],
        responseFormat: {"type": "json_object"},
      );
      return jsonDecode(response.choices.first.message.content!.first.text!);
    } else {
      // Gemini Logic
      String key = (settings['gemini_key'] ?? '').toString();
      if (key.isEmpty) key = _defaultGeminiKey;

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: key,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(systemPrompt)]);
      String text = response.text ?? '{}';
      return jsonDecode(text.trim());
    }
  }
}
