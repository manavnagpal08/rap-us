import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAvailable = false;

  // Initialize Speech and TTS
  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('Voice Status: $status'),
        onError: (error) => debugPrint('Voice Error: $error'),
      );
      
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Normal speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      return _isAvailable;
    } catch (e) {
      debugPrint('Voice Service Init Failed: $e');
      return false;
    }
  }

  // Start Listening
  Future<void> listen({required Function(String) onResult}) async {
    if (!_isAvailable) {
      bool reinit = await init();
      if (!reinit) return;
    }

    _speech.listen(
      onResult: (val) => onResult(val.recognizedWords),
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
    );
  }

  // Stop Listening
  Future<void> stop() async {
    await _speech.stop();
  }

  // Text to Speech
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
