"""
User Incident Reporting Service
Users can report crimes/incidents they witness or experience
"""
import json
import os
from datetime import datetime
from typing import List, Dict
from geopy.distance import geodesic

INCIDENTS_FILE = "incidents.json"

def load_incidents() -> List[Dict]:
    """Load incidents from file"""
    if os.path.exists(INCIDENTS_FILE):
        try:
            with open(INCIDENTS_FILE, 'r') as f:
                return json.load(f)
        except:
            return []
    return []

def save_incidents(incidents: List[Dict]):
    """Save incidents to file"""
    with open(INCIDENTS_FILE, 'w') as f:
        json.dump(incidents, f, indent=2)

def report_incident(latitude: float, longitude: float, incident_type: str, description: str = "") -> Dict:
    """
    Report a new incident
    
    Args:
        latitude: Location latitude
        longitude: Location longitude
        incident_type: Type of incident (theft, assault, vandalism, etc.)
        description: Optional description
    
    Returns:
        dict: Confirmation of reported incident
    """
    incidents = load_incidents()
    
    new_incident = {
        "id": len(incidents) + 1,
        "latitude": latitude,
        "longitude": longitude,
        "incident_type": incident_type,
        "description": description,
        "reported_at": datetime.now().isoformat(),
        "verified": False  # Could add verification system later
    }
    
    incidents.append(new_incident)
    save_incidents(incidents)
    
    return {
        "success": True,
        "incident_id": new_incident["id"],
        "message": "Incident reported successfully"
    }

def get_incidents_near_location(latitude: float, longitude: float, radius_km: float = 1.0) -> List[Dict]:
    """
    Get incidents near a location
    
    Args:
        latitude: Location latitude
        longitude: Location longitude
        radius_km: Search radius in kilometers
    
    Returns:
        list: List of incidents within radius
    """
    incidents = load_incidents()
    location = (latitude, longitude)
    nearby_incidents = []
    
    for incident in incidents:
        incident_location = (incident["latitude"], incident["longitude"])
        distance = geodesic(location, incident_location).kilometers
        
        if distance <= radius_km:
            incident_copy = incident.copy()
            incident_copy["distance_km"] = round(distance, 2)
            nearby_incidents.append(incident_copy)
    
    return nearby_incidents

def calculate_crime_score_from_incidents(latitude: float, longitude: float, radius_km: float = 1.0) -> Dict:
    """
    Calculate crime score based on user-reported incidents
    
    Args:
        latitude: Location latitude
        longitude: Location longitude
        radius_km: Search radius in kilometers
    
    Returns:
        dict: Crime statistics based on user reports
    """
    incidents = get_incidents_near_location(latitude, longitude, radius_km)
    
    # Calculate crime rate based on number of incidents
    # More incidents = higher crime rate
    incident_count = len(incidents)
    
    # Recent incidents (within last 30 days) count more
    from datetime import datetime, timedelta
    thirty_days_ago = datetime.now() - timedelta(days=30)
    
    recent_count = sum(
        1 for inc in incidents 
        if datetime.fromisoformat(inc["reported_at"]) > thirty_days_ago
    )
    
    if not incidents:
        # No incidents = very safe area
        crime_rate = 10  # Lower base (was 20) = higher safety score
        return {
            "crime_rate": crime_rate,
            "safety_level": "very_safe",
            "recent_incidents": 0,
            "total_incidents": 0,
            "incident_types": [],
            "data_source": "user_reports",
            "message": "No incidents reported in this area - very safe!"
        }
    
    # Calculate crime rate (0-100)
    # Base: 10 (very safe if no incidents)
    # Each incident adds points based on severity
    # Recent incidents add more weight
    base_rate = 10
    incident_points = incident_count * 15  # Each incident adds 15 points
    recent_bonus = recent_count * 10  # Recent incidents add extra 10 points each
    
    crime_rate = base_rate + incident_points + recent_bonus
    crime_rate = min(100, crime_rate)  # Cap at 100
    
    # Get unique incident types
    incident_types = list(set([inc["incident_type"] for inc in incidents]))
    
    # Determine safety level
    if crime_rate < 30:
        safety_level = "very_safe"
    elif crime_rate < 50:
        safety_level = "safe"
    elif crime_rate < 70:
        safety_level = "moderate"
    elif crime_rate < 85:
        safety_level = "caution"
    else:
        safety_level = "unsafe"
    
    return {
        "crime_rate": crime_rate,
        "safety_level": safety_level,
        "recent_incidents": recent_count,
        "total_incidents": incident_count,
        "incident_types": incident_types,
        "incidents": incidents[:5],  # Return first 5 for details
        "data_source": "user_reports",
        "last_updated": datetime.now().isoformat()
    }

