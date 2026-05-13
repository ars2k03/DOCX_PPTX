import shutil
import uuid
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.parser import MCQParseError, parse_docx_mcqs
from app.ppt_generator import PPTGenerationError, generate_pptx


BASE_DIR = Path(__file__).resolve().parent.parent
import sys

if getattr(sys, 'frozen', False):
    BASE_DIR = Path(sys._MEIPASS)

UPLOAD_DIR = BASE_DIR / "uploads"
OUTPUT_DIR = BASE_DIR / "outputs"
TEMPLATE_DIR = BASE_DIR / "templates"

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
TEMPLATE_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="MCQ to PPT Generator API",
    version="2.1.0",
    description="Generate MCQ PowerPoint decks from DOCX using one template.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def health_check():
    return {
        "status": "ok",
        "message": "MCQ to PPT backend is running",
    }


@app.post("/api/generate-ppt")
async def generate_ppt(
        file: UploadFile = File(...),
        mcq_count: Optional[int] = Form(None),
        top_no: Optional[int] = Form(None),
):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded.")

    if not file.filename.lower().endswith(".docx"):
        raise HTTPException(status_code=400, detail="Only .docx files are allowed.")

    if mcq_count is not None and (mcq_count < 1 or mcq_count > 500):
        raise HTTPException(
            status_code=400,
            detail="MCQ count must be between 1 and 500.",
        )

    safe_upload_name = f"{uuid.uuid4().hex}.docx"
    upload_path = UPLOAD_DIR / safe_upload_name

    try:
        with upload_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        max_count = mcq_count if mcq_count and mcq_count > 0 else None

        mcqs = parse_docx_mcqs(upload_path, max_count=max_count)

        output_path = generate_pptx(
            mcqs=mcqs,
            template_dir=TEMPLATE_DIR,
            output_dir=OUTPUT_DIR,
        )

        return FileResponse(
            path=str(output_path),
            media_type=(
                "application/vnd.openxmlformats-officedocument."
                "presentationml.presentation"
            ),
            filename=output_path.name,
        )

    except MCQParseError as error:
        raise HTTPException(status_code=422, detail=str(error))

    except PPTGenerationError as error:
        raise HTTPException(status_code=422, detail=str(error))

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(error)}",
        )

    finally:
        try:
            if upload_path.exists():
                upload_path.unlink()
        except Exception:
            pass


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
    )