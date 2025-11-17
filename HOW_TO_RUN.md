# 🚀 How to Run TravelSafe Project

This guide will help you run both the backend (Python/FastAPI) and Flutter app.

---

## 📋 Prerequisites

- ✅ Python 3.12.0 (you have this)
- ✅ Flutter 3.24.4 (you have this)
- ✅ Virtual environment activated

---

## 🔧 Step 1: Setup Backend (Python/FastAPI)

### 1.1 Navigate to backend folder
```bash
cd backend
```

### 1.2 Activate virtual environment
**On Windows (PowerShell):**
```powershell
venv\Scripts\Activate.ps1
```

**On Windows (Command Prompt):**
```cmd
venv\Scripts\activate.bat
```

You should see `(venv)` at the start of your command prompt.

### 1.3 Install dependencies (if not already installed)
```bash
pip install -r requirements.txt
```

### 1.4 Create .env file (if not exists)
Create a file named `.env` in the `backend` folder with:
```
GROQ_API_KEY=your_groq_api_key_here
WEATHER_API_KEY=
CRIME_DATA_API_KEY=
```

**Note:** Replace `your_groq_api_key_here` with your actual Groq API key.

### 1.5 Run the backend server
```bash
python main.py
```

You should see:
```
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**✅ Backend is now running!**

### 1.6 Test the backend
Open your browser and visit:
- http://localhost:8000 - Main page
- http://localhost:8000/docs - API Documentation (Swagger UI)
- http://localhost:8000/api/test - Test endpoint

**Keep this terminal window open!** The backend must stay running.

---

## 📱 Step 2: Setup Flutter App

### 2.1 Open a NEW terminal window
**Important:** Keep the backend running in the first terminal, open a new one!

### 2.2 Navigate to mobile folder
```bash
cd mobile
```

### 2.3 Install Flutter dependencies
```bash
flutter pub get
```

This downloads all required packages (like `http` for API calls).

### 2.4 Check available devices
```bash
flutter devices
```

You should see something like:
- Chrome (web)
- Windows (desktop)
- Or your connected phone/emulator

### 2.5 Run the Flutter app

**Option A: Run on Chrome (Web) - Easiest for beginners**
```bash
flutter run -d chrome
```

**Option B: Run on Windows Desktop**
```bash
flutter run -d windows
```

**Option C: Run on Android Emulator** (if you have Android Studio setup)
```bash
flutter run
```

**Option D: Run on your phone** (if connected via USB)
```bash
flutter run
```

---

## 🔗 Step 3: Connect Flutter to Backend

### Important: URL Configuration

The Flutter app needs to know where your backend is running.

**For Web/Desktop (Chrome, Windows):**
- Use: `http://localhost:8000` ✅ (already set)

**For Android Emulator:**
- Change to: `http://10.0.2.2:8000`
- Edit `mobile/lib/main.dart`, line 30:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000';
  ```

**For Real Android/iOS Device:**
- Find your computer's IP address:
  - Windows: Open Command Prompt, type `ipconfig`
  - Look for "IPv4 Address" (e.g., 192.168.1.100)
- Change to: `http://YOUR_IP:8000`
- Edit `mobile/lib/main.dart`, line 30:
  ```dart
  static const String baseUrl = 'http://192.168.1.100:8000';  // Your IP
  ```

---

## 🧪 Step 4: Test the Connection

1. **Backend is running** (Terminal 1) ✅
2. **Flutter app is running** (Terminal 2) ✅
3. **In the Flutter app**, click the **"Test Backend Connection"** button
4. You should see: **"✅ Connected! Backend is working!"**

---

## 🐛 Troubleshooting

### Backend won't start?
- Make sure virtual environment is activated (see `(venv)` in prompt)
- Check if port 8000 is already in use
- Try: `python main.py` again

### Flutter can't connect to backend?
- **For Web/Desktop:** Make sure backend is running on `localhost:8000`
- **For Emulator:** Change URL to `http://10.0.2.2:8000`
- **For Real Device:** Use your computer's IP address
- Check Windows Firewall isn't blocking port 8000

### Flutter dependencies error?
```bash
cd mobile
flutter clean
flutter pub get
```

### "flutter: command not found"?
- Make sure Flutter is in your PATH
- Restart your terminal
- Check: `flutter --version`

---

## 📝 Quick Reference

**Terminal 1 (Backend):**
```bash
cd backend
venv\Scripts\activate
python main.py
```

**Terminal 2 (Flutter):**
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

---

## 🎉 Success!

If you see "✅ Connected!" in the Flutter app, everything is working!

Now you can start building features:
- Image analysis
- Weather data
- Crime data
- Safety scoring

---

## 💡 Tips

1. **Hot Reload in Flutter:** Press `r` in the Flutter terminal to reload changes
2. **Hot Restart:** Press `R` (capital) to fully restart
3. **Stop App:** Press `q` to quit
4. **Backend Auto-reload:** Install `watchdog` for auto-reload (optional)

---

**Need help?** Check the error messages - they usually tell you what's wrong!

