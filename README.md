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
```

**Standalone food scan (no laptop server)** — the app calls Gemini from the device. Pass your API key at build/run time:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
# Optional: different model (default in app is gemini-2.5-flash)
flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=GEMINI_MODEL=gemini-2.5-flash-lite
```

**“Quota”, “ResourceExhausted”, or `limit: 0` in errors:** That usually means the project tied to your API key has **no free-tier quota** for that model (or **2.0 Flash** is not available for free anymore). The app now defaults to **`gemini-2.5-flash`**. In [Google Cloud Console](https://console.cloud.google.com) for the same project as your key: link a **billing account** (free usage can still be \$0; many accounts need billing linked for Generative Language API quotas to activate), and ensure the **Generative Language API** is enabled. If it still fails, try `GEMINI_MODEL=gemini-2.5-flash-lite` for a higher free-tier request cap. See [rate limits](https://ai.google.dev/gemini-api/docs/rate-limits).

**With the FastAPI backend** (local development) — omit `GEMINI_API_KEY` and point the app at your machine:

- **Android emulator** (default `API_BASE_URL` is `http://10.0.2.2:8000`):

  ```bash
  flutter run
  ```

- **Physical device** (use your computer’s LAN IP, same Wi‑Fi as the phone):

  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000
  ```

## Tech Stack

- **Backend**: FastAPI, Google Gemini 2.5 Flash, Python
- **Frontend**: Flutter, Dart
- **APIs**: Google Gemini Vision, Android Health Connect
- **Design**: Custom Clash Grotesk typography, minimal dark theme



