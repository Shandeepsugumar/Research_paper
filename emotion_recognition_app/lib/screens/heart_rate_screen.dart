import 'package:flutter/material.dart';
import '../services/heart_rate_service.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({Key? key}) : super(key: key);

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  final HeartRateEmotionService _emotionService = HeartRateEmotionService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _status = 'Tap to fetch heart rate data from Google Fit';
  HREmotionResult? _result;
  List<double>? _heartRateData;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _emotionService.initialize();
      await _emotionService.initializeGoogleFit();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing: $e';
      });
    }
  }

  Future<void> _fetchAndAnalyze() async {
    setState(() {
      _isProcessing = true;
      _status = 'Fetching heart rate data from Google Fit...';
      _result = null;
    });

    try {
      final hrData = await _emotionService.getHeartRateData();

      if (hrData == null || hrData.isEmpty) {
        setState(() {
          _status = 'No heart rate data found. Please ensure Google Fit has data.';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _heartRateData = hrData;
        _status = 'Analyzing heart rate data...';
      });

      final result = await _emotionService.predictEmotion(hrData);

      setState(() {
        _result = result;
        _status = 'Analysis complete!';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _emotionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Emotion Recognition'),
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[700]!, Colors.red[50]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 30),
                _buildFetchButton(),
                const SizedBox(height: 30),
                if (_heartRateData != null) _buildHeartRateInfo(),
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
              _isProcessing ? Icons.favorite : Icons.favorite_border,
              size: 50,
              color: Colors.red[700],
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

  Widget _buildFetchButton() {
    return ElevatedButton.icon(
      onPressed: _isInitialized && !_isProcessing ? _fetchAndAnalyze : null,
      icon: const Icon(Icons.cloud_download, size: 28),
      label: const Text('Fetch from Google Fit', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
    );
  }

  Widget _buildHeartRateInfo() {
    final avgHR = _heartRateData!.reduce((a, b) => a + b) / _heartRateData!.length;
    final minHR = _heartRateData!.reduce((a, b) => a < b ? a : b);
    final maxHR = _heartRateData!.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Heart Rate Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Average', '${avgHR.toStringAsFixed(1)} bpm'),
                _buildStatItem('Min', '${minHR.toStringAsFixed(0)} bpm'),
                _buildStatItem('Max', '${maxHR.toStringAsFixed(0)} bpm'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Data points: ${_heartRateData!.length}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
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
            const Icon(Icons.psychology, size: 40, color: Colors.red),
            const SizedBox(height: 15),
            const Text(
              'Emotional Valence',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _result!.emotion.toUpperCase(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_result!.confidence * 100).toStringAsFixed(1)}% Confidence',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Column(
              children: HeartRateEmotionService.emotionLabels.asMap().entries.map((entry) {
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
                              color: Colors.red[700],
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
            ),
          ],
        ),
      ),
    );
  }
}
