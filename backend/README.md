# TravelSafe Backend

AI Safety Assistant Backend API built with FastAPI.

## Features

- Image analysis from camera
- Weather data integration
- Public crime dataset analysis
- Safety score calculation (1-100)
- Alert system for unsafe zones

## Setup

1. Activate virtual environment:
   ```bash
   venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure environment variables in `.env` file

4. Run the server:
   ```bash
   python main.py
   ```

   Or using uvicorn directly:
   ```bash
   uvicorn main:app --reload
   ```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Tech Stack

- FastAPI
- Python/Scikit-learn
- OpenCV for image processing
- Pandas for data analysis
- Geopy for location services

