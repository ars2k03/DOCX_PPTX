import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from docx import Document


class MCQParseError(Exception):
    pass


OPTION_KEY_MAP = {
    "A": "A", "B": "B", "C": "C", "D": "D", "E": "E",
    "1": "A", "2": "B", "3": "C", "4": "D", "5": "E",
    "১": "A", "২": "B", "৩": "C", "৪": "D", "৫": "E",
    "ক": "A", "খ": "B", "গ": "C", "ঘ": "D", "ঙ": "E",
}

HEADING_LINES = {
    "ENGLISH",
    "BANGLA 1ST",
    "BANGLA 2ND",
    "GENERAL KNOWLEDGE",
    "INTERNATIONAL",
    "EXTRA QUESTIONS",
}

QUESTION_NUMBER_PATTERN = re.compile(r"^\s*[0-9০-৯]+\s*[\.\)\-]\s*")

QUESTION_WITH_TRAILING_SOURCE_PATTERN = re.compile(
    r"^\s*(?:[0-9০-৯]+\s*[\.\)\-]\s*)?(?P<question>.+?)\s*\[(?P<source>[^\]]+)\]\s*$"
)

OPTION_PATTERN = re.compile(
    r"""
    ^\s*
    (?:option\s*)?
    [\(\[]?
    (?P<key>A|B|C|D|E|a|b|c|d|e|1|2|3|4|5|১|২|৩|৪|৫|ক|খ|গ|ঘ|ঙ)
    [\)\]]?
    \s*[\.\)\:\-]\s*
    (?P<value>.*?)
    \s*$
    """,
    re.IGNORECASE | re.VERBOSE,
    )

ANSWER_PATTERN = re.compile(
    r"""
    ^\s*
    (?:
        answer|ans|correct|correct\s+answer|
        উত্তর|উ|সঠিক\s+উত্তর
    )
    \s*[\:\-]\s*
    (?:option\s*)?
    [\(\[]?
    (?P<key>A|B|C|D|E|a|b|c|d|e|1|2|3|4|5|১|২|৩|৪|৫|ক|খ|গ|ঘ|ঙ)
    [\)\]]?
    (?:\s*[\.\)\:\-]\s*.*)?
    \s*$
    """,
    re.IGNORECASE | re.VERBOSE,
    )


def clean_text(text: str) -> str:
    text = text or ""
    text = text.replace("\xa0", " ")
    text = text.replace("\u200b", "")
    text = text.replace("\ufeff", "")
    text = text.replace("‌", "")
    text = re.sub(r"^\s*[​•●▪▫]+\s*", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def split_inline_mcq_line(line: str) -> List[str]:
    line = clean_text(line)

    if not line:
        return []

    line = re.sub(
        r"\s+(?=(?:option\s*)?[\(\[]?(?:A|B|C|D|E|a|b|c|d|e)[\)\]]?\s*[\.\)\:\-]\s+)",
        "\n",
        line,
    )

    line = re.sub(
        r"\s+(?=(?:Answer|Ans|Correct|Correct Answer|উত্তর|উ|সঠিক উত্তর)\s*[\:\-])",
        "\n",
        line,
        flags=re.IGNORECASE,
    )

    return [clean_text(part) for part in line.split("\n") if clean_text(part)]


def remove_question_number(text: str) -> str:
    return QUESTION_NUMBER_PATTERN.sub("", clean_text(text)).strip()


def normalize_option_key(raw_key: str) -> str:
    raw_key = clean_text(raw_key)
    return OPTION_KEY_MAP.get(raw_key.upper(), OPTION_KEY_MAP.get(raw_key, ""))


def is_heading_line(line: str) -> bool:
    line = clean_text(line)

    if not line:
        return True

    # IMPORTANT: option/answer lines must never be treated as headings.
    # Bengali option lines like "A. আওয়াজ" can make str.isupper() return True
    # because Bangla letters are uncased and the only Latin letter is uppercase A/B/C/D.
    if OPTION_PATTERN.match(line) or ANSWER_PATTERN.match(line):
        return False

    normalized = line.upper().strip(" :")
    if normalized in HEADING_LINES:
        return True

    if QUESTION_NUMBER_PATTERN.match(line):
        return False

    # Only pure heading-like English/Bangla section labels should be skipped.
    # Avoid skipping short mixed option text.
    if len(line) <= 35 and line.isupper() and "?" not in line and not re.search(r"^[A-Ea-eকখগঘঙ১-৫]\s*[\.\)\:\-]", line):
        return True

    return False


def parse_option_line(line: str) -> Optional[Tuple[str, str]]:
    match = OPTION_PATTERN.match(clean_text(line))

    if not match:
        return None

    key = normalize_option_key(match.group("key"))
    value = clean_text(match.group("value"))

    if not key:
        return None

    return key, value


def resolve_duplicate_option_key(options: Dict[str, str], option_key: str) -> str:
    """Keep bad DOCX numbering from breaking the last options.

    Example: A, B, B, C should become A, B, C, D.
    """
    if option_key not in options:
        return option_key

    ordered_keys = ["A", "B", "C", "D", "E"]
    try:
        start_index = ordered_keys.index(option_key) + 1
    except ValueError:
        start_index = 0

    for key in ordered_keys[start_index:]:
        if key not in options:
            return key

    for key in ordered_keys:
        if key not in options:
            return key

    return option_key


def parse_answer_line(line: str) -> Optional[str]:
    match = ANSWER_PATTERN.match(clean_text(line))

    if not match:
        return None

    return normalize_option_key(match.group("key"))


def split_question_source(text: str) -> Dict[str, str]:
    text = remove_question_number(clean_text(text))

    trailing = QUESTION_WITH_TRAILING_SOURCE_PATTERN.match(text)
    if trailing:
        return {
            "question_source": clean_text(trailing.group("source")),
            "question": clean_text(trailing.group("question")),
        }

    return {
        "question_source": "",
        "question": text,
    }


def is_question_start(line: str) -> bool:
    line = clean_text(line)
    if not line or is_heading_line(line):
        return False
    if parse_answer_line(line):
        return False
    return bool(QUESTION_NUMBER_PATTERN.match(line))


def read_docx_lines(file_path: str | Path) -> List[str]:
    path = Path(file_path)

    if not path.exists():
        raise MCQParseError(f"File not found: {path}")

    if path.suffix.lower() != ".docx":
        raise MCQParseError("Only .docx files are supported.")

    document = Document(str(path))
    lines: List[str] = []

    for paragraph in document.paragraphs:
        line = clean_text(paragraph.text)
        if line:
            lines.extend(split_inline_mcq_line(line))

    if not lines:
        raise MCQParseError("DOCX file is empty or contains no readable text.")

    return lines


def create_mcq_from_question(line: str) -> Dict:
    parsed = split_question_source(line)

    return {
        "question_source": parsed["question_source"],
        "question": parsed["question"],
        "options": {},
        "answer": "",
    }


def normalize_mcq(current: Dict) -> Dict:
    question = clean_text(current.get("question", ""))
    question_source = clean_text(current.get("question_source", ""))
    options = current.get("options", {})
    answer = clean_text(current.get("answer", "")).upper()

    if not question:
        raise MCQParseError("One MCQ is missing a question.")

    option_a = clean_text(options.get("A", ""))
    option_b = clean_text(options.get("B", ""))
    option_c = clean_text(options.get("C", ""))
    option_d = clean_text(options.get("D", ""))
    option_e = clean_text(options.get("E", ""))

    available_options = {
        "A": option_a,
        "B": option_b,
        "C": option_c,
        "D": option_d,
        "E": option_e,
    }

    if answer not in ["A", "B", "C", "D", "E"]:
        answer = ""

    if answer and not available_options.get(answer):
        answer = ""

    return {
        "question_source": question_source,
        "question": question,
        "option_a": option_a,
        "option_b": option_b,
        "option_c": option_c,
        "option_d": option_d,
        "option_e": option_e,
        "answer": answer,
    }


def mcq_signature(mcq: Dict) -> Tuple[str, str, str, str, str, str]:
    return (
        mcq["question"].lower(),
        mcq["option_a"].lower(),
        mcq["option_b"].lower(),
        mcq["option_c"].lower(),
        mcq["option_d"].lower(),
        mcq["option_e"].lower(),
    )


def finalize_mcq(current: Optional[Dict], mcqs: List[Dict], seen: set) -> None:
    if not current:
        return

    mcq = normalize_mcq(current)
    sig = mcq_signature(mcq)

    if sig in seen:
        return

    seen.add(sig)
    mcqs.append(mcq)


def parse_docx_mcqs(file_path: str | Path, max_count: int | None = None) -> List[Dict]:
    lines = read_docx_lines(file_path)

    mcqs: List[Dict] = []
    seen = set()
    current: Optional[Dict] = None
    last_option: Optional[str] = None
    pending_passage: List[str] = []

    for raw_line in lines:
        line = clean_text(raw_line)

        if not line or is_heading_line(line):
            continue

        if is_question_start(line):
            if current is not None:
                finalize_mcq(current, mcqs, seen)
                if max_count and len(mcqs) >= max_count:
                    return mcqs[:max_count]

            question_line = line
            if pending_passage:
                question_line = f"{' '.join(pending_passage)} {question_line}"
                pending_passage = []

            current = create_mcq_from_question(question_line)
            last_option = None
            continue

        answer_key = parse_answer_line(line)
        if answer_key:
            if current is not None:
                current["answer"] = answer_key
                last_option = None
            continue

        option_data = parse_option_line(line)
        if option_data:
            if current is None:
                continue

            option_key, option_value = option_data
            option_key = resolve_duplicate_option_key(current["options"], option_key)
            current["options"][option_key] = option_value
            last_option = option_key
            continue

        if current is None:
            if line.lower().startswith("read the following passage") or len(line) > 80:
                pending_passage.append(line)
            continue

        if last_option:
            current["options"][last_option] = clean_text(
                current["options"].get(last_option, "") + " " + line
            )
        else:
            current["question"] = clean_text(current["question"] + " " + line)

    if current:
        finalize_mcq(current, mcqs, seen)

    if not mcqs:
        raise MCQParseError("No valid MCQs found in DOCX.")

    if max_count:
        return mcqs[:max_count]

    return mcqs