# Quick Start Guide

## ⚡ 5-Minute Setup

### Step 1: Prerequisites (1 min)
```bash
# Verify Flutter is installed
flutter --version

# Should show Flutter 3.0.0 or higher
```

### Step 2: Copy Your Models (2 min)
```bash
cd emotion_recognition_app

# CRITICAL: Replace placeholder models with your actual trained models
cp /path/to/your/ser_cpu_rnn_model.tflite assets/models/
cp /path/to/your/HER_emotion_model_custom.tflite assets/models/
cp /path/to/your/fusion_model.tflite assets/models/

# Verify models are copied (should NOT be 20 bytes)
ls -lh assets/models/
```

### Step 3: Install Dependencies (1 min)
```bash
flutter pub get
```

### Step 4: Run the App (1 min)
```bash
# Connect Android device or start emulator
flutter devices

# Run the app
flutter run
```

## 🎯 Testing Each Feature

### Test 1: Speech Emotion Recognition (30 seconds)
1. Open app → Tap "Speech Emotion Recognition"
2. Tap microphone → Grant permission
3. Speak for 3-5 seconds → Tap stop
4. ✅ View emotion prediction

### Test 2: Heart Rate Recognition (1 minute)
1. **Before testing**: Open Google Fit app, ensure it has heart rate data
2. Open app → Tap "Heart Rate Emotion Recognition"
3. Tap "Fetch from Google Fit" → Grant permissions
4. ✅ View valence prediction

### Test 3: Fusion Analysis (1 minute)
1. Open app → Tap "Multimodal Fusion Analysis"
2. Step 1: Fetch heart rate → Grant permissions
3. Step 2: Record voice → Speak clearly
4. ✅ View combined prediction

## 🚨 Common Issues & Quick Fixes

### Issue: "Model not found"
```bash
# Fix: Verify models are in correct location
ls assets/models/

# Should show 3 .tflite files with substantial sizes
# If files are 20 bytes, replace with actual trained models
```

### Issue: "No heart rate data"
**Fix**:
1. Install Google Fit app from Play Store
2. Open Google Fit → Grant all permissions
3. Add heart rate data (manual entry or sync from wearable)
4. Wait 1-2 minutes for sync
5. Try fetching again

### Issue: Microphone permission denied
**Fix**:
- Go to device Settings → Apps → Emotion Recognition
- Grant Microphone permission
- Restart app

### Issue: Build fails
```bash
# Nuclear option - clean everything
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
flutter run
```

## 📱 App Navigation

```
Home Screen
├── Speech Emotion Recognition
│   └── Record → Analyze → Result
├── Heart Rate Emotion Recognition
│   └── Fetch Data → Analyze → Result
└── Multimodal Fusion Analysis
    └── Step 1 (HR) → Step 2 (Voice) → Result
```

## 🎨 Expected Output

### Speech Recognition Result
```
Detected Emotion: HAPPY
Confidence: 87.3%

Top 5 Predictions:
Happy: 87.3%
Calm: 6.2%
Neutral: 3.1%
...
```

### Heart Rate Result
```
Emotional Valence: HIGH VALENCE
Confidence: 78.5%

Heart Rate Statistics:
Average: 72.3 bpm
Min: 68 bpm
Max: 85 bpm
```

### Fusion Result
```
Fused Emotion Prediction: HAPPY
Confidence: 92.1%

All Predictions:
Happy: 92.1%
Calm: 4.3%
Neutral: 2.1%
...
```

## 📊 Model Requirements

| Model | Input Shape | Output Shape | Size (Approx) |
|-------|-------------|--------------|---------------|
| SER | [1, 40, 174] | [1, 26] | ~500 KB |
| HER | [1, 5000] | [1, 2] | ~300 KB |
| Fusion | [1, 40] + [1, 100, 1] | [1, 8] | ~800 KB |

## 🔑 Google Fit Setup (If Using Different Credentials)

1. **Google Cloud Console**
   - Enable Fitness API
   - Create OAuth 2.0 Client ID (Android)

2. **Get SHA-1**
   ```bash
   cd android
   ./gradlew signingReport
   # Copy SHA1 from debug variant
   ```

3. **Update Client ID**
   - Edit `android/app/src/main/res/values/strings.xml`
   - Replace `google_fitness_api_key` value

## 🎯 Next Steps

After successful setup:

1. **Test with different emotions** - Try angry, sad, happy voices
2. **Check accuracy** - Compare predictions with actual emotions
3. **Test in different environments** - Quiet vs noisy
4. **Review code** - Understand the implementation
5. **Customize** - Modify UI, add features

## 📚 Documentation

- **Full Setup**: See `SETUP_INSTRUCTIONS.md`
- **Technical Details**: See `PROJECT_OVERVIEW.md`
- **User Guide**: See `README.md`

## ⚠️ Important Notes

1. **Model Files**: MUST replace placeholder files with actual trained models
2. **Google Fit**: Requires Google Fit app with synced data
3. **Permissions**: Grant ALL requested permissions
4. **Audio Quality**: Record in quiet environment for best results
5. **Heart Rate**: Need continuous data from wearable device

## 🆘 Getting Help

If you're stuck:
1. ✅ Verified Flutter installed?
2. ✅ Models copied to assets/models/?
3. ✅ Dependencies installed (flutter pub get)?
4. ✅ Device connected (flutter devices)?
5. ✅ Permissions granted?

Still not working? Check detailed `SETUP_INSTRUCTIONS.md`

---

**Ready to recognize emotions!** 🎉

Run: `flutter run` and start testing!
