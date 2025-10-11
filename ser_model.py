// voice_emotion_page.dart
// Real-time voice -> MFCC -> TFLite inference (ser_cpu_rnn_model.tflite)
// Replace placeholder labels with your actual labels mapping.

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// --------------------------- CONFIG ---------------------------
// Sample rate used for processing (must match model preprocessing assumptions)
const int sampleRate = 22050;

// MFCC settings following ser_model.py assumptions
const int nMfcc = 40;
const int nFft = 512;       // n_fft
const int hopLength = 256;  // hop length
const int targetFrames = 174; // number of frames model expects

// Derived: number of samples needed to produce targetFrames
int get requiredSamples => hopLength * (targetFrames - 1) + nFft; // 256*(174-1)+512 ≈ 44800

// MFCC DCT length (keep same as nMfcc)
const int dctLength = nMfcc;

// Inference frequency: run inference when we have 'requiredSamples' in buffer
const Duration inferenceInterval = Duration(milliseconds: 1600);

// Path inside assets
const String tfliteModelAsset = 'assets/ser_cpu_rnn_model.tflite';

// Placeholder labels - REPLACE with your real emotion labels (26 entries)
final List<String> emotionLabels = List.generate(26, (i) => 'Class $i');

// --------------------------- UI Page ---------------------------

class VoiceEmotionPage extends StatefulWidget {
  const VoiceEmotionPage({Key? key}) : super(key: key);

  @override
  State<VoiceEmotionPage> createState() => _VoiceEmotionPageState();
}

class _VoiceEmotionPageState extends State<VoiceEmotionPage> {
  final FlutterAudioCapture _audioRecorder = FlutterAudioCapture();
  final Queue<double> _ringBuffer = Queue<double>(); // holds recent samples (mono)
  Interpreter? _interpreter;
  bool _isListening = false;
  Timer? _inferenceTimer;

  // UI state
  String _status = 'Idle';
  String _topLabel = '';
  double _topConfidence = 0.0;
  List<double> _lastProbabilities = [];

  @override
  void initState() {
    super.initState();
    _initializeInterpreter();
  }

  @override
  void dispose() {
    _stopListening();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initializeInterpreter() async {
    setState(() {
      _status = 'Loading model...';
    });
    try {
      _interpreter = await Interpreter.fromAsset(tfliteModelAsset.replaceFirst('assets/', ''));
      // Optionally print shapes (debug)
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      debugPrint('TFLite input shape: ${inputTensors[0].shape}');
      debugPrint('TFLite output shape: ${outputTensors[0].shape}');
      setState(() {
        _status = 'Model loaded';
      });
    } catch (e) {
      debugPrint('Error loading model: $e');
      setState(() {
        _status = 'Model load failed: $e';
      });
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    try {
      // start audio capture; we request float32 PCM in callback
      await _audioRecorder.start(listener, onError,
          sampleRate: sampleRate, bufferSize: 3000);
      _isListening = true;
      setState(() {
        _status = 'Listening...';
      });

      // Start inference timer to periodically check buffer
      _inferenceTimer = Timer.periodic(inferenceInterval, (_) {
        _maybeRunInference();
      });
    } catch (e) {
      debugPrint('Start listening error: $e');
      setState(() {
        _status = 'Start listening error: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    try {
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
    _inferenceTimer?.cancel();
    _isListening = false;
    setState(() {
      _status = 'Stopped';
    });
  }

  // Listener callback receives raw Float64List or Float32List depending on plugin
  void listener(dynamic obj) {
    // obj usually looks like Float32List or Float64List interleaved (L,R) or mono depending on platform
    try {
      var buffer = Float64List(0);
      if (obj is Float64List) {
        buffer = obj;
      } else if (obj is Float32List) {
        // promote
        buffer = Float64List(obj.length);
        for (int i = 0; i < obj.length; i++) buffer[i] = obj[i].toDouble();
      } else if (obj is List<dynamic>) {
        // convert list of doubles
        final list = obj.cast<num>();
        buffer = Float64List(list.length);
        for (int i = 0; i < list.length; i++) buffer[i] = list[i].toDouble();
      } else {
        // fallback
        return;
      }

      // audio might be stereo interleaved L,R. We'll take every 1 sample (mono) or average pairs.
      // For safety, handle both cases: if length is odd/even unknown - assume mono.
      for (int i = 0; i < buffer.length; i++) {
        _ringBuffer.add(buffer[i].toDouble());
      }

      // trim to requiredSamples * 2 (some extra) for safety, but keep at most requiredSamples
      while (_ringBuffer.length > requiredSamples * 2) {
        _ringBuffer.removeFirst();
      }
    } catch (e) {
      debugPrint('Listener parsing error: $e');
    }
  }

  void onError(Object e) {
    debugPrint('Audio capture error: $e');
    setState(() {
      _status = 'Audio capture error: $e';
    });
  }

  Future<void> _maybeRunInference() async {
    if (_interpreter == null) return;
    if (_ringBuffer.length < requiredSamples) {
      debugPrint('Need ${requiredSamples - _ringBuffer.length} more samples for inference...');
      return;
    }

    // Take the most recent requiredSamples from ring buffer
    final List<double> samples = _takeRecentSamples(requiredSamples);

    // Convert Float64 samples to float32 normalized between -1 and +1 (already likely so)
    final Float32List floatSamples = Float32List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      floatSamples[i] = samples[i].toDouble().toFloat();
    }

    setState(() {
      _status = 'Processing audio...';
    });

    // Compute MFCC -> result 2D [nMfcc, frames]
    final List<List<double>> mfcc2d = computeMFCC(floatSamples, sampleRate, nFft, hopLength, nMfcc);

    // Ensure frames dimension is targetFrames by pad/truncate
    final List<List<double>> mfccPadded = padOrTruncateMFCC(mfcc2d, targetFrames);

    // Build input as [1, nMfcc, targetFrames] flattened
    // The Python model expects shape (1, 40, 174) — we pass Float32List accordingly
    final inputBuffer = Float32List(nMfcc * targetFrames);
    for (int i = 0; i < nMfcc; i++) {
      for (int j = 0; j < targetFrames; j++) {
        inputBuffer[i * targetFrames + j] = mfccPadded[i][j].toFloat();
      }
    }

    // tflite_flutter expects nested lists or typed buffer depending on interpreter config
    // We'll use shaped input List with proper nesting: [ [ [..] ] ] => [1][40][174]
    // Build nested List<double>
    final List<List<List<double>>> inputNested = List.generate(1, (_) =>
        List.generate(nMfcc, (i) => List.generate(targetFrames, (j) => mfccPadded[i][j])));

    // Prepare output buffer: model outputs [1, 26] probabilities
    final output = List.filled(1, List.filled(26, 0.0));

    try {
      _interpreter!.run(inputNested, output);

      final probs = List<double>.from(output[0].map((e) => e.toDouble()));

      // find max
      int maxIndex = 0;
      double maxVal = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxVal) {
          maxVal = probs[i];
          maxIndex = i;
        }
      }

      setState(() {
        _lastProbabilities = probs;
        _topLabel = (maxIndex < emotionLabels.length) ? emotionLabels[maxIndex] : 'Class $maxIndex';
        _topConfidence = maxVal;
        _status = 'Inference complete';
      });
    } catch (e) {
      debugPrint('TFLite inference error: $e');
      setState(() {
        _status = 'Inference error: $e';
      });
    }
  }

  // Helper: take most recent N samples from the queue without destroying them
  List<double> _takeRecentSamples(int n) {
    final int start = _ringBuffer.length - n;
    final List<double> out = List<double>.filled(n, 0.0);
    int idx = 0;
    for (int i = start; i < _ringBuffer.length; i++) {
      out[idx++] = _ringBuffer.elementAt(i);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Speech Emotion Recognition'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Status: $_status'),
                    const SizedBox(height: 8),
                    Text('Listening: $_isListening'),
                    const SizedBox(height: 8),
                    Text('Buffer samples: ${_ringBuffer.length} / $requiredSamples'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _isListening ? _stopListening : _startListening,
                child: Text(_isListening ? 'Stop Listening' : 'Start Listening')),
            const SizedBox(height: 20),
            if (_topLabel.isNotEmpty)
              Card(
                color: Colors.deepPurple[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 36, color: Colors.deepPurple),
                      const SizedBox(height: 8),
                      Text(
                        _topLabel.toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Text('${(_topConfidence * 100).toStringAsFixed(1)}% confidence'),
                      const SizedBox(height: 12),
                      _buildProbabilitiesWidget(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilitiesWidget() {
    if (_lastProbabilities.isEmpty) return const SizedBox();
    // show top 6 probabilities
    final List<int> idx = List<int>.generate(_lastProbabilities.length, (i) => i);
    idx.sort((a, b) => _lastProbabilities[b].compareTo(_lastProbabilities[a]));
    final topIdx = idx.take(6).toList();
    return Column(
      children: topIdx.map((i) {
        final label = (i < emotionLabels.length) ? emotionLabels[i] : 'Class $i';
        final prob = _lastProbabilities[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(prob * 100).toStringAsFixed(1)}%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// --------------------------- MFCC Implementation ---------------------------

// Convert Float to double extension
extension ToFloat on double {
  double toFloat() => this; // we rely on Float32List later
}

// Compute MFCCs: returns List of length nMfcc, each inner list length = frames
List<List<double>> computeMFCC(Float32List samples, int sr, int nFft, int hop, int nMfcc) {
  // Steps:
  // 1. Pre-emphasis
  // 2. Framing & Windowing (Hamming)
  // 3. FFT -> Power spectrum
  // 4. Mel filterbank -> energies
  // 5. log -> DCT -> keep first nMfcc coefficients per frame

  // 1. Pre-emphasis (simple)
  final List<double> emphasized = List<double>.filled(samples.length, 0.0);
  for (int i = 0; i < samples.length; i++) {
    emphasized[i] = (i == 0) ? samples[0].toDouble() : (samples[i].toDouble() - 0.97 * samples[i - 1].toDouble());
  }

  // 2. Framing
  final int frameStep = hop;
  final int frameLen = nFft;
  final int numFrames = ((emphasized.length - frameLen) / frameStep).floor() + 1;
  if (numFrames <= 0) {
    // return zeros
    return List.generate(nMfcc, (_) => List.filled(1, 0.0));
  }

  // Prepare Hamming window
  final List<double> hamming = List<double>.generate(frameLen, (i) {
    return 0.54 - 0.46 * cos(2 * pi * i / (frameLen - 1));
  });

  // FFT buffer size is nFft (already power of two)
  // Precompute mel filterbank for nFft/2+1 bins
  final int nFftBins = nFft ~/ 2 + 1;
  final List<List<double>> melFilter = melFilterbank(nMfcc, nFft, sr);

  // For each frame, compute power spectrum and then apply filterbank
  final List<List<double>> mfccsPerFrame = [];

  for (int f = 0; f < numFrames; f++) {
    final int start = f * frameStep;
    final Float64List frame = Float64List(frameLen);
    for (int i = 0; i < frameLen; i++) {
      frame[i] = emphasized[start + i] * hamming[i];
    }

    // compute FFT -> power spectrum (real FFT)
    final List<Complex> spectrum = fft(frame.map((e) => e.toDouble()).toList());
    // take only first nFftBins
    final List<double> powerSpec = List<double>.filled(nFftBins, 0.0);
    for (int k = 0; k < nFftBins; k++) {
      final Complex c = spectrum[k];
      final double mag = c.real * c.real + c.imag * c.imag;
      powerSpec[k] = mag / nFft; // normalized power
    }

    // Apply mel filterbank
    final List<double> melEnergies = List<double>.filled(melFilter.length, 0.0);
    for (int m = 0; m < melFilter.length; m++) {
      double sum = 0.0;
      final List<double> filt = melFilter[m];
      for (int k = 0; k < nFftBins; k++) {
        sum += filt[k] * powerSpec[k];
      }
      // avoid log(0)
      melEnergies[m] = (sum > 1e-10) ? log(sum) : -10.0;
    }

    // DCT type-II on melEnergies to get MFCCs
    final List<double> mfccFrame = dct(melEnergies, nMfcc);
    mfccsPerFrame.add(mfccFrame);
  }

  // Result needs to be [nMfcc][frames]
  final int frames = mfccsPerFrame.length;
  final List<List<double>> result = List.generate(nMfcc, (_) => List.filled(frames, 0.0));
  for (int t = 0; t < frames; t++) {
    final List<double> frm = mfccsPerFrame[t];
    for (int m = 0; m < nMfcc; m++) {
      result[m][t] = frm[m];
    }
  }

  return result;
}

// Pad/truncate MFCC to targetFrames along the second dimension (frames)
List<List<double>> padOrTruncateMFCC(List<List<double>> mfcc, int targetFrames) {
  final int coff = mfcc.length;
  final int frames = mfcc.isNotEmpty ? mfcc[0].length : 0;
  // Initialize output
  final List<List<double>> out = List.generate(coff, (_) => List.filled(targetFrames, 0.0));
  for (int i = 0; i < coff; i++) {
    final List<double> row = mfcc[i];
    if (frames >= targetFrames) {
      // take last targetFrames (similar to librosa pad/trunc from left)
      final int start = frames - targetFrames;
      for (int j = 0; j < targetFrames; j++) {
        out[i][j] = row[start + j];
      }
    } else {
      // pad left with zeros, keep original at end
      final int pad = targetFrames - frames;
      for (int j = 0; j < frames; j++) {
        out[i][pad + j] = row[j];
      }
      // pre-padding left remains 0.0
    }
  }
  return out;
}

// --------------------------- DSP helpers ---------------------------

// Complex number simple class
class Complex {
  double real;
  double imag;
  Complex(this.real, this.imag);
}

// Cooley-Tukey radix-2 FFT; returns List<Complex> length n (n must be power of two)
List<Complex> fft(List<double> realInput) {
  int n = realInput.length;
  // If n != power-of-two, pad to next power of two (we expect nFft is a power-of-two)
  int size = 1;
  while (size < n) size <<= 1;
  if (size != n) {
    realInput = List<double>.from(realInput)..addAll(List<double>.filled(size - n, 0.0));
    n = size;
  }

  List<Complex> buffer = List.generate(n, (i) => Complex(realInput[i], 0.0));

  // bit-reverse permutation
  int j = 0;
  for (int i = 1; i < n; i++) {
    int bit = n >> 1;
    while (j & bit != 0) {
      j ^= bit;
      bit >>= 1;
    }
    j ^= bit;
    if (i < j) {
      final tmp = buffer[i];
      buffer[i] = buffer[j];
      buffer[j] = tmp;
    }
  }

  // FFT
  for (int len = 2; len <= n; len <<= 1) {
    final double ang = -2 * pi / len;
    final Complex wlen = Complex(cos(ang), sin(ang));
    for (int i = 0; i < n; i += len) {
      Complex w = Complex(1.0, 0.0);
      for (int k = 0; k < len / 2; k++) {
        final Complex u = buffer[i + k];
        final Complex v = multiplyComplex(buffer[i + k + len ~/ 2], w);
        buffer[i + k] = Complex(u.real + v.real, u.imag + v.imag);
        buffer[i + k + len ~/ 2] = Complex(u.real - v.real, u.imag - v.imag);
        w = multiplyComplex(w, wlen);
      }
    }
  }

  return buffer;
}

Complex multiplyComplex(Complex a, Complex b) {
  return Complex(a.real * b.real - a.imag * b.imag, a.real * b.imag + a.imag * b.real);
}

// Build mel filterbank similar to librosa's implementation
List<List<double>> melFilterbank(int nMels, int nFft, int sr) {
  final int nFftBins = nFft ~/ 2 + 1;
  final double lowFreq = 0.0;
  final double highFreq = sr / 2.0;

  // Convert Hz to Mel and vice versa (HTK formula)
  double hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
  double melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

  final double lowMel = hzToMel(lowFreq);
  final double highMel = hzToMel(highFreq);
  final List<double> mels = List<double>.generate(nMels + 2,
      (i) => lowMel + (highMel - lowMel) * i / (nMels + 1));
  final List<double> hz = mels.map((m) => melToHz(m)).toList();

  final List<int> bins = hz.map((h) => ((nFft + 1) * h / sr).floor()).toList();

  final List<List<double>> filterbank = List.generate(nMels, (_) => List.filled(nFftBins, 0.0));
  for (int m = 1; m <= nMels; m++) {
    final int f_m_minus = bins[m - 1];
    final int f_m = bins[m];
    final int f_m_plus = bins[m + 1];

    for (int k = f_m_minus; k < f_m; k++) {
      if (k >= 0 && k < nFftBins) {
        filterbank[m - 1][k] = (k - f_m_minus) / max(1, (f_m - f_m_minus)).toDouble();
      }
    }
    for (int k = f_m; k < f_m_plus; k++) {
      if (k >= 0 && k < nFftBins) {
        filterbank[m - 1][k] = (f_m_plus - k) / max(1, (f_m_plus - f_m)).toDouble();
      }
    }
  }

  return filterbank;
}

// DCT-II compute first 'count' coefficients from 'x'
List<double> dct(List<double> x, int count) {
  final int n = x.length;
  final List<double> result = List.filled(count, 0.0);
  for (int k = 0; k < count; k++) {
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      sum += x[i] * cos(pi * k * (2 * i + 1) / (2 * n));
    }
    result[k] = sum;
  }
  return result;
}
