# ⚡ Quick Start Guide

## 🎯 Goal: Get Backend + Flutter Running in 5 Minutes

---

## Step 1: Start Backend (Terminal 1)

```bash
cd backend
venv\Scripts\activate
python main.py
```

**✅ Success when you see:** `Uvicorn running on http://0.0.0.0:8000`

**Test it:** Open http://localhost:8000 in your browser

---

## Step 2: Start Flutter App (Terminal 2 - NEW WINDOW!)

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

**✅ Success when you see:** Chrome opens with the TravelSafe app

---

## Step 3: Test Connection

1. In the Flutter app, click **"Test Backend Connection"** button
2. You should see: **"✅ Connected! Backend is working!"**

---

## 🎉 Done!

If you see the success message, everything is working!

---

## 📖 Need More Details?

See **[HOW_TO_RUN.md](HOW_TO_RUN.md)** for:
- Troubleshooting
- Different device configurations
- Advanced setup

---

## 🐛 Common Issues

**"Connection failed"**
- Make sure backend is running (Step 1)
- Check the URL in `mobile/lib/main.dart` (line 30)

**"flutter: command not found"**
- Restart terminal
- Check Flutter is in PATH: `flutter --version`

**Backend won't start**
- Activate venv: `venv\Scripts\activate`
- Check Python: `python --version`

