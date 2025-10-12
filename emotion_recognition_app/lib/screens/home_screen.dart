import 'package:flutter/material.dart';
import 'speech_emotion_screen.dart';
import 'heart_rate_screen.dart';
import 'fusion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal[700]!, Colors.teal[100]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Emotion Recognition',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Multimodal Emotion Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      _buildFeatureCard(
                        context,
                        title: 'Speech Emotion Recognition',
                        description: 'Analyze emotions from voice recordings using AI',
                        icon: Icons.mic,
                        color: Colors.blue[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SpeechEmotionScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCard(
                        context,
                        title: 'Heart Rate Emotion Recognition',
                        description: 'Detect emotional valence from heart rate data',
                        icon: Icons.favorite,
                        color: Colors.red[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HeartRateScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCard(
                        context,
                        title: 'Multimodal Fusion Analysis',
                        description: 'Combined voice and heart rate emotion detection',
                        icon: Icons.merge_type,
                        color: Colors.green[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FusionScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Powered by TensorFlow Lite',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Advanced Deep Learning Models',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
