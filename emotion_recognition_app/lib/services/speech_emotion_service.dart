import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/audio_processor.dart';

class SpeechEmotionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const List<String> emotionLabels = [
    'Neutral', 'Calm', 'Happy', 'Sad', 'Angry', 'Fearful', 'Disgust', 'Surprised',
    'Neutral-Strong', 'Calm-Strong', 'Happy-Strong', 'Sad-Strong', 'Angry-Strong',
    'Fearful-Strong', 'Disgust-Strong', 'Surprised-Strong', 'Neutral-Normal',
    'Calm-Normal', 'Happy-Normal', 'Sad-Normal', 'Angry-Normal', 'Fearful-Normal',
    'Disgust-Normal', 'Surprised-Normal', 'Neutral-Weak', 'Calm-Weak'
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/ser_cpu_rnn_model.tflite');
      _isInitialized = true;
      print('✅ SER Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensors()[0].shape}');
      print('Output shape: ${_interpreter!.getOutputTensors()[0].shape}');
    } catch (e) {
      print('❌ Error loading SER model: $e');
      rethrow;
    }
  }

  Future<EmotionResult> predictEmotion(Float32List audioSamples) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    final mfcc2d = AudioProcessor.computeMFCC(
      audioSamples,
      AudioProcessor.sampleRate,
      AudioProcessor.nFft,
      AudioProcessor.hopLength,
      AudioProcessor.nMfcc,
    );

    final mfccPadded = AudioProcessor.padOrTruncateMFCC(mfcc2d, AudioProcessor.targetFrames);

    final inputNested = List.generate(
      1,
      (_) => List.generate(
        AudioProcessor.nMfcc,
        (i) => List.generate(AudioProcessor.targetFrames, (j) => mfccPadded[i][j]),
      ),
    );

    final output = List.filled(1, List.filled(emotionLabels.length, 0.0));

    _interpreter!.run(inputNested, output);

    final probabilities = List<double>.from(output[0]);

    int maxIndex = 0;
    double maxValue = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxValue) {
        maxValue = probabilities[i];
        maxIndex = i;
      }
    }

    return EmotionResult(
      emotion: maxIndex < emotionLabels.length ? emotionLabels[maxIndex] : 'Unknown',
      confidence: maxValue,
      probabilities: probabilities,
    );
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

class EmotionResult {
  final String emotion;
  final double confidence;
  final List<double> probabilities;

  EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.probabilities,
  });

  Map<String, dynamic> toJson() => {
        'emotion': emotion,
        'confidence': confidence,
        'probabilities': probabilities,
      };
}
