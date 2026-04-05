import os
import io
import re
import json
import traceback

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from PIL import Image
from google import genai
from google.genai import types

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY is not set in .env file")

client = genai.Client(api_key=GEMINI_API_KEY)

app = FastAPI(title="FitCore AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

NUTRITION_PROMPT = """You are an expert nutritionist specializing in Indian cuisine. Analyze the food in this image and return ONLY a valid JSON object with no extra text, no markdown, no backticks.

The JSON must follow this exact structure:
{
  "dish_name": "Name of the dish",
  "confidence": "high" or "medium" or "low",
  "serving_size": "Estimated serving size as plain text",
  "calories": number,
  "macros": {
    "protein_g": number,
    "carbs_g": number,
    "fats_g": number,
    "fiber_g": number
  },
  "micros": {
    "iron_mg": number,
    "calcium_mg": number,
    "vitamin_c_mg": number,
    "vitamin_b12_mcg": number,
    "sodium_mg": number
  },
  "health_note": "A single helpful sentence about this dish"
}

If you cannot identify the food, return:
{
  "dish_name": "Unknown",
  "confidence": "low",
  "serving_size": "Unknown",
  "calories": 0,
  "macros": {"protein_g": 0, "carbs_g": 0, "fats_g": 0, "fiber_g": 0},
  "micros": {"iron_mg": 0, "calcium_mg": 0, "vitamin_c_mg": 0, "vitamin_b12_mcg": 0, "sodium_mg": 0},
  "health_note": "Could not identify the food in the image."
}

Return ONLY the JSON object. No other text."""

ALLOWED_FORMATS = {"JPEG", "PNG", "GIF", "BMP", "WEBP", "TIFF"}


def clean_gemini_response(text: str) -> str:
    """Strip whitespace and remove accidental markdown code fences."""
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text)
    text = re.sub(r"\s*```$", "", text)
    return text.strip()


@app.post("/analyze")
async def analyze_food(file: UploadFile = File(...)):
    try:
        contents = await file.read()

        # Validate that the upload is an actual image
        try:
            img = Image.open(io.BytesIO(contents))
            img_format = img.format
            if img_format not in ALLOWED_FORMATS:
                return JSONResponse(
                    status_code=400,
                    content={
                        "success": False,
                        "message": f"Unsupported image format: {img_format}. Allowed: {', '.join(ALLOWED_FORMATS)}",
                    },
                )
        except Exception:
            return JSONResponse(
                status_code=400,
                content={
                    "success": False,
                    "message": "The uploaded file is not a valid image.",
                },
            )

        # Determine MIME type for Gemini
        mime_map = {
            "JPEG": "image/jpeg",
            "PNG": "image/png",
            "GIF": "image/gif",
            "BMP": "image/bmp",
            "WEBP": "image/webp",
            "TIFF": "image/tiff",
        }
        mime_type = mime_map.get(img_format, "image/jpeg")

        # Build the image part for Gemini
        image_part = types.Part.from_bytes(data=contents, mime_type=mime_type)

        # Call Gemini
        try:
            response = client.models.generate_content(
                model="gemini-flash-latest",
                contents=[NUTRITION_PROMPT, image_part],
            )
        except Exception:
            return JSONResponse(
                status_code=502,
                content={
                    "success": False,
                    "message": "Failed to get a response from the AI model. Please try again.",
                },
            )

        # Parse response
        raw_text = response.text
        cleaned = clean_gemini_response(raw_text)

        try:
            nutrition_data = json.loads(cleaned)
        except json.JSONDecodeError:
            return JSONResponse(
                status_code=502,
                content={
                    "success": False,
                    "message": "The AI returned an unreadable response. Please try again with a clearer photo.",
                },
            )

        return JSONResponse(
            status_code=200,
            content={
                "success": True,
                "data": nutrition_data,
            },
        )

    except HTTPException:
        raise
    except Exception:
        traceback.print_exc()
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "An unexpected error occurred. Please try again.",
            },
        )


@app.get("/health")
async def health_check():
    return {"status": "ok"}
