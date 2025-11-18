# 🛡️ TravelSafe - AI Safety Assistant

**TravelSafe** est une application mobile intelligente qui génère des rapports de sécurité en temps réel pour les conducteurs dans un rayon de 1 kilomètre basé sur leur localisation actuelle.

---

## 📋 Description du Projet

TravelSafe est une application Flutter avec un backend Python/FastAPI qui évalue la sécurité d'une zone en combinant trois facteurs principaux :

- 🌦️ **Conditions Météorologiques** : Intégration en temps réel des données météo via OpenWeatherMap API pour alerter les utilisateurs sur les conditions de conduite dangereuses (pluie, brouillard, vent fort, etc.)

- 📊 **Rapports d'Incidents Communautaires** : Système de signalement d'incidents par les utilisateurs. Chaque nouveau rapport augmente automatiquement le niveau de criminalité de cette zone spécifique

- 🤖 **Analyse d'Images par IA** : Les conducteurs peuvent télécharger des photos de la route, et l'IA analyse ces images pour détecter les dangers potentiels tels que les travaux routiers, l'accumulation d'eau, ou les débris

L'application calcule un score de sécurité (1-100) et envoie des alertes pour les zones non sécurisées.

---

## 🛠️ Technologies Utilisées

### Backend
- **FastAPI** - Framework web moderne et rapide pour construire des APIs
- **Python 3.12** - Langage de programmation
- **Groq API** - Analyse d'images par intelligence artificielle
- **OpenCV** - Traitement d'images et vision par ordinateur (fallback)
- **OpenWeatherMap API** - Données météorologiques en temps réel
- **Scikit-learn** - Machine learning pour l'analyse de données
- **Geopy** - Services de géolocalisation
- **JWT (JSON Web Tokens)** - Authentification sécurisée
- **bcrypt** - Hachage de mots de passe
- **Pandas & NumPy** - Analyse et manipulation de données

### Frontend (Mobile/Web)
- **Flutter** - Framework multiplateforme (Web, Android, iOS, Windows)
- **Google Maps Flutter** - Intégration de cartes (mobile uniquement)
- **Geolocator** - Services de localisation GPS
- **Geocoding** - Conversion coordonnées ↔ adresses
- **Image Picker** - Capture et sélection d'images
- **HTTP** - Communication avec l'API backend
- **Shared Preferences** - Stockage local pour les tokens d'authentification

---

## 📁 Structure du Projet

```
TravelSafe/
├── backend/                    # Backend Python/FastAPI
│   ├── services/               # Services métier
│   │   ├── auth_service.py     # Authentification (login/signup)
│   │   ├── image_analysis.py   # Analyse d'images par IA (Groq + OpenCV)
│   │   ├── weather_service.py  # Service météorologique
│   │   ├── incident_service.py # Gestion des incidents signalés
│   │   ├── crime_service.py    # Calcul des scores de criminalité
│   │   └── safety_scorer.py    # Calcul du score de sécurité global
│   ├── main.py                 # Point d'entrée FastAPI
│   ├── requirements.txt        # Dépendances Python
│   ├── .env                    # Variables d'environnement (à créer)
│   ├── users.json              # Base de données utilisateurs (JSON)
│   └── incidents.json          # Base de données incidents (JSON)
│
└── mobile/                     # Application Flutter
    ├── lib/
    │   ├── main.dart           # Point d'entrée Flutter
    │   ├── screens/            # Écrans de l'application
    │   │   ├── home_screen.dart      # Page d'accueil
    │   │   ├── login_screen.dart     # Écran de connexion
    │   │   └── signup_screen.dart    # Écran d'inscription
    │   └── services/           # Services côté client
    │       ├── api_service.dart      # Communication API
    │       └── auth_service.dart     # Gestion authentification locale
    ├── pubspec.yaml            # Dépendances Flutter
    └── android/ios/web/        # Configurations plateformes
```

---

## 🚀 Comment Exécuter l'Application

### Prérequis

- ✅ **Python 3.12+** installé
- ✅ **Flutter 3.24+** installé et configuré
- ✅ **Git** pour cloner le projet
- ✅ **Clés API** :
  - Groq API Key (https://console.groq.com/)
  - OpenWeatherMap API Key (https://openweathermap.org/api)

---

### 📦 Étape 1 : Configuration du Backend

1. **Naviguer vers le dossier backend :**
   ```bash
   cd backend
   ```

2. **Activer l'environnement virtuel :**
   
   **Windows (PowerShell) :**
   ```powershell
   venv\Scripts\Activate.ps1
   ```
   
   **Windows (Command Prompt) :**
   ```cmd
   venv\Scripts\activate.bat
   ```
   
   Vous devriez voir `(venv)` au début de votre ligne de commande.

3. **Installer les dépendances :**
   ```bash
   pip install -r requirements.txt
   ```

4. **Créer le fichier `.env` :**
   
   Créez un fichier nommé `.env` dans le dossier `backend/` avec le contenu suivant :
   ```env
   GROQ_API_KEY=votre_cle_groq_ici
   WEATHER_API_KEY=votre_cle_openweathermap_ici
   JWT_SECRET_KEY=votre_secret_jwt_ici
   ```
   
   > **Note :** Remplacez les valeurs par vos clés API réelles.

5. **Lancer le serveur backend :**
   ```bash
   python main.py
   ```
   
   Ou avec uvicorn directement :
   ```bash
   uvicorn main:app --reload
   ```
   
   **✅ Le backend est maintenant en cours d'exécution !**
   
   Vous devriez voir :
   ```
   INFO:     Started server process
   INFO:     Uvicorn running on http://0.0.0.0:8000
   ```

6. **Tester le backend :**
   
   Ouvrez votre navigateur et visitez :
   - **API Documentation (Swagger UI) :** http://localhost:8000/docs
   - **ReDoc :** http://localhost:8000/redoc
   - **Test endpoint :** http://localhost:8000/api/test

> **⚠️ Important :** Gardez ce terminal ouvert ! Le backend doit continuer à fonctionner.

---

### 📱 Étape 2 : Configuration de l'Application Flutter

1. **Ouvrir un NOUVEAU terminal :**
   
   **Important :** Gardez le backend en cours d'exécution dans le premier terminal, ouvrez-en un nouveau !

2. **Naviguer vers le dossier mobile :**
   ```bash
   cd mobile
   ```

3. **Installer les dépendances Flutter :**
   ```bash
   flutter pub get
   ```
   
   Cela télécharge tous les packages requis.

4. **Configurer l'URL de l'API (si nécessaire) :**
   
   Le fichier `mobile/lib/services/api_service.dart` contient l'URL du backend.
   
   Par défaut, il est configuré pour :
   - **Web/Desktop :** `http://localhost:8000` ✅
   
   Pour Android Emulator, changez en :
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8000';
   ```
   
   Pour un appareil réel, utilisez l'adresse IP de votre ordinateur :
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:8000';  // Votre IP
   ```

5. **Vérifier les appareils disponibles :**
   ```bash
   flutter devices
   ```
   
   Vous devriez voir quelque chose comme :
   - Chrome (web)
   - Windows (desktop)
   - Votre téléphone/émulateur connecté

6. **Lancer l'application Flutter :**
   
   **Option A : Exécuter sur Chrome (Web) - Recommandé pour débuter :**
   ```bash
   flutter run -d chrome
   ```
   
   **Option B : Exécuter sur Windows Desktop :**
   ```bash
   flutter run -d windows
   ```
   
   **Option C : Exécuter sur Android Emulator (si Android Studio est configuré) :**
   ```bash
   flutter run
   ```
   
   **Option D : Exécuter sur votre téléphone (si connecté via USB) :**
   ```bash
   flutter run
   ```

---

## 🎯 Utilisation de l'Application

### Premier Lancement

1. **Créer un compte :**
   - Ouvrir l'application
   - Cliquer sur "Sign Up"
   - Remplir : Nom complet, Numéro de téléphone, Mot de passe

2. **Se connecter :**
   - Entrer votre numéro de téléphone et mot de passe
   - Cliquer sur "Login"

3. **Page d'accueil :**
   - Voir les fonctionnalités de l'application
   - Cliquer sur "Get Started"

### Utilisation Principale

1. **Vérifier la localisation :**
   - L'application récupère automatiquement votre position GPS
   - Affiche le nom du lieu actuel
   - Affiche les coordonnées (latitude/longitude)

2. **Analyser la sécurité :**
   - Cliquer sur "Check Safety"
   - L'application calcule un score de sécurité (1-100)
   - Affiche les détails : Météo, Rapports utilisateurs, Analyse d'image

3. **Télécharger une image :**
   - Cliquer sur l'icône image dans l'AppBar
   - Sélectionner une photo de la route
   - L'IA analysera l'image pour détecter les dangers

4. **Signaler un incident :**
   - Cliquer sur "Report" ou "Report Incident"
   - Choisir le type d'incident (Theft, Assault, Vandalism, etc.)
   - L'incident sera enregistré pour cette zone

---

## 🔌 Points de Terminaison API

### Authentification

- **POST** `/api/auth/signup` - Créer un compte
  ```json
  {
    "phone_number": "+216XXXXXXXXX",
    "full_name": "Nom Complet",
    "password": "motdepasse"
  }
  ```

- **POST** `/api/auth/login` - Se connecter
  ```json
  {
    "phone_number": "+216XXXXXXXXX",
    "password": "motdepasse"
  }
  ```

- **GET** `/api/auth/me` - Obtenir l'utilisateur actuel (nécessite token JWT)

### Analyse de Sécurité

- **POST** `/api/safety-analysis` - Analyse complète de sécurité
  - **Body (multipart/form-data) :**
    - `latitude`: float (obligatoire)
    - `longitude`: float (obligatoire)
    - `file`: image (optionnel)
  
  **Réponse :**
  ```json
  {
    "success": true,
    "safety_score": 75,
    "safety_level": "safe",
    "alert": false,
    "breakdown": {
      "image_analysis": 80,
      "weather": 70,
      "crime_data": 90
    },
    "factors": {
      "weather": {...},
      "crime": {...},
      "image_analysis": {...}
    }
  }
  ```

### Incidents

- **POST** `/api/report-incident` - Signaler un incident
  ```json
  {
    "latitude": 36.8065,
    "longitude": 10.1815,
    "incident_type": "theft"
  }
  ```

- **GET** `/api/incidents-nearby` - Obtenir les incidents proches
  - **Query params :** `latitude`, `longitude`, `radius_km` (par défaut: 1.0)

---

## 🐛 Dépannage

### Le backend ne démarre pas ?

- ✅ Vérifiez que l'environnement virtuel est activé (vous devriez voir `(venv)` dans le prompt)
- ✅ Vérifiez que le port 8000 n'est pas déjà utilisé
- ✅ Vérifiez que toutes les dépendances sont installées : `pip install -r requirements.txt`
- ✅ Vérifiez que le fichier `.env` existe et contient les clés API

### Flutter ne peut pas se connecter au backend ?

- ✅ **Pour Web/Desktop :** Assurez-vous que le backend fonctionne sur `http://localhost:8000`
- ✅ **Pour Android Emulator :** Changez l'URL en `http://10.0.2.2:8000` dans `api_service.dart`
- ✅ **Pour Appareil Réel :** Utilisez l'adresse IP de votre ordinateur au lieu de `localhost`
- ✅ Vérifiez que le pare-feu Windows n'bloque pas le port 8000
- ✅ Vérifiez que le backend est toujours en cours d'exécution dans le premier terminal

### Erreurs de dépendances Flutter ?

```bash
cd mobile
flutter clean
flutter pub get
```

### "flutter: command not found" ?

- ✅ Assurez-vous que Flutter est dans votre PATH
- ✅ Redémarrez votre terminal
- ✅ Vérifiez : `flutter --version`

### Erreurs d'authentification ?

- ✅ Vérifiez que le backend est en cours d'exécution
- ✅ Vérifiez que vous utilisez le bon numéro de téléphone et mot de passe
- ✅ Essayez de créer un nouveau compte si nécessaire

---

## 📚 Documentation Complémentaire

### Backend API

Une fois le backend en cours d'exécution, visitez :
- **Swagger UI :** http://localhost:8000/docs
- **ReDoc :** http://localhost:8000/redoc

Ces interfaces fournissent une documentation interactive complète de l'API.

---

## 🔒 Sécurité

- Les mots de passe sont hachés avec **bcrypt** avant stockage
- L'authentification utilise **JWT (JSON Web Tokens)** sécurisés
- Les tokens expirent après 30 jours
- Les clés API sont stockées dans `.env` (non versionnées dans Git)

---

## 🎨 Fonctionnalités de l'Application

- ✅ **Interface moderne et responsive** : Design épuré et professionnel
- ✅ **Page d'accueil élégante** : Présentation des fonctionnalités
- ✅ **Authentification complète** : Login/Signup sécurisé
- ✅ **Géolocalisation automatique** : Récupération GPS avec nom du lieu
- ✅ **Analyse d'images par IA** : Détection des dangers routiers
- ✅ **Météo en temps réel** : Alertes sur les conditions dangereuses
- ✅ **Système de signalement** : Rapports d'incidents communautaires
- ✅ **Score de sécurité** : Calcul intelligent (1-100)
- ✅ **Alertes visuelles** : Notifications pour zones non sécurisées
- ✅ **Multiplateforme** : Fonctionne sur Web, Android, iOS, Windows

---

## 📝 Notes Importantes

- L'application utilise les données météorologiques réelles d'**OpenWeatherMap**
- L'analyse d'images utilise **Groq AI** avec un fallback **OpenCV** si nécessaire
- Les incidents sont stockés localement dans `incidents.json` (pas de base de données externe)
- Les utilisateurs sont stockés dans `users.json` (système simple pour développement)
- Pour la production, considérez utiliser une vraie base de données (PostgreSQL, MongoDB, etc.)

---

## 🚀 Développement Futur

### Améliorations Potentielles

- [ ] Base de données relationnelle (PostgreSQL)
- [ ] Notifications push
- [ ] Historique des analyses de sécurité
- [ ] Partage de rapports de sécurité
- [ ] Mode hors ligne
- [ ] Optimisation des performances (cache)
- [ ] Tests automatisés
- [ ] CI/CD Pipeline

---

## 👥 Auteur

**Chaima Fouzri**

Ce projet a été développé dans le cadre d'une pratique personnelle et d'auto-apprentissage pour améliorer mes compétences en développement mobile, intelligence artificielle, et création d'APIs RESTful. 

C'est un projet éducatif qui combine plusieurs technologies modernes pour créer une solution pratique et innovante.

---

## 📄 Licence

Ce projet est la propriété exclusive de **Chaima Fouzri**.

Tous droits réservés. Ce code source est fourni uniquement à des fins de démonstration et de portfolio. 

**L'utilisation, la copie, la modification ou la distribution de ce code sans autorisation explicite est strictement interdite.**

Pour toute demande d'utilisation, veuillez contacter le propriétaire du projet.

---

## 🙏 Remerciements

- **Groq** pour l'API d'analyse d'images par IA
- **OpenWeatherMap** pour les données météorologiques
- **Flutter** et **FastAPI** pour les frameworks exceptionnels
- La communauté open-source pour les nombreuses bibliothèques utilisées

---

## 📞 Contact

Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue sur le repository.

---

**Bon développement ! 🚀**
