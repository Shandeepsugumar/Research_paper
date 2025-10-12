import 'dart:async';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/audio_processor.dart';

class FusionEmotionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const List<String> emotionLabels = [
    'Angry', 'Calm', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise'
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/fusion_model.tflite');
      _isInitialized = true;
      print('✅ Fusion Model loaded successfully');
      print('Input tensors: ${_interpreter!.getInputTensors().length}');
      for (var i = 0; i < _interpreter!.getInputTensors().length; i++) {
        print('Input $i shape: ${_interpreter!.getInputTensors()[i].shape}');
      }
      print('Output shape: ${_interpreter!.getOutputTensors()[0].shape}');
    } catch (e) {
      print('❌ Error loading Fusion model: $e');
      rethrow;
    }
  }

  Future<FusionEmotionResult> predictEmotion(
    Float32List audioSamples,
    List<double> hrData,
  ) async {
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

    final speechFeatures = <double>[];
    for (var mfccCoeff in mfcc2d) {
      final mean = mfccCoeff.reduce((a, b) => a + b) / mfccCoeff.length;
      speechFeatures.add(mean);
    }

    List<double> herFeatures = List<double>.from(hrData);
    if (herFeatures.length > 100) {
      herFeatures = herFeatures.sublist(0, 100);
    } else if (herFeatures.length < 100) {
      herFeatures.addAll(List.filled(100 - herFeatures.length, 0.0));
    }

    final speechMean = speechFeatures.reduce((a, b) => a + b) / speechFeatures.length;
    final speechVariance = speechFeatures.map((x) => (x - speechMean) * (x - speechMean)).reduce((a, b) => a + b) / speechFeatures.length;
    final speechStd = speechVariance > 0 ? speechVariance : 0.0001;
    final normalizedSpeech = speechFeatures.map((x) => (x - speechMean) / speechStd).toList();

    final herMean = herFeatures.reduce((a, b) => a + b) / herFeatures.length;
    final herVariance = herFeatures.map((x) => (x - herMean) * (x - herMean)).reduce((a, b) => a + b) / herFeatures.length;
    final herStd = herVariance > 0 ? herVariance : 0.0001;
    final normalizedHer = herFeatures.map((x) => (x - herMean) / herStd).toList();

    final speechInput = [
      normalizedSpeech
    ];
    final herInput = [
      [normalizedHer]
    ];

    final output = List.filled(1, List.filled(emotionLabels.length, 0.0));

    final inputs = {
      0: speechInput,
      1: herInput,
    };

    final outputs = {
      0: output,
    };

    _interpreter!.runForMultipleInputs(inputs, outputs);

    final probabilities = List<double>.from(output[0]);

    int maxIndex = 0;
    double maxValue = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxValue) {
        maxValue = probabilities[i];
        maxIndex = i;
      }
    }

    return FusionEmotionResult(
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

class FusionEmotionResult {
  final String emotion;
  final double confidence;
  final List<double> probabilities;

  FusionEmotionResult({
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
