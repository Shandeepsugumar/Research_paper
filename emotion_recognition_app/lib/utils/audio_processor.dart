import 'dart:math';
import 'dart:typed_data';

class AudioProcessor {
  static const int sampleRate = 22050;
  static const int nMfcc = 40;
  static const int nFft = 512;
  static const int hopLength = 256;
  static const int targetFrames = 174;

  static int get requiredSamples => hopLength * (targetFrames - 1) + nFft;

  static List<List<double>> computeMFCC(
    Float32List samples,
    int sr,
    int nFft,
    int hop,
    int nMfcc,
  ) {
    final emphasized = _preEmphasis(samples);
    final frames = _frameSignal(emphasized, nFft, hop);
    final melFilter = _melFilterbank(nMfcc, nFft, sr);
    final mfccsPerFrame = <List<double>>[];

    for (final frame in frames) {
      final windowed = _applyHammingWindow(frame);
      final spectrum = _fft(windowed);
      final powerSpec = _computePowerSpectrum(spectrum, nFft);
      final melEnergies = _applyMelFilterbank(powerSpec, melFilter);
      final logMel = melEnergies.map((e) => e > 1e-10 ? log(e) : -10.0).toList();
      final mfccFrame = _dct(logMel, nMfcc);
      mfccsPerFrame.add(mfccFrame);
    }

    return _transposeFrames(mfccsPerFrame, nMfcc);
  }

  static List<double> _preEmphasis(Float32List samples, [double alpha = 0.97]) {
    final result = List<double>.filled(samples.length, 0.0);
    result[0] = samples[0].toDouble();
    for (int i = 1; i < samples.length; i++) {
      result[i] = samples[i] - alpha * samples[i - 1];
    }
    return result;
  }

  static List<List<double>> _frameSignal(List<double> signal, int frameLen, int frameStep) {
    final numFrames = ((signal.length - frameLen) / frameStep).floor() + 1;
    if (numFrames <= 0) return [List.filled(frameLen, 0.0)];

    final frames = <List<double>>[];
    for (int i = 0; i < numFrames; i++) {
      final start = i * frameStep;
      final end = start + frameLen;
      if (end <= signal.length) {
        frames.add(signal.sublist(start, end));
      }
    }
    return frames;
  }

  static List<double> _applyHammingWindow(List<double> frame) {
    final n = frame.length;
    return List.generate(n, (i) {
      final window = 0.54 - 0.46 * cos(2 * pi * i / (n - 1));
      return frame[i] * window;
    });
  }

  static List<_Complex> _fft(List<double> realInput) {
    int n = realInput.length;
    int size = 1;
    while (size < n) size <<= 1;

    final padded = List<double>.from(realInput);
    if (size != n) {
      padded.addAll(List.filled(size - n, 0.0));
      n = size;
    }

    final buffer = List.generate(n, (i) => _Complex(padded[i], 0.0));

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

    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * pi / len;
      final wlen = _Complex(cos(ang), sin(ang));
      for (int i = 0; i < n; i += len) {
        var w = _Complex(1.0, 0.0);
        for (int k = 0; k < len ~/ 2; k++) {
          final u = buffer[i + k];
          final v = buffer[i + k + len ~/ 2] * w;
          buffer[i + k] = u + v;
          buffer[i + k + len ~/ 2] = u - v;
          w = w * wlen;
        }
      }
    }

    return buffer;
  }

  static List<double> _computePowerSpectrum(List<_Complex> spectrum, int nFft) {
    final nFftBins = nFft ~/ 2 + 1;
    return List.generate(nFftBins, (k) {
      final c = spectrum[k];
      return (c.real * c.real + c.imag * c.imag) / nFft;
    });
  }

  static List<List<double>> _melFilterbank(int nMels, int nFft, int sr) {
    final nFftBins = nFft ~/ 2 + 1;
    final lowFreq = 0.0;
    final highFreq = sr / 2.0;

    double hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
    double melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

    final lowMel = hzToMel(lowFreq);
    final highMel = hzToMel(highFreq);
    final mels = List.generate(
      nMels + 2,
      (i) => lowMel + (highMel - lowMel) * i / (nMels + 1),
    );
    final hz = mels.map(melToHz).toList();
    final bins = hz.map((h) => ((nFft + 1) * h / sr).floor()).toList();

    final filterbank = List.generate(nMels, (_) => List.filled(nFftBins, 0.0));

    for (int m = 1; m <= nMels; m++) {
      final fMinus = bins[m - 1];
      final fM = bins[m];
      final fPlus = bins[m + 1];

      for (int k = fMinus; k < fM; k++) {
        if (k >= 0 && k < nFftBins && fM > fMinus) {
          filterbank[m - 1][k] = (k - fMinus) / (fM - fMinus);
        }
      }
      for (int k = fM; k < fPlus; k++) {
        if (k >= 0 && k < nFftBins && fPlus > fM) {
          filterbank[m - 1][k] = (fPlus - k) / (fPlus - fM);
        }
      }
    }

    return filterbank;
  }

  static List<double> _applyMelFilterbank(
    List<double> powerSpec,
    List<List<double>> filterbank,
  ) {
    return List.generate(filterbank.length, (m) {
      double sum = 0.0;
      for (int k = 0; k < powerSpec.length; k++) {
        sum += filterbank[m][k] * powerSpec[k];
      }
      return sum;
    });
  }

  static List<double> _dct(List<double> x, int count) {
    final n = x.length;
    return List.generate(count, (k) {
      double sum = 0.0;
      for (int i = 0; i < n; i++) {
        sum += x[i] * cos(pi * k * (2 * i + 1) / (2 * n));
      }
      return sum;
    });
  }

  static List<List<double>> _transposeFrames(List<List<double>> framesData, int nMfcc) {
    final frames = framesData.length;
    final result = List.generate(nMfcc, (_) => List.filled(frames, 0.0));
    for (int t = 0; t < frames; t++) {
      for (int m = 0; m < nMfcc; m++) {
        result[m][t] = framesData[t][m];
      }
    }
    return result;
  }

  static List<List<double>> padOrTruncateMFCC(List<List<double>> mfcc, int targetFrames) {
    final nCoeff = mfcc.length;
    final frames = mfcc.isNotEmpty ? mfcc[0].length : 0;
    final result = List.generate(nCoeff, (_) => List.filled(targetFrames, 0.0));

    for (int i = 0; i < nCoeff; i++) {
      if (frames >= targetFrames) {
        final start = frames - targetFrames;
        for (int j = 0; j < targetFrames; j++) {
          result[i][j] = mfcc[i][start + j];
        }
      } else {
        final pad = targetFrames - frames;
        for (int j = 0; j < frames; j++) {
          result[i][pad + j] = mfcc[i][j];
        }
      }
    }

    return result;
  }
}

class _Complex {
  final double real;
  final double imag;

  _Complex(this.real, this.imag);

  _Complex operator +(_Complex other) => _Complex(real + other.real, imag + other.imag);
  _Complex operator -(other) => _Complex(real - other.real, imag - other.imag);
  _Complex operator *(_Complex other) => _Complex(
        real * other.real - imag * other.imag,
        real * other.imag + imag * other.real,
      );
}
