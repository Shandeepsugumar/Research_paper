import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:health/health.dart';

class HeartRateEmotionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  Health? _health;

  static const int maxLength = 5000;
  static const List<String> emotionLabels = ['Low Valence', 'High Valence'];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/HER_emotion_model_custom.tflite');
      _isInitialized = true;
      print('✅ HER Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensors()[0].shape}');
      print('Output shape: ${_interpreter!.getOutputTensors()[0].shape}');
    } catch (e) {
      print('❌ Error loading HER model: $e');
      rethrow;
    }
  }

  Future<void> initializeGoogleFit() async {
    _health = Health();

    final types = [
      HealthDataType.HEART_RATE,
    ];

    final permissions = [
      HealthDataAccess.READ,
    ];

    try {
      bool? hasPermissions = await _health!.hasPermissions(types, permissions: permissions);

      if (hasPermissions == null || !hasPermissions) {
        hasPermissions = await _health!.requestAuthorization(types, permissions: permissions);
      }

      if (hasPermissions == true) {
        print('✅ Google Fit permissions granted');
      } else {
        print('❌ Google Fit permissions denied');
      }
    } catch (e) {
      print('❌ Error initializing Google Fit: $e');
    }
  }

  Future<List<double>?> getHeartRateData() async {
    if (_health == null) {
      await initializeGoogleFit();
    }

    try {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 5));

      List<HealthDataPoint> healthData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: earlier,
        endTime: now,
      );

      if (healthData.isEmpty) {
        print('⚠️ No heart rate data available');
        return null;
      }

      final hrValues = healthData
          .map((point) => (point.value as NumericHealthValue).numericValue.toDouble())
          .toList();

      print('✅ Retrieved ${hrValues.length} heart rate values');
      return hrValues;
    } catch (e) {
      print('❌ Error getting heart rate data: $e');
      return null;
    }
  }

  Float32List preprocessHeartRateData(List<double> hrData) {
    List<double> signal = List<double>.from(hrData);

    if (signal.length > maxLength) {
      signal = signal.sublist(0, maxLength);
    } else if (signal.length < maxLength) {
      signal.addAll(List.filled(maxLength - signal.length, 0.0));
    }

    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance = signal.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / signal.length;
    final stdDev = variance > 0 ? variance : 0.0001;
    final sqrtStdDev = stdDev > 0 ? stdDev : 0.0001;

    for (int i = 0; i < signal.length; i++) {
      signal[i] = (signal[i] - mean) / sqrtStdDev;
    }

    return Float32List.fromList(signal);
  }

  Future<HREmotionResult> predictEmotion(List<double> hrData) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call initialize() first.');
    }

    final preprocessed = preprocessHeartRateData(hrData);

    final input = List.generate(
      1,
      (_) => List.generate(maxLength, (i) => preprocessed[i]),
    );

    final output = List.filled(1, List.filled(2, 0.0));

    _interpreter!.run(input, output);

    final probabilities = List<double>.from(output[0]);

    int maxIndex = probabilities[0] > probabilities[1] ? 0 : 1;
    double maxValue = probabilities[maxIndex];

    return HREmotionResult(
      emotion: emotionLabels[maxIndex],
      confidence: maxValue,
      probabilities: probabilities,
    );
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

class HREmotionResult {
  final String emotion;
  final double confidence;
  final List<double> probabilities;

  HREmotionResult({
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
