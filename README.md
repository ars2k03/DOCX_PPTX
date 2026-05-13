# 🧠 MCQ to PPTX Flutter Desktop App

A Flutter Desktop application that converts MCQ-based DOCX files into PowerPoint presentations using a local Python FastAPI backend.

The app uploads a `.docx` file to the backend, parses MCQs, generates a `.pptx` file, and allows the user to save the generated presentation locally.

---

## ✨ Features

- 🖥️ Native Flutter Desktop UI
- 📄 DOCX file upload
- 🔢 MCQ count validation up to 500
- 🧠 DOCX MCQ parser
- 🎞️ PPTX generator
- 🔁 Automatic duplicate-slide generation
- ❓ Question slide + ✅ Answer slide output
- ➕ Optional 5th option support
- 🧹 Automatic removal of empty Option E row
- 📐 Auto text fitting inside PPT placeholders
- 💾 Generated PPTX download/save support

---

## 🧰 Tech Stack

### 🎨 Frontend

- Flutter
- Dart

### ⚙️ Backend

- Python
- FastAPI
- python-docx
- python-pptx
- Uvicorn

---

## 📄 DOCX Input Format

### 🇬🇧 English Format

```txt
1. What is the capital of Bangladesh? [RU 22-23]
A. Dhaka
B. Rajshahi
C. Sylhet
D. Khulna
Answer: A
```

### 🇧🇩 Bangla Format

```txt
1) Question text
ক. Option one
খ. Option two
গ. Option three
ঘ. Option four
উত্তর: ক
```

---

## 🧪 Demo / Test File

A sample DOCX file is included for quick testing and validation of the app.

```txt
demo/RUET 24-25 shift 3 4.docx
```

## 🎨 PPT Template Requirement

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


## ⚠️ Important Notes

- 📄 Only `.docx` files are supported.
- 🔢 MCQ count must be between 1 and 500.
- 🎨 `template.pptx` is required.
- 🎞️ Each MCQ generates 2 slides.
- ➕ Option E is optional.
- 🧹 Empty Option E rows are removed automatically.
- ✅ Answer slide shows answer data only when an answer exists.
- 🌐 Backend currently allows all CORS origins.

---

## 📜 License

Educational and productivity use only.

---

## 👨‍💻 Author

Developed by **ARS**.

---

## © Copyright

**Copyright © 2026 ARS. All rights reserved.**
