"""
TravelSafe - AI Safety Assistant Backend
FastAPI application for safety analysis
"""

from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional
import os

# Import services
from services.image_analysis import analyze_image_safety
from services.weather_service import get_weather_data
from services.crime_service import get_crime_data
from services.safety_scorer import calculate_safety_score
from services.incident_service import report_incident, get_incidents_near_location
from services.auth_service import signup_user, login_user, get_user_by_token, verify_token

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="TravelSafe API",
    description="AI Safety Assistant for rating street and neighborhood safety",
    version="1.0.0"
)

# Configure CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific Flutter app origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory if it doesn't exist
os.makedirs("uploads", exist_ok=True)

# Request models
class LocationRequest(BaseModel):
    latitude: float
    longitude: float

class SafetyAnalysisRequest(BaseModel):
    latitude: float
    longitude: float
    image_url: Optional[str] = None

class SignupRequest(BaseModel):
    phone_number: str
    full_name: str
    password: str

class LoginRequest(BaseModel):
    phone_number: str
    password: str

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "TravelSafe API is running",
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}

@app.get("/api/test")
async def test():
    """Simple test endpoint to verify connection"""
    return {
        "message": "Backend is working!",
        "data": "This is a test response from the TravelSafe API"
    }

@app.post("/api/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """
    Upload and analyze an image for safety indicators
    """
    try:
        # Read image file
        contents = await file.read()
        
        # Analyze image
        analysis = analyze_image_safety(contents)
        
        return {
            "success": True,
            "analysis": analysis
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/weather")
async def get_weather(location: LocationRequest):
    """
    Get weather data for a location
    """
    try:
        weather_data = get_weather_data(
            location.latitude,
            location.longitude
        )
        return {
            "success": True,
            "weather": weather_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/crime-data")
async def get_crime(location: LocationRequest):
    """
    Get crime data for a location
    """
    try:
        crime_data = get_crime_data(
            location.latitude,
            location.longitude
        )
        return {
            "success": True,
            "crime_data": crime_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/safety-analysis")
async def complete_safety_analysis(
    latitude: float = Form(...),
    longitude: float = Form(...),
    file: Optional[UploadFile] = File(None)
):
    """
    Complete safety analysis combining:
    - Image analysis (if image provided)
    - Weather data
    - Crime data
    
    Returns safety score (1-100) and alert status
    
    Accepts multipart/form-data with:
    - latitude: float (required)
    - longitude: float (required)
    - file: image file (optional)
    """
    try:
        # Get weather data
        weather_data = get_weather_data(latitude, longitude)
        
        # Get crime data (within 1km radius for drivers)
        crime_data = get_crime_data(latitude, longitude, radius_km=1.0)
        
        # Analyze image if provided
        image_analysis = {"indicators": {}}
        if file:
            contents = await file.read()
            print(f"📸 Analyzing image: {len(contents)} bytes")
            image_analysis = analyze_image_safety(contents)
            print(f"📸 Image analysis result: {image_analysis.get('error', 'Success')}")
            if image_analysis.get('error'):
                print(f"❌ Image analysis error: {image_analysis.get('error')}")
            else:
                print(f"✅ Image analysis indicators: {image_analysis.get('indicators', {})}")
        
        # Calculate safety score
        safety_result = calculate_safety_score(
            image_analysis,
            weather_data,
            crime_data
        )
        
        return {
            "success": True,
            "location": {
                "latitude": latitude,
                "longitude": longitude
            },
            "safety_score": safety_result["safety_score"],
            "safety_level": safety_result["safety_level"],
            "alert": safety_result["alert"],
            "breakdown": safety_result["breakdown"],
            "factors": {
                "weather": weather_data,
                "crime": crime_data,
                "image_analysis": image_analysis if file else None
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/report-incident")
async def report_incident_endpoint(
    latitude: float = Form(...),
    longitude: float = Form(...),
    incident_type: str = Form(...),
    description: str = Form("")
):
    """
    Report a crime/incident at a location
    
    Accepts:
    - latitude: float (required)
    - longitude: float (required)
    - incident_type: string (required) - e.g., "theft", "assault", "vandalism", "suspicious_activity"
    - description: string (optional)
    """
    try:
        result = report_incident(latitude, longitude, incident_type, description)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/incidents-nearby")
async def get_nearby_incidents(location: LocationRequest):
    """
    Get incidents near a location
    """
    try:
        incidents = get_incidents_near_location(
            location.latitude,
            location.longitude,
            radius_km=1.0
        )
        return {
            "success": True,
            "incidents": incidents,
            "count": len(incidents)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/auth/signup")
async def signup_endpoint(request: SignupRequest):
    """
    User signup endpoint
    Requires: phone_number, full_name, password
    """
    try:
        result = signup_user(
            phone_number=request.phone_number,
            full_name=request.full_name,
            password=request.password
        )
        
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result.get("error", "Signup failed"))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/auth/login")
async def login_endpoint(request: LoginRequest):
    """
    User login endpoint
    Requires: phone_number, password
    Returns: access_token and user info
    """
    try:
        result = login_user(
            phone_number=request.phone_number,
            password=request.password
        )
        
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=401, detail=result.get("error", "Login failed"))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/auth/me")
async def get_current_user(authorization: Optional[str] = Header(None, alias="Authorization")):
    """
    Get current user information from JWT token
    Requires: Authorization header with Bearer token
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    try:
        # Extract token from "Bearer <token>"
        token = authorization.replace("Bearer ", "").strip()
        user = get_user_by_token(token)
        
        if user:
            return {
                "success": True,
                "user": user
            }
        else:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
