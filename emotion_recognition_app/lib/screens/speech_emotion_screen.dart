import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/speech_emotion_service.dart';

class SpeechEmotionScreen extends StatefulWidget {
  const SpeechEmotionScreen({Key? key}) : super(key: key);

  @override
  State<SpeechEmotionScreen> createState() => _SpeechEmotionScreenState();
}

class _SpeechEmotionScreenState extends State<SpeechEmotionScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechEmotionService _emotionService = SpeechEmotionService();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _status = 'Tap the microphone to start recording';
  EmotionResult? _result;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _emotionService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing model: $e';
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
      _recordingPath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

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
        _status = 'Recording... Speak now!';
        _result = null;
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
        _status = 'Processing audio...';
      });

      await _processAudio();
    } catch (e) {
      setState(() {
        _status = 'Error stopping recording: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processAudio() async {
    if (_recordingPath == null) return;

    try {
      final file = File(_recordingPath!);
      if (!await file.exists()) {
        setState(() {
          _status = 'Recording file not found';
          _isProcessing = false;
        });
        return;
      }

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

      final result = await _emotionService.predictEmotion(floatSamples);

      setState(() {
        _result = result;
        _status = 'Analysis complete!';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error processing audio: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _emotionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Emotion Recognition'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 30),
                _buildRecordButton(),
                const SizedBox(height: 30),
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
              _isRecording
                  ? Icons.mic
                  : _isProcessing
                      ? Icons.hourglass_empty
                      : Icons.mic_none,
              size: 50,
              color: _isRecording ? Colors.red : Colors.blue[700],
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

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isInitialized && !_isProcessing
          ? (_isRecording ? _stopRecording : _startRecording)
          : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? Colors.red : Colors.blue[700],
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : Colors.blue[700]!).withOpacity(0.4),
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
            const Icon(Icons.psychology, size: 40, color: Colors.blue),
            const SizedBox(height: 15),
            const Text(
              'Detected Emotion',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _result!.emotion.toUpperCase(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_result!.confidence * 100).toStringAsFixed(1)}% Confidence',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildTopProbabilities(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProbabilities() {
    final topIndices = <int>[];
    final sortedProbs = List<double>.from(_result!.probabilities);
    sortedProbs.sort((a, b) => b.compareTo(a));

    for (var prob in sortedProbs.take(5)) {
      final index = _result!.probabilities.indexOf(prob);
      if (!topIndices.contains(index)) {
        topIndices.add(index);
      }
    }

    return Column(
      children: topIndices.map((i) {
        final label = SpeechEmotionService.emotionLabels[i];
        final prob = _result!.probabilities[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('${(prob * 100).toStringAsFixed(1)}%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
