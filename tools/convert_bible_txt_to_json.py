# -*- coding: utf-8 -*-

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INPUT_DIR = ROOT / "data" / "bible_txt"
OUTPUT_FILE = ROOT / "assets" / "bible_full.json"

BOOK_MAP = {
    "창": ("구약", "창세기"),
    "출": ("구약", "출애굽기"),
    "레": ("구약", "레위기"),
    "민": ("구약", "민수기"),
    "신": ("구약", "신명기"),
    "수": ("구약", "여호수아"),
    "삿": ("구약", "사사기"),
    "룻": ("구약", "룻기"),
    "삼상": ("구약", "사무엘상"),
    "삼하": ("구약", "사무엘하"),
    "왕상": ("구약", "열왕기상"),
    "왕하": ("구약", "열왕기하"),
    "대상": ("구약", "역대상"),
    "대하": ("구약", "역대하"),
    "스": ("구약", "에스라"),
    "느": ("구약", "느헤미야"),
    "에": ("구약", "에스더"),
    "욥": ("구약", "욥기"),
    "시": ("구약", "시편"),
    "잠": ("구약", "잠언"),
    "전": ("구약", "전도서"),
    "아": ("구약", "아가"),
    "사": ("구약", "이사야"),
    "렘": ("구약", "예레미야"),
    "애": ("구약", "예레미야애가"),
    "겔": ("구약", "에스겔"),
    "단": ("구약", "다니엘"),
    "호": ("구약", "호세아"),
    "욜": ("구약", "요엘"),
    "암": ("구약", "아모스"),
    "옵": ("구약", "오바댜"),
    "욘": ("구약", "요나"),
    "미": ("구약", "미가"),
    "나": ("구약", "나훔"),
    "합": ("구약", "하박국"),
    "습": ("구약", "스바냐"),
    "학": ("구약", "학개"),
    "슥": ("구약", "스가랴"),
    "말": ("구약", "말라기"),

    "마": ("신약", "마태복음"),
    "막": ("신약", "마가복음"),
    "눅": ("신약", "누가복음"),
    "요": ("신약", "요한복음"),
    "행": ("신약", "사도행전"),
    "롬": ("신약", "로마서"),
    "고전": ("신약", "고린도전서"),
    "고후": ("신약", "고린도후서"),
    "갈": ("신약", "갈라디아서"),
    "엡": ("신약", "에베소서"),
    "빌": ("신약", "빌립보서"),
    "골": ("신약", "골로새서"),
    "살전": ("신약", "데살로니가전서"),
    "살후": ("신약", "데살로니가후서"),
    "딤전": ("신약", "디모데전서"),
    "딤후": ("신약", "디모데후서"),
    "딛": ("신약", "디도서"),
    "몬": ("신약", "빌레몬서"),
    "히": ("신약", "히브리서"),
    "약": ("신약", "야고보서"),
    "벧전": ("신약", "베드로전서"),
    "벧후": ("신약", "베드로후서"),
    "요일": ("신약", "요한일서"),
    "요이": ("신약", "요한이서"),
    "요삼": ("신약", "요한삼서"),
    "유": ("신약", "유다서"),
    "계": ("신약", "요한계시록"),
}

BOOK_ORDER = [
    "창세기", "출애굽기", "레위기", "민수기", "신명기",
    "여호수아", "사사기", "룻기", "사무엘상", "사무엘하",
    "열왕기상", "열왕기하", "역대상", "역대하", "에스라",
    "느헤미야", "에스더", "욥기", "시편", "잠언",
    "전도서", "아가", "이사야", "예레미야", "예레미야애가",
    "에스겔", "다니엘", "호세아", "요엘", "아모스",
    "오바댜", "요나", "미가", "나훔", "하박국",
    "스바냐", "학개", "스가랴", "말라기",
    "마태복음", "마가복음", "누가복음", "요한복음", "사도행전",
    "로마서", "고린도전서", "고린도후서", "갈라디아서", "에베소서",
    "빌립보서", "골로새서", "데살로니가전서", "데살로니가후서",
    "디모데전서", "디모데후서", "디도서", "빌레몬서", "히브리서",
    "야고보서", "베드로전서", "베드로후서", "요한일서", "요한이서",
    "요한삼서", "유다서", "요한계시록",
]

LINE_RE = re.compile(r"^([가-힣]+)(\d+):(\d+)\s+(.*)$")


def read_text_file(path: Path) -> str:
    for encoding in ("utf-8-sig", "utf-8", "cp949", "euc-kr"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError("unknown", b"", 0, 1, f"Cannot decode {path}")


def clean_body(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def main():
    bible = {"구약": {}, "신약": {}}
    unknown_books = set()
    skipped_lines = 0
    parsed_verses = 0

    txt_files = sorted(INPUT_DIR.glob("*.txt"))

    if not txt_files:
        print(f"TXT 파일이 없습니다: {INPUT_DIR}")
        return

    for path in txt_files:
        content = read_text_file(path)

        for line in content.splitlines():
            line = line.strip()
            if not line:
                continue

            match = LINE_RE.match(line)
            if not match:
                skipped_lines += 1
                continue

            abbr, chapter, verse, body = match.groups()

            if abbr not in BOOK_MAP:
                unknown_books.add(abbr)
                continue

            testament, book = BOOK_MAP[abbr]
            body = clean_body(body)

            bible[testament].setdefault(book, {})
            bible[testament][book].setdefault(chapter, {})
            bible[testament][book][chapter][verse] = body
            parsed_verses += 1

    ordered_bible = {"구약": {}, "신약": {}}

    for book in BOOK_ORDER:
        for testament in ("구약", "신약"):
            if book in bible[testament]:
                ordered_bible[testament][book] = bible[testament][book]

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(
        json.dumps(ordered_bible, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"저장 완료: {OUTPUT_FILE}")
    print(f"TXT 파일 수: {len(txt_files)}")
    print(f"변환된 절 수: {parsed_verses}")
    print(f"건너뛴 줄 수: {skipped_lines}")

    if unknown_books:
        print("알 수 없는 약어:")
        for abbr in sorted(unknown_books):
            print(f" - {abbr}")


if __name__ == "__main__":
    main()