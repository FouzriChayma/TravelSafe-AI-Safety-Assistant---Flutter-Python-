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
│   └── .env         # Environment variables
└── mobile/          # Flutter app (to be created)
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

4. Configure `.env` file with API keys

5. Run the server:
   ```bash
   python main.py
   ```

### Flutter Setup

(To be added when Flutter app is created)

## Difficulty: ⭐⭐⭐⭐

