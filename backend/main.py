"""
TravelSafe - AI Safety Assistant Backend
FastAPI application for safety analysis
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

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

# TODO: Add endpoints for:
# - Image analysis
# - Weather data
# - Crime data
# - Safety score calculation
# - Alerts

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

