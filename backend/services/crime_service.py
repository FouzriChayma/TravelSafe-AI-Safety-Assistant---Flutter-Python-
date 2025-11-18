"""
Crime Data Service - Get crime statistics from user-reported incidents
Uses user-generated incident reports instead of external APIs
"""
from .incident_service import calculate_crime_score_from_incidents

def get_crime_data(latitude: float, longitude: float, radius_km: float = 1.0) -> dict:
    """
    Get crime data for a location based on user-reported incidents
    
    Args:
        latitude: Location latitude
        longitude: Location longitude
        radius_km: Search radius in kilometers
    
    Returns:
        dict: Crime statistics based on user reports
    """
    try:
        return calculate_crime_score_from_incidents(latitude, longitude, radius_km)
    except Exception as e:
        return {
            "crime_rate": 20,
            "safety_level": "safe",
            "recent_incidents": 0,
            "error": str(e),
            "data_source": "user_reports"
        }

