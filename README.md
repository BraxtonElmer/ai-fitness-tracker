# AI Fitness Tracker

An AI-powered health and fitness ecosystem built with Flutter and FastAPI.

## Features

- **Food Photo Recognition** - Upload a photo of any dish and get instant nutrition breakdown including macros and micronutrients
- **Health Connect Integration** - Sync steps, active calories, and sleep data from Android Health Connect
- **Nutrition Insights** - Detailed macro and micronutrient analysis with RDA percentages


## Project Structure

```
├── backend/          # FastAPI Python server
│   ├── main.py       # Gemini vision API integration
│   └── requirements.txt
├── frontend/         # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme.dart
│   │   ├── screens/  # Home, Scan, Result, Dashboard
│   │   └── services/ # API and Health service
│   └── assets/       # Fonts and images
└── assets/           # Shared assets
```

## Getting Started

### Backend

```bash
cd backend
python -m venv venv
./venv/Scripts/pip install -r requirements.txt
cp .env.example .env
# Add your GEMINI_API_KEY to .env
./venv/Scripts/uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd frontend
flutter pub get
# For physical device (replace IP with your machine's LAN IP):
flutter run --dart-define=API_BASE_URL=http://192.168.29.2:8000
# For emulator (uses 10.0.2.2 by default):
flutter run
```

## Tech Stack

- **Backend**: FastAPI, Google Gemini 2.0 Flash, Python
- **Frontend**: Flutter, Dart
- **APIs**: Google Gemini Vision, Android Health Connect
- **Design**: Custom Clash Grotesk typography, minimal dark theme



