"""
Authentication Service
Handles user signup, login, and JWT token management
"""
import json
import os
import hashlib
from datetime import datetime, timedelta
from typing import Optional, Dict
from jose import JWTError, jwt
import bcrypt

# Password hashing - using bcrypt directly to avoid passlib compatibility issues

# JWT settings
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30 * 24 * 60  # 30 days

USERS_FILE = "users.json"

def load_users() -> list:
    """Load users from file"""
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE, 'r') as f:
                return json.load(f)
        except:
            return []
    return []

def save_users(users: list):
    """Save users to file"""
    with open(USERS_FILE, 'w') as f:
        json.dump(users, f, indent=2)

def get_password_hash(password: str) -> str:
    """Hash a password - handles bcrypt's 72 byte limit"""
    # Bcrypt has a 72 byte limit, so we hash long passwords first
    # If password is longer than 72 bytes, we hash it with SHA256 first
    password_bytes = password.encode('utf-8')
    
    # If password is longer than 72 bytes, hash it with SHA256 first
    if len(password_bytes) > 72:
        # Hash with SHA256 first, then bcrypt the hash
        sha256_hash = hashlib.sha256(password_bytes).hexdigest()
        # SHA256 hexdigest is 64 bytes, which is < 72, so safe for bcrypt
        return bcrypt.hashpw(sha256_hash.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    # Normal password hashing
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash - handles bcrypt's 72 byte limit"""
    password_bytes = plain_password.encode('utf-8')
    hashed_bytes = hashed_password.encode('utf-8')
    
    # Try direct verification first
    try:
        if bcrypt.checkpw(password_bytes, hashed_bytes):
            return True
    except:
        pass
    
    # If password is longer than 72 bytes, hash it with SHA256 first
    if len(password_bytes) > 72:
        sha256_hash = hashlib.sha256(password_bytes).hexdigest()
        try:
            return bcrypt.checkpw(sha256_hash.encode('utf-8'), hashed_bytes)
        except:
            return False
    
    return False

def validate_phone_number(phone: str) -> bool:
    """Validate phone number format (Tunisian format: +216XXXXXXXXX or 0XXXXXXXXX)"""
    # Remove spaces and dashes
    phone = phone.replace(" ", "").replace("-", "")
    
    # Check Tunisian format
    if phone.startswith("+216"):
        phone = phone[4:]
    elif phone.startswith("00216"):
        phone = phone[5:]
    elif phone.startswith("216"):
        phone = phone[3:]
    
    # Should be 8 digits starting with 2, 5, 9, or 7
    if len(phone) == 8 and phone[0] in ["2", "5", "9", "7"]:
        return True
    
    return False

def normalize_phone_number(phone: str) -> str:
    """Normalize phone number to +216XXXXXXXXX format"""
    phone = phone.replace(" ", "").replace("-", "")
    
    if phone.startswith("+216"):
        return phone
    elif phone.startswith("00216"):
        return "+" + phone[2:]
    elif phone.startswith("216"):
        return "+" + phone
    elif phone.startswith("0"):
        return "+216" + phone[1:]
    else:
        return "+216" + phone

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Optional[Dict]:
    """Verify and decode JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def signup_user(phone_number: str, full_name: str, password: str) -> Dict:
    """
    Register a new user
    
    Args:
        phone_number: User's phone number
        full_name: User's full name
        password: User's password (will be hashed)
    
    Returns:
        dict: Success status and user info or error message
    """
    # Validate inputs
    if not phone_number or not full_name or not password:
        return {
            "success": False,
            "error": "All fields are required"
        }
    
    # Validate phone number
    if not validate_phone_number(phone_number):
        return {
            "success": False,
            "error": "Invalid phone number format. Use Tunisian format: +216XXXXXXXXX or 0XXXXXXXXX"
        }
    
    # Validate password (at least 6 characters)
    if len(password) < 6:
        return {
            "success": False,
            "error": "Password must be at least 6 characters long"
        }
    
    # Validate full name (at least 2 characters)
    if len(full_name.strip()) < 2:
        return {
            "success": False,
            "error": "Full name must be at least 2 characters long"
        }
    
    # Normalize phone number
    normalized_phone = normalize_phone_number(phone_number)
    
    # Check if user already exists
    users = load_users()
    for user in users:
        if user.get("phone_number") == normalized_phone:
            return {
                "success": False,
                "error": "Phone number already registered"
            }
    
    # Create new user
    new_user = {
        "id": len(users) + 1,
        "phone_number": normalized_phone,
        "full_name": full_name.strip(),
        "password_hash": get_password_hash(password),
        "created_at": datetime.now().isoformat(),
        "is_active": True
    }
    
    users.append(new_user)
    save_users(users)
    
    # Create access token
    access_token = create_access_token(
        data={"sub": normalized_phone, "user_id": new_user["id"]}
    )
    
    return {
        "success": True,
        "message": "User registered successfully",
        "user": {
            "id": new_user["id"],
            "phone_number": normalized_phone,
            "full_name": new_user["full_name"]
        },
        "access_token": access_token,
        "token_type": "bearer"
    }

def login_user(phone_number: str, password: str) -> Dict:
    """
    Authenticate user and return access token
    
    Args:
        phone_number: User's phone number
        password: User's password
    
    Returns:
        dict: Success status and access token or error message
    """
    # Validate inputs
    if not phone_number or not password:
        return {
            "success": False,
            "error": "Phone number and password are required"
        }
    
    # Normalize phone number
    normalized_phone = normalize_phone_number(phone_number)
    
    # Find user
    users = load_users()
    user = None
    for u in users:
        if u.get("phone_number") == normalized_phone:
            user = u
            break
    
    if not user:
        return {
            "success": False,
            "error": "Invalid phone number or password"
        }
    
    # Check if user is active
    if not user.get("is_active", True):
        return {
            "success": False,
            "error": "Account is deactivated"
        }
    
    # Verify password
    if not verify_password(password, user["password_hash"]):
        return {
            "success": False,
            "error": "Invalid phone number or password"
        }
    
    # Create access token
    access_token = create_access_token(
        data={"sub": normalized_phone, "user_id": user["id"]}
    )
    
    return {
        "success": True,
        "message": "Login successful",
        "user": {
            "id": user["id"],
            "phone_number": normalized_phone,
            "full_name": user["full_name"]
        },
        "access_token": access_token,
        "token_type": "bearer"
    }

def get_user_by_token(token: str) -> Optional[Dict]:
    """
    Get user information from JWT token
    
    Args:
        token: JWT access token
    
    Returns:
        dict: User information or None if invalid
    """
    payload = verify_token(token)
    if not payload:
        return None
    
    phone_number = payload.get("sub")
    if not phone_number:
        return None
    
    users = load_users()
    for user in users:
        if user.get("phone_number") == phone_number:
            return {
                "id": user["id"],
                "phone_number": user["phone_number"],
                "full_name": user["full_name"]
            }
    
    return None

