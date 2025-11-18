"""
Safety Score Calculator
Combines image analysis, weather, and crime data to calculate safety score (1-100)
"""
from typing import Dict

def calculate_safety_score(
    image_analysis: Dict,
    weather_data: Dict,
    crime_data: Dict
) -> Dict:
    """
    Calculate overall safety score from multiple factors
    
    Args:
        image_analysis: Results from image analysis
        weather_data: Weather information
        crime_data: Crime statistics
    
    Returns:
        dict: Safety score (1-100) and breakdown
    """
    score = 50  # Start with neutral score
    factors = {}
    
    # Image analysis contribution (30% weight)
    # Only calculate if image was actually analyzed (has real indicators, not empty)
    has_image_analysis = (
        "indicators" in image_analysis and 
        image_analysis["indicators"] and 
        isinstance(image_analysis["indicators"], dict) and
        len(image_analysis["indicators"]) > 0 and
        not image_analysis.get("error")
    )
    
    if has_image_analysis:
        img_score = 50
        indicators = image_analysis["indicators"]
        
        # ROAD HAZARDS - Most critical for travel safety (0-40 points impact)
        road_hazards = indicators.get("road_hazards", {})
        hazard_severity = indicators.get("hazard_severity", "none")
        
        # Check for specific hazards
        has_construction = road_hazards.get("construction_roadwork", False)
        has_water = road_hazards.get("water_flooding", False)
        has_obstacles = road_hazards.get("obstacles_debris", False)
        has_poor_road = road_hazards.get("poor_road_condition", False)
        has_traffic_hazards = road_hazards.get("traffic_hazards", False)
        
        # Count number of hazards
        hazard_count = sum([has_construction, has_water, has_obstacles, has_poor_road, has_traffic_hazards])
        
        # Apply severe penalties for road hazards
        # Note: hazard_severity already accounts for travel safety, so we don't double-penalize
        if hazard_severity == "critical":
            img_score -= 40  # Critical hazards = very unsafe
        elif hazard_severity == "high":
            img_score -= 30  # High hazards = unsafe (construction sites)
        elif hazard_severity == "moderate":
            img_score -= 20  # Moderate hazards = caution (construction, water)
        elif hazard_severity == "low":
            img_score -= 12  # Low hazards = minor impact
        elif hazard_count > 0:
            # If hazards detected but no severity, apply based on count
            img_score -= (hazard_count * 8)  # Penalty per hazard
        
        # Travel safety check - only apply if severity wasn't already applied
        # (hazard_severity already reflects travel safety)
        # Only add extra penalty if travel_safe is False but severity is low/none
        if not indicators.get("travel_safe", True) and hazard_severity in ["none", "low"]:
            img_score -= 15  # Additional penalty only if severity didn't already account for it
        
        # Lighting (0-10 points) - reduced impact
        lighting = indicators.get("lighting", "moderate")
        if lighting == "good":
            img_score += 10
        elif lighting == "moderate":
            img_score += 3  # Small bonus for moderate lighting
        else:
            img_score -= 3  # Small penalty for poor lighting
        
        # People present (0-5 points) - reduced impact
        if indicators.get("people_present", False):
            img_score += 5  # People can indicate safety (witnesses) or danger (crowds)
        
        # Cleanliness (0-5 points) - reduced impact
        cleanliness = indicators.get("cleanliness", "moderate")
        if cleanliness == "good":
            img_score += 5
        elif cleanliness == "moderate":
            img_score += 2  # Small bonus
        else:
            img_score -= 2  # Small penalty
        
        # Ensure minimum score of 5 (not 0) to show that image was analyzed
        # Even with severe hazards, we want to show some score
        img_score = max(5, min(100, img_score))
        factors["image_analysis"] = img_score
        # Increase weight of image analysis to 40% since it's a key feature
        score = (score * 0.6) + (img_score * 0.4)
        print(f"📊 Image score calculated: {img_score}, New total score after image: {score}")
    else:
        # No image provided - don't include in score calculation
        factors["image_analysis"] = None
    
    # Weather contribution (25% weight)
    weather_impact = weather_data.get("safety_impact", "neutral")
    weather_score = 50
    if weather_impact == "negative":
        weather_score = 30
    elif weather_impact == "positive":
        weather_score = 70
    
    factors["weather"] = weather_score
    score = (score * 0.75) + (weather_score * 0.25)
    print(f"📊 Weather score: {weather_score}, New total score after weather: {score}")
    
    # Crime data contribution (50% weight - most important)
    crime_rate = crime_data.get("crime_rate", 50)
    crime_score = 100 - crime_rate  # Invert: lower crime = higher score
    
    factors["crime_data"] = crime_score
    score = (score * 0.6) + (crime_score * 0.4)
    print(f"📊 Crime score: {crime_score}, New total score after crime: {score}")
    
    # Final score (1-100)
    final_score = max(1, min(100, int(score)))
    
    # Determine safety level
    if final_score >= 80:
        level = "very_safe"
        alert = False
    elif final_score >= 60:
        level = "safe"
        alert = False
    elif final_score >= 40:
        level = "moderate"
        alert = False
    elif final_score >= 20:
        level = "caution"
        alert = True
    else:
        level = "unsafe"
        alert = True
    
    return {
        "safety_score": final_score,
        "safety_level": level,
        "alert": alert,
        "factors": factors,
        "breakdown": {
            "image_analysis": factors.get("image_analysis"),  # None if no image
            "weather": factors.get("weather", 50),
            "crime_data": factors.get("crime_data", 50)
        }
    }

