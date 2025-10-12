import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/fusion_emotion_service.dart';
import '../services/heart_rate_service.dart';

class FusionScreen extends StatefulWidget {
  const FusionScreen({Key? key}) : super(key: key);

  @override
  State<FusionScreen> createState() => _FusionScreenState();
}

class _FusionScreenState extends State<FusionScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final FusionEmotionService _fusionService = FusionEmotionService();
  final HeartRateEmotionService _hrService = HeartRateEmotionService();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _status = 'Initialize and record voice + heart rate for fusion analysis';
  FusionEmotionResult? _result;
  String? _recordingPath;
  List<double>? _heartRateData;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _fusionService.initialize();
      await _hrService.initialize();
      await _hrService.initializeGoogleFit();
      setState(() {
        _isInitialized = true;
        _status = 'Ready! Follow the steps below';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing: $e';
      });
    }
  }

  Future<void> _fetchHeartRate() async {
    setState(() {
      _isProcessing = true;
      _status = 'Fetching heart rate data...';
    });

    try {
      final hrData = await _hrService.getHeartRateData();

      if (hrData == null || hrData.isEmpty) {
        setState(() {
          _status = 'No heart rate data found';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _heartRateData = hrData;
        _currentStep = 1;
        _status = 'Heart rate fetched! Now record your voice';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error fetching heart rate: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _status = 'Microphone permission denied';
      });
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/fusion_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _status = 'Recording voice... Speak now!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error starting recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _currentStep = 2;
        _status = 'Processing multimodal data...';
      });

      await _processFusion();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFusion() async {
    if (_recordingPath == null || _heartRateData == null) return;

    try {
      final file = File(_recordingPath!);
      final bytes = await file.readAsBytes();

      final wavHeader = 44;
      final audioData = bytes.sublist(wavHeader);

      final int16List = <int>[];
      for (int i = 0; i < audioData.length - 1; i += 2) {
        final int16 = (audioData[i + 1] << 8) | audioData[i];
        int16List.add(int16 > 32767 ? int16 - 65536 : int16);
      }

      final floatSamples = Float32List.fromList(
        int16List.map((sample) => sample / 32768.0).toList(),
      );

      final result = await _fusionService.predictEmotion(floatSamples, _heartRateData!);

      setState(() {
        _result = result;
        _currentStep = 3;
        _status = 'Fusion analysis complete!';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error processing fusion: $e';
        _isProcessing = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _heartRateData = null;
      _recordingPath = null;
      _result = null;
      _status = 'Ready! Follow the steps below';
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _fusionService.dispose();
    _hrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multimodal Fusion Analysis'),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[700]!, Colors.green[50]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 30),
                _buildStepsIndicator(),
                const SizedBox(height: 30),
                _buildActionButton(),
                const SizedBox(height: 20),
                if (_result != null) _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              _isProcessing
                  ? Icons.hourglass_empty
                  : _currentStep == 3
                      ? Icons.check_circle
                      : Icons.info_outline,
              size: 50,
              color: Colors.green[700],
            ),
            const SizedBox(height: 15),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsIndicator() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            _buildStepItem(0, 'Fetch Heart Rate', Icons.favorite, _heartRateData != null),
            const Divider(),
            _buildStepItem(1, 'Record Voice', Icons.mic, _recordingPath != null),
            const Divider(),
            _buildStepItem(2, 'Fusion Analysis', Icons.merge_type, _result != null),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String title, IconData icon, bool isCompleted) {
    final isActive = _currentStep == step;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? Colors.green[700]
                    : Colors.grey[300],
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isCompleted || isActive ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_currentStep == 0) {
      return ElevatedButton.icon(
        onPressed: _isInitialized && !_isProcessing ? _fetchHeartRate : null,
        icon: const Icon(Icons.favorite),
        label: const Text('Step 1: Fetch Heart Rate'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      );
    } else if (_currentStep == 1) {
      return GestureDetector(
        onTap: _isRecording ? _stopRecording : _startRecording,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording ? Colors.red : Colors.green[700],
            boxShadow: [
              BoxShadow(
                color: (_isRecording ? Colors.red : Colors.green[700]!).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            _isRecording ? Icons.stop : Icons.mic,
            size: 60,
            color: Colors.white,
          ),
        ),
      );
    } else if (_currentStep == 3) {
      return ElevatedButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.refresh),
        label: const Text('Start New Analysis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.psychology, size: 50, color: Colors.green),
            const SizedBox(height: 15),
            const Text(
              'Fused Emotion Prediction',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _result!.emotion.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_result!.confidence * 100).toStringAsFixed(1)}% Confidence',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'All Predictions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...FusionEmotionService.emotionLabels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final prob = _result!.probabilities[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: prob,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(prob * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
