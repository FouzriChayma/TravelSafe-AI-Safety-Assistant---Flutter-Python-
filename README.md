# TravelSafe – AI Safety Assistant

A Flutter app with Python AI backend that rates the safety of streets and neighborhoods.

## Features

- 📸 Image analysis from camera
- 🌤️ Weather data integration
- 📊 Public crime dataset analysis
- 🎯 Safety score (1–100)
- 🚨 Alert system for unsafe zones

## Tech Stack

### Backend
- FastAPI
- Python/Scikit-learn
- OpenCV for image processing
- Pandas for data analysis
- Geopy for location services

### Frontend
- Flutter
- Maps integration
- Real-time API communication

## Project Structure

```
TravelSafe/
├── backend/          # Python FastAPI backend
│   ├── venv/        # Virtual environment
│   ├── main.py      # FastAPI application
│   ├── requirements.txt
│   └── .env         # Environment variables (create manually)
└── mobile/          # Flutter mobile app
    ├── lib/         # Dart source code
    │   └── main.dart
    ├── android/     # Android platform files
    ├── ios/         # iOS platform files
    ├── web/         # Web platform files
    └── pubspec.yaml # Flutter dependencies
```

## Setup Instructions

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Activate virtual environment:
   ```bash
   venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure `.env` file with API keys:
   ```
   GROQ_API_KEY=your_groq_api_key_here
   WEATHER_API_KEY=your_weather_api_key_here
   CRIME_DATA_API_KEY=your_crime_data_api_key_here
   ```

5. Run the server:
   ```bash
   python main.py
   ```
   
   Or using uvicorn directly:
   ```bash
   uvicorn main:app --reload
   ```

6. Access API documentation:
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Flutter Setup

1. Navigate to mobile directory:
   ```bash
   cd mobile
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

   Or run on a specific device:
   ```bash
   flutter devices  # List available devices
   flutter run -d <device-id>
   ```

## Difficulty: ⭐⭐⭐⭐
