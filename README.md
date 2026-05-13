# MCQ → PPT Flutter Desktop App

A Flutter Desktop application for generating MCQ PowerPoint presentations from DOCX files.

The app uploads a `.docx` file to a local Python FastAPI backend, parses the MCQs, generates a `.pptx` file, and allows the user to save the generated presentation locally.

---

## Features

- Native Flutter Desktop UI
- DOCX file upload
- MCQ count validation up to 500
- DOCX MCQ parser
- PPTX generator
- Automatic duplicate-slide generation
- Question slide + answer slide output
- Optional 5th option support
- Automatic removal of empty Option E row
- Auto text fitting inside PPT placeholders
- Generated PPTX download/save support

---

## Tech Stack

### Frontend

- Flutter
- Dart

### Backend

- Python
- FastAPI
- python-docx
- python-pptx
- Uvicorn

---

## DOCX Input Format

### English Format

```txt
1. What is the capital of Bangladesh? [RU 22-23]
A. Dhaka
B. Rajshahi
C. Sylhet
D. Khulna
Answer: A
```

### Bangla Format

```txt
1) Question text
ক. Option one
খ. Option two
গ. Option three
ঘ. Option four
উত্তর: ক
```

---

## PPT Template Requirement

The backend requires the following template file:

```txt
backend/templates/template.pptx
```

The template must contain **2 slides**:

```txt
1. Question-only slide
2. Answer-box slide
```

The PPT generator duplicates both template slides for every MCQ.

```txt
1 MCQ    = 2 slides
10 MCQs  = 20 slides
100 MCQs = 200 slides
```

---

## PPT Placeholder Variables

Use the following placeholders inside `template.pptx`:

```txt
{{QUESTION_SOURCE}}
{{QUESTION}}
{{QUESTION_ONLY}}
{{QUESTION_FULL}}

{{OPTION_A}}
{{OPTION_B}}
{{OPTION_C}}
{{OPTION_D}}
{{OPTION_E}}

{{OPTION_A_KEY}}
{{OPTION_B_KEY}}
{{OPTION_C_KEY}}
{{OPTION_D_KEY}}
{{OPTION_E_KEY}}

{{ANSWER_KEY}}
{{ANSWER_TEXT}}

{{OPTION_A_MARK}}
{{OPTION_B_MARK}}
{{OPTION_C_MARK}}
{{OPTION_D_MARK}}
{{OPTION_E_MARK}}

{{OPTION_E_ROW}}
```

---

## Output File Naming

Generated PPTX files are saved using this pattern:

```txt
MCQ_{question_count}Q_{total_slides}Slides_{timestamp}.pptx
```

Example:

```txt
MCQ_10Q_20Slides_1710000000.pptx
```

---

## Important Notes

- Only `.docx` files are supported.
- MCQ count must be between 1 and 500.
- `template.pptx` is required.
- Each MCQ generates 2 slides.
- Option E is optional.
- Empty Option E rows are removed automatically.
- Answer slide shows answer data only when an answer exists.
- Backend currently allows all CORS origins.

---

## License

Educational and productivity use .

---

## Author

Built with Flutter Desktop + FastAPI for fast DOCX MCQ to PPTX generation.