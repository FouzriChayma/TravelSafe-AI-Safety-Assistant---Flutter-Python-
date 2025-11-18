"""
Weather Service - Get weather data for safety analysis
Uses OpenWeatherMap API (free tier available)
"""
import os
import requests
from typing import Optional

def get_weather_data(latitude: float, longitude: float) -> dict:
    """
    Get weather data for a location
    
    Args:
        latitude: Location latitude
        longitude: Location longitude
    
    Returns:
        dict: Weather data with safety-relevant information
    """
    api_key = os.getenv("WEATHER_API_KEY")
    
    if not api_key:
        # Return mock data if API key not available
        return {
            "temperature": 20,
            "condition": "clear",
            "visibility": 10,
            "wind_speed": 5,
            "safety_impact": "neutral"
        }
    
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": latitude,
            "lon": longitude,
            "appid": api_key,
            "units": "metric"
        }
        
        response = requests.get(url, params=params, timeout=5)
        response.raise_for_status()
        data = response.json()
        
        # Extract relevant safety information
        weather_condition = data.get("weather", [{}])[0].get("main", "clear").lower()
        visibility = data.get("visibility", 10000) / 1000  # Convert to km
        wind_speed = data.get("wind", {}).get("speed", 0)
        temperature = data.get("main", {}).get("temp", 20)
        
        # Determine safety impact
        safety_impact = "neutral"
        if weather_condition in ["rain", "storm", "snow", "fog"]:
            safety_impact = "negative"
        elif visibility < 1:
            safety_impact = "negative"
        elif wind_speed > 15:
            safety_impact = "negative"
        
        return {
            "temperature": round(temperature, 1),
            "condition": weather_condition,
            "visibility": round(visibility, 1),
            "wind_speed": round(wind_speed, 1),
            "safety_impact": safety_impact,
            "description": data.get("weather", [{}])[0].get("description", ""),
            "humidity": data.get("main", {}).get("humidity", 0),
            "city": data.get("name", ""),
            "country": data.get("sys", {}).get("country", ""),
            "data_source": "openweathermap_api"
        }
        
    except requests.exceptions.RequestException as e:
        # Network/API error
        return {
            "temperature": 20,
            "condition": "clear",
            "visibility": 10,
            "wind_speed": 5,
            "safety_impact": "neutral",
            "error": f"Weather API error: {str(e)}",
            "data_source": "fallback"
        }
    except Exception as e:
        # Other errors
        return {
            "temperature": 20,
            "condition": "clear",
            "visibility": 10,
            "wind_speed": 5,
            "safety_impact": "neutral",
            "error": str(e),
            "data_source": "fallback"
        }

