"""
Image Analysis Service using Groq AI with OpenCV fallback
"""
import os
import base64
import cv2
import numpy as np
from groq import Groq
from PIL import Image
import io

def analyze_image_with_opencv(image_bytes: bytes) -> dict:
    """
    Fallback image analysis using OpenCV when Groq vision is unavailable
    Detects basic road hazards using computer vision
    """
    try:
        # Convert bytes to numpy array
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return {
                "error": "Could not decode image",
                "indicators": {}
            }
        
        # Convert to different color spaces for analysis
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        road_hazards = {
            "construction_roadwork": False,
            "water_flooding": False,
            "obstacles_debris": False,
            "poor_road_condition": False,
            "traffic_hazards": False
        }
        
        hazard_severity = "none"
        hazard_description = ""
        
        # Detect orange/yellow colors (construction signs, barriers)
        # Orange range in HSV
        lower_orange = np.array([10, 100, 100])
        upper_orange = np.array([25, 255, 255])
        orange_mask = cv2.inRange(hsv, lower_orange, upper_orange)
        orange_pixels = cv2.countNonZero(orange_mask)
        orange_percentage = (orange_pixels / (img.shape[0] * img.shape[1])) * 100
        
        # Detect yellow colors (construction equipment, warning signs)
        lower_yellow = np.array([20, 100, 100])
        upper_yellow = np.array([30, 255, 255])
        yellow_mask = cv2.inRange(hsv, lower_yellow, upper_yellow)
        yellow_pixels = cv2.countNonZero(yellow_mask)
        yellow_percentage = (yellow_pixels / (img.shape[0] * img.shape[1])) * 100
        
        # Detect blue colors (water, but also sky - need to be careful)
        lower_blue = np.array([100, 50, 50])
        upper_blue = np.array([130, 255, 255])
        blue_mask = cv2.inRange(hsv, lower_blue, upper_blue)
        blue_pixels = cv2.countNonZero(blue_mask)
        blue_percentage = (blue_pixels / (img.shape[0] * img.shape[1])) * 100
        
        # Detect edges (potential obstacles, road damage)
        edges = cv2.Canny(gray, 50, 150)
        edge_density = cv2.countNonZero(edges) / (img.shape[0] * img.shape[1])
        
        # Analyze brightness (lighting conditions)
        mean_brightness = np.mean(gray)
        
        # Heuristics for hazard detection
        # Lower threshold for construction detection (orange/yellow = construction signs, barriers, workers)
        construction_threshold = 2.0  # Lowered from 5% to catch more construction sites
        if orange_percentage > construction_threshold or yellow_percentage > construction_threshold:
            road_hazards["construction_roadwork"] = True
            # If both orange and yellow are present, it's more likely construction
            if orange_percentage > construction_threshold and yellow_percentage > construction_threshold:
                hazard_severity = "high"
                hazard_description += f"Active construction/roadwork detected (orange: {orange_percentage:.1f}%, yellow: {yellow_percentage:.1f}%). "
            else:
                hazard_severity = "moderate"
                hazard_description += f"Construction/roadwork detected (orange/yellow colors: {orange_percentage + yellow_percentage:.1f}%). "
        
        # Water detection - be more careful (blue could be sky)
        # Only detect water if blue is in lower part of image (not sky)
        if blue_percentage > 20:  # High blue percentage
            # Check if it's likely water (would need image analysis, but for now use edge density)
            if edge_density > 0.12:  # Water has reflections/edges
                road_hazards["water_flooding"] = True
                if hazard_severity in ["none", "low"]:
                    hazard_severity = "moderate"
                hazard_description += f"Possible water/flooding detected (blue: {blue_percentage:.1f}%). "
        
        # High edge density indicates obstacles, debris, or poor road condition
        if edge_density > 0.15:
            road_hazards["poor_road_condition"] = True
            if hazard_severity == "none":
                hazard_severity = "low"
            elif hazard_severity == "low" and road_hazards.get("construction_roadwork"):
                hazard_severity = "moderate"  # Construction + poor road = higher severity
            hazard_description += f"High edge density detected (possible obstacles or road damage: {edge_density:.3f}). "
        
        # If construction is detected, also mark as poor road condition
        if road_hazards.get("construction_roadwork") and not road_hazards.get("poor_road_condition"):
            road_hazards["poor_road_condition"] = True
            hazard_description += "Construction zone typically indicates road work in progress. "
        
        # Determine lighting
        if mean_brightness > 150:
            lighting = "good"
        elif mean_brightness > 100:
            lighting = "moderate"
        else:
            lighting = "poor"
        
        # Determine if travel is safe
        travel_safe = hazard_severity in ["none", "low"]
        
        if not hazard_description:
            hazard_description = "No obvious hazards detected by computer vision analysis."
        
        print(f"🔍 OpenCV Analysis Results:")
        print(f"  - Orange/Yellow: {orange_percentage:.1f}% (construction)")
        print(f"  - Blue: {blue_percentage:.1f}% (possible water)")
        print(f"  - Edge density: {edge_density:.3f}")
        print(f"  - Brightness: {mean_brightness:.1f}")
        print(f"  - Hazards detected: {road_hazards}")
        
        return {
            "analysis": f"OpenCV-based analysis: {hazard_description}",
            "indicators": {
                "lighting": lighting,
                "people_present": False,  # Can't detect with basic CV
                "cleanliness": "moderate",
                "road_hazards": road_hazards,
                "hazard_severity": hazard_severity,
                "hazard_description": hazard_description,
                "travel_safe": travel_safe,
                "safety_notes": f"Computer vision analysis (OpenCV). {hazard_description}"
            },
            "hazard_severity": hazard_severity,
            "hazard_description": hazard_description
        }
    except Exception as e:
        print(f"❌ OpenCV analysis error: {str(e)}")
        return {
            "error": f"OpenCV analysis failed: {str(e)}",
            "indicators": {}
        }

def analyze_image_safety(image_bytes: bytes) -> dict:
    """
    Analyze image for safety indicators using Groq AI
    
    Returns:
        dict: Analysis results with safety indicators
    """
    groq_api_key = os.getenv("GROQ_API_KEY")
    
    if not groq_api_key:
        return {
            "error": "GROQ_API_KEY not found",
            "safety_score": 50,
            "indicators": []
        }
    
    try:
        # Initialize Groq client
        # Workaround for proxies parameter issue - clear proxy env vars temporarily
        import os as groq_os
        
        # Save and remove proxy env vars that might cause issues
        proxy_vars = {}
        for var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy', 'ALL_PROXY', 'all_proxy']:
            if var in groq_os.environ:
                proxy_vars[var] = groq_os.environ.pop(var)
        
        try:
            # Initialize Groq client
            client = Groq(api_key=groq_api_key)
        except Exception as init_error:
            error_str = str(init_error)
            if "proxies" in error_str.lower():
                # If still failing, try with requests session without proxies
                import requests
                session = requests.Session()
                session.proxies = {}
                # This is a workaround - we'll use the client as is
                # The error might be in the underlying HTTP client
                raise Exception(f"Groq SDK version issue. Please upgrade: pip install --upgrade groq")
            raise
        finally:
            # Restore proxy env vars if they existed
            for var, value in proxy_vars.items():
                groq_os.environ[var] = value
        
        # Convert image to base64
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Prepare the prompt for safety analysis - focus on travel/road hazards
        prompt = f"""Analyze this street/road image for TRAVEL SAFETY and ROAD HAZARDS.
        
        CRITICAL: Look for these specific travel obstacles and hazards:
        1. **Roadwork/Construction (Travaux)**: Barricades, construction signs, workers, heavy machinery, road closures
        2. **Water/Flooding**: Standing water, flooded areas, puddles, drainage issues
        3. **Road Obstacles**: Debris, fallen trees, rocks, large potholes, broken pavement
        4. **Traffic Hazards**: Heavy traffic, dangerous intersections, lack of traffic signs
        5. **Road Conditions**: Damaged road, cracks, uneven surface, slippery conditions
        
        Also check general safety:
        - Lighting conditions (well-lit = safer)
        - Presence of people (more people = generally safer, but also consider if too crowded)
        - Cleanliness and maintenance
        - Visible security features (cameras, lights, etc.)
        
        Return a JSON object with:
        {{
            "road_hazards": {{
                "construction_roadwork": true/false,
                "water_flooding": true/false,
                "obstacles_debris": true/false,
                "poor_road_condition": true/false,
                "traffic_hazards": true/false
            }},
            "hazard_severity": "none" | "low" | "moderate" | "high" | "critical",
            "hazard_description": "brief description of hazards found",
            "lighting": "good" | "moderate" | "poor",
            "people_present": true/false,
            "cleanliness": "good" | "moderate" | "poor",
            "security_features": ["cameras", "lights", etc.],
            "overall_condition": "good" | "moderate" | "poor",
            "safety_notes": "brief description of safety concerns for travelers",
            "travel_safe": true/false  // Is it safe to travel this route?
        }}
        
        IMPORTANT: If you see construction, water, obstacles, or poor road conditions, mark them as true and set hazard_severity accordingly."""
        
        # Use Groq's vision API with image
        # Create message with image
        user_message = {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": prompt
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{image_base64}"
                    }
                }
            ]
        }
        
        # Try different vision models - Groq vision models
        # Note: Some models may not support vision, so we try multiple approaches
        vision_models = [
            "llama-3.2-11b-vision-preview",  # Smaller vision model
            "llama-3.2-90b-vision-preview",   # Larger vision model
        ]
        
        response = None
        last_error = None
        
        # First, try with vision-capable models using image_url format
        for model_name in vision_models:
            try:
                print(f"🔄 Trying vision model: {model_name}")
                response = client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a safety analysis expert. Analyze images for street and neighborhood safety. Always return valid JSON."
                        },
                        user_message
                    ],
                    response_format={"type": "json_object"}
                )
                print(f"✅ Success with vision model: {model_name}")
                break
            except Exception as model_error:
                last_error = model_error
                error_str = str(model_error)
                print(f"❌ Vision model {model_name} failed: {error_str}")
                # If model doesn't exist or is decommissioned, try next
                if "decommissioned" in error_str.lower() or "not found" in error_str.lower():
                    continue
                # If it's a format error, the model doesn't support vision
                if "must be a string" in error_str.lower():
                    break  # Try alternative approach
                continue
        
        # If vision models failed, use OpenCV-based analysis as fallback
        if response is None:
            print("🔄 Vision models not available, using OpenCV-based analysis...")
            return analyze_image_with_opencv(image_bytes)
        
        # Parse response
        analysis_text = response.choices[0].message.content
        
        # Parse JSON response
        import json
        try:
            analysis_data = json.loads(analysis_text)
            
            # Extract indicators from parsed response
            road_hazards = analysis_data.get("road_hazards", {})
            if not isinstance(road_hazards, dict):
                road_hazards = {}
            
            indicators = {
                "lighting": analysis_data.get("lighting", "moderate"),
                "people_present": analysis_data.get("people_present", False),
                "cleanliness": analysis_data.get("cleanliness", "moderate"),
                "road_hazards": road_hazards,
                "hazard_severity": analysis_data.get("hazard_severity", "none"),
                "hazard_description": analysis_data.get("hazard_description", ""),
                "travel_safe": analysis_data.get("travel_safe", True),
                "safety_notes": analysis_data.get("safety_notes", "")
            }
            
            # Debug print
            print(f"🔍 Image Analysis Results:")
            print(f"  - Road Hazards: {road_hazards}")
            print(f"  - Has Construction: {road_hazards.get('construction_roadwork', False)}")
            print(f"  - Has Water: {road_hazards.get('water_flooding', False)}")
            print(f"  - Has Obstacles: {road_hazards.get('obstacles_debris', False)}")
            print(f"  - Hazard Severity: {indicators['hazard_severity']}")
            print(f"  - Travel Safe: {indicators['travel_safe']}")
            
            return {
                "analysis": analysis_text,
                "indicators": indicators,
                "hazard_severity": analysis_data.get("hazard_severity", "none"),
                "hazard_description": analysis_data.get("hazard_description", "")
            }
        except json.JSONDecodeError:
            # If JSON parsing fails, return basic structure
            return {
                "analysis": analysis_text,
                "indicators": {
                    "lighting": "moderate",
                    "people_present": True,
                    "cleanliness": "good",
                    "road_hazards": {},
                    "hazard_severity": "none",
                    "travel_safe": True
                },
                "error": "Failed to parse JSON response"
            }
        
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Image Analysis Error: {error_msg}")
        
        # If it's a proxies error, try without any proxy settings
        if "proxies" in error_msg.lower():
            try:
                # Try again with explicit no-proxy settings
                import os as groq_os
                for proxy_var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy']:
                    groq_os.environ.pop(proxy_var, None)
                
                # Retry initialization
                client = Groq(api_key=groq_api_key)
                
                # Retry the full analysis - recreate prompt and image
                image_base64 = base64.b64encode(image_bytes).decode('utf-8')
                retry_prompt = """Analyze this street/road image for TRAVEL SAFETY and ROAD HAZARDS.
        
        CRITICAL: Look for these specific travel obstacles and hazards:
        1. **Roadwork/Construction (Travaux)**: Barricades, construction signs, workers, heavy machinery, road closures
        2. **Water/Flooding**: Standing water, flooded areas, puddles, drainage issues
        3. **Road Obstacles**: Debris, fallen trees, rocks, large potholes, broken pavement
        4. **Traffic Hazards**: Heavy traffic, dangerous intersections, lack of traffic signs
        5. **Road Conditions**: Damaged road, cracks, uneven surface, slippery conditions
        
        Return a JSON object with:
        {
            "road_hazards": {
                "construction_roadwork": false,
                "water_flooding": false,
                "obstacles_debris": false,
                "poor_road_condition": false,
                "traffic_hazards": false
            },
            "hazard_severity": "none",
            "hazard_description": "",
            "lighting": "moderate",
            "people_present": false,
            "cleanliness": "moderate",
            "travel_safe": true
        }"""
                
                user_message = {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": retry_prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_base64}"
                            }
                        }
                    ]
                }
                
                response = client.chat.completions.create(
                    model="llama-3.2-90b-vision-preview",
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a safety analysis expert. Analyze images for street and neighborhood safety. Always return valid JSON."
                        },
                        user_message
                    ],
                    response_format={"type": "json_object"}
                )
                
                analysis_text = response.choices[0].message.content
                import json
                analysis_data = json.loads(analysis_text)
                
                road_hazards = analysis_data.get("road_hazards", {})
                if not isinstance(road_hazards, dict):
                    road_hazards = {}
                
                indicators = {
                    "lighting": analysis_data.get("lighting", "moderate"),
                    "people_present": analysis_data.get("people_present", False),
                    "cleanliness": analysis_data.get("cleanliness", "moderate"),
                    "road_hazards": road_hazards,
                    "hazard_severity": analysis_data.get("hazard_severity", "none"),
                    "hazard_description": analysis_data.get("hazard_description", ""),
                    "travel_safe": analysis_data.get("travel_safe", True),
                    "safety_notes": analysis_data.get("safety_notes", "")
                }
                
                print(f"🔍 Image Analysis Results (retry):")
                print(f"  - Road Hazards: {road_hazards}")
                print(f"  - Hazard Severity: {indicators['hazard_severity']}")
                
                return {
                    "analysis": analysis_text,
                    "indicators": indicators,
                    "hazard_severity": analysis_data.get("hazard_severity", "none"),
                    "hazard_description": analysis_data.get("hazard_description", "")
                }
            except Exception as e2:
                print(f"❌ Retry also failed: {str(e2)}")
                return {
                    "error": f"Groq API error: {str(e2)}",
                    "safety_score": 50,
                    "indicators": {}
                }
        
        # Even if there's an error, return structure that can be checked
        print(f"❌ Final error return: {error_msg}")
        return {
            "error": error_msg,
            "safety_score": 50,
            "indicators": {}  # Empty dict, not list
        }

