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

  // Step 1: Image Scan (Smart Analysis)
  Future<Map<String, dynamic>> analyzeImage(String imageBase64) async {
    final settings = await _getSettings();
    String provider = settings['active_provider'] ?? _defaultProvider;
    final String openAiKey = (settings['openai_key'] ?? '').toString();
    
    if (provider == 'openai' && openAiKey.isEmpty) {
      provider = 'gemini';
    }

    const prompt = """
    Analyze this image for a US-based repair or build estimation app.
    Return ONLY VALID JSON.
    
    Output Format:
    {
      "object_type": "Specific name of the object (e.g. 'Wooden Dining Chair', 'Kitchen Cabinet')",
      "estimated_dimensions": "Estimated H x W x D in feet/inches (e.g. '3ft x 2ft' or 'Standard Size')",
      "material": "Dominant material detected (e.g. 'Oak Wood', 'Metal', 'Upholstery')",
      "confidence_score": 0.0 to 1.0,
      "questions": [
        "A list of MAX 3 specific, customizable questions to refine the user's intent.",
        "Example 1 (Repair): 'Do you need to replace the entire handle or just the latch?'",
        "Example 2 (Build): 'Would you prefer a modern matte finish or a classic glossy look?'"
      ]
    }
    
    Rules:
    - DO NOT ask basic questions like 'What is this?'. Assume the role of an expert.
    - If confident about dimensions, include them; otherwise, ask a verification question like 'Is this roughly 6ft wide?'.
    - Focus questions on INTENT (Repair vs Replace), STYLE (Modern vs Classic), or SPECIFIC DETAILS not visible (e.g., 'Is the plumbing inside copper or PVC?').
    """;

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
        model: 'gemini-1.5-flash',
        apiKey: key,
      );
      
      final String pureBase64 = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
      final bytes = base64Decode(pureBase64);
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];
      
      try {
        final response = await model.generateContent(content);
        String text = response.text ?? '{}';
        
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
1. CURRENCY: USD ONLY (will be converted on client).
2. LABOR DISCOUNT: AUTOMATICALLY apply a FIXED 20% LABOR DISCOUNT.
3. ECO-SUSTAINABILITY: Provide a 'Green Alternative' for every repair/build.
4. ROI CALCULATION: Estimate the Property Value Increase (ROI) for this project.
5. OUTPUT: Strict JSON schema provided.

CONTEXT:
Object: (Analyze the image to identify if not specified: ${imageAnalysis['object_type']})
Material: ${imageAnalysis['material']}
Dimensions: (Use this if valid: "$dimensions", otherwise ESTIMATE dimensions from the image for an average item of this type. Return the dimensions used in the output).
Location: $location
Intent: $repairOrBuild
Quality: $materialQuality

CALCULATION LOGIC:
1. Identify the object type and standard dimensions if not provided.
2. Estimate standard US labor cost.
3. Apply 20% discount to labor.
4. Estimate material cost using US averages.
5. Provide a 'Repair vs Replace' recommendation.
6. GREEN ADVANTAGE: Suggest a sustainable alternative (e.g., low-flow faucet, recycled wood, LED integration) and calculate estimated 12-month savings.
7. ROI INSIGHT: Estimate how much this specific project adds to the property value based on US real estate trends.
8. Calculate low/likely/high range.

JSON SCHEMA:
{
  "item_summary": "Detailed name of object (e.g. 'Oak Wooden Dining Table', 'Broken Ceramic Vase')",
  "repair_or_build": "$repairOrBuild",
  "dimensions": "Final used dimensions (e.g. '6 ft x 4 ft' or 'Standard Size')",
  "location": "$location",
  "materials": [
    {
      "name": "Material Name",
      "estimated_cost_usd": "10.00"
    }
  ],
  "material_cost_total_usd": "10.00",
  "labor_cost_original_usd": "50.00",
  "labor_discount_percent": 20,
  "labor_cost_final_usd": "40.00",
  "total_estimate_range_usd": {
    "low": "40.00",
    "likely": "50.00",
    "high": "60.00"
  },
  "green_advantage": {
    "sustainable_model": "Product Name/Type Suggestion (e.g. 'EcoFlow Low-Flow Faucet')",
    "impact_description": "Briefly explains environmental benefit.",
    "estimated_annual_savings_usd": "120.00"
  },
  "roi_insight": {
    "estimated_value_increase_usd": "500.00",
    "roi_percentage": "85"
  },
  "risk_level": "Low | Medium | High",
  "confidence_level": "Low | Medium | High",
  "repair_vs_replace_note": "A clear recommendation: Is it better to repair this or buy a new one? Explain why briefly.",
  "disclaimer": "This is an AI-generated estimate based on visual input. Final costs may vary."
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

  Future<String> getHelpResponse(String userQuery) async {
    final query = userQuery.toLowerCase();
    
    if (query.contains('estimate') || query.contains('cost')) {
      return "To create an estimate, go to the Home screen and upload an image of the item. Our AI analyzes the material and damage to provide a cost estimate, automatically applying a 20% labor discount.";
    }
    if (query.contains('contractor') || query.contains('hire') || query.contains('marketplace')) {
      return "You can hire verified pros in the Marketplace. Simply browse contractors by category and location, view their profile, and message them or request a direct cover project.";
    }
    if (query.contains('security') || query.contains('2fa') || query.contains('biometrics')) {
      return "We take security seriously. You can enable Two-Factor Authentication (2FA) and Biometric Login (FaceID/Fingerprint) in the Settings > Security section.";
    }
    if (query.contains('green') || query.contains('sustainable')) {
      return "Every estimate includes a 'Green Advantage' suggestion. This provides eco-friendly alternatives (like low-flow fixtures or recycled materials) and estimates your annual savings.";
    }
    if (query.contains('payment') || query.contains('billing')) {
      return "Payments are handled securely through the platform. You can change your preferred currency in Settings > Preferences.";
    }
    if (query.contains('history')) {
      return "You can view all your past estimates and active projects in the History tab. You can also export any estimate as a PDF for your records.";
    }
    if (query.contains('hello') || query.contains('hi')) {
      return "Hello! I'm the RAP Help Assistant. I can help you with app usage, estimates, marketplace, or security questions. How can I assist you today?";
    }
    
    return "I'm the RAP Help Assistant. I can help with information about estimates, contractors, security, and app features. For specific technical issues, please contact support@rap.com.";
  }
}
