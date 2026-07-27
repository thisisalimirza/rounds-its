#!/usr/bin/env python3
"""
Export the hard-coded case library out of Swift and into JSON.

CaseLibrary.swift and DiagnosisRegistry.swift are hand-written Swift literals —
308KB and 84KB of them. This parses those literals directly rather than asking
anyone to retype them, so the export can be re-run and diffed if the Swift
files change again before the cutover.

Two things it must get exactly right, or user history detaches from the cases
it points at:

  * The case id. MedicalCase.deterministicID is sha256("rounds.case." +
    diagnosis.lowercased().trimmed), first 16 bytes used raw as a UUID — no
    version or variant bits. Reproduced here byte for byte.
  * The hint padding. The MedicalCase initializer pads short hint lists to five
    and truncates long ones, so the stored case differs from the literal.
    Replicated here so the server holds what the app actually plays.

Usage:  python3 tools/export_case_library.py [--out DIR]
"""

import argparse
import datetime
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter

HINT_PADDING = "Additional clue coming soon"
HINT_COUNT = 5


def deterministic_id(diagnosis: str) -> str:
    """Mirror of MedicalCase.deterministicID."""
    normalized = diagnosis.lower().strip()
    digest = hashlib.sha256(f"rounds.case.{normalized}".encode("utf-8")).digest()
    h = digest[:16].hex()
    return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


# --- Swift literal parsing -------------------------------------------------

def _scan_call(text: str, start: int) -> tuple[str, int]:
    """Return the contents of the parenthesised call beginning at `start`."""
    depth = 0
    i = start
    in_string = False
    while i < len(text):
        c = text[i]
        if in_string:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_string = False
        elif c == '"':
            in_string = True
        elif c == "(":
            depth += 1
            if depth == 1:
                open_at = i
        elif c == ")":
            depth -= 1
            if depth == 0:
                return text[open_at + 1:i], i + 1
        i += 1
    raise ValueError(f"unterminated call at offset {start}")


def find_calls(text: str, name: str) -> list[str]:
    """Every `Name(...)` call body in source order."""
    bodies = []
    for match in re.finditer(rf"\b{name}\s*\(", text):
        body, _ = _scan_call(text, match.start())
        bodies.append(body)
    return bodies


def _split_top_level(text: str) -> list[str]:
    """Split on commas that aren't inside strings, brackets or parens."""
    parts, depth, buf, in_string = [], 0, [], False
    i = 0
    while i < len(text):
        c = text[i]
        if in_string:
            buf.append(c)
            if c == "\\":
                buf.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
        elif c == '"':
            in_string = True
            buf.append(c)
        elif c in "([{":
            depth += 1
            buf.append(c)
        elif c in ")]}":
            depth -= 1
            buf.append(c)
        elif c == "," and depth == 0:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    if "".join(buf).strip():
        parts.append("".join(buf))
    return [p.strip() for p in parts]


_ESCAPES = {'"': '"', "\\": "\\", "n": "\n", "t": "\t", "r": "\r", "0": "\0", "'": "'"}


def _swift_string(literal: str) -> str:
    literal = literal.strip()
    if not (literal.startswith('"') and literal.endswith('"')):
        raise ValueError(f"not a string literal: {literal[:60]!r}")
    if "\\(" in literal:
        raise ValueError(f"string interpolation is not supported: {literal[:60]!r}")
    body, out, i = literal[1:-1], [], 0
    while i < len(body):
        c = body[i]
        if c == "\\":
            nxt = body[i + 1]
            if nxt == "u":                      # \u{1F600}
                end = body.index("}", i)
                out.append(chr(int(body[i + 3:end], 16)))
                i = end + 1
                continue
            out.append(_ESCAPES.get(nxt, nxt))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _value(raw: str):
    raw = raw.strip()
    if raw == "nil":
        return None
    if raw.startswith("["):
        inner = raw[1:-1].strip()
        return [] if not inner else [_swift_string(p) for p in _split_top_level(inner)]
    if raw.startswith('"'):
        return _swift_string(raw)
    return int(raw)


def parse_args(body: str) -> dict:
    args = {}
    for part in _split_top_level(body):
        if not part.strip():
            continue
        label, _, raw = part.partition(":")
        args[label.strip()] = _value(raw)
    return args


# --- Export ----------------------------------------------------------------

def export_cases(source: str) -> list[dict]:
    cases = []
    for body in find_calls(source, "MedicalCase"):
        a = parse_args(body)
        if "diagnosis" not in a or "hints" not in a:
            continue                              # previews, helpers, not library entries

        hints = list(a["hints"])
        if len(hints) < HINT_COUNT:
            hints += [HINT_PADDING] * (HINT_COUNT - len(hints))
        hints = hints[:HINT_COUNT]

        cases.append({
            "id": deterministic_id(a["diagnosis"]),
            "diagnosis": a["diagnosis"],
            "diagnosis_slug": a.get("diagnosisSlug"),
            "alternative_names": a.get("alternativeNames") or [],
            "hints": hints,
            "category": a.get("category", ""),
            "difficulty": max(1, min(5, a.get("difficulty", 3))),
        })
    return cases


def export_diagnoses(source: str) -> list[dict]:
    out = []
    for body in find_calls(source, "DiagnosisDefinition"):
        a = parse_args(body)
        if "id" not in a or "canonicalName" not in a:
            continue
        out.append({
            "slug": a["id"],
            "canonical_name": a["canonicalName"],
            "alternative_names": a.get("alternativeNames") or [],
            "category": a.get("category", ""),
        })
    return out


# --- Daily schedule --------------------------------------------------------

def legacy_daily_index(day, count: int) -> int:
    """What ContentView.startNewGame would pick for `day`.

    Reproduces three things exactly:
      * the seed, YYYYMMDD as an integer;
      * SeededRandomNumberGenerator, an LCG with the Knuth/MMIX constants;
      * Swift's RandomNumberGenerator.next(upperBound:), which uses Lemire's
        nearly-divisionless method and returns the HIGH word of a full-width
        multiply — NOT `next() % count`, which lands somewhere else entirely.

    Verified against a real device: 2026-07-26 gives index 1, Multiple
    Sclerosis, which is what the app showed.

    The rejection branch of Lemire's method is omitted deliberately. It only
    triggers when the low word falls under (2^64 mod count) — about a 1-in-10^17
    chance per draw — and reproducing it would require guessing more stdlib
    internals than it is worth. If a generated schedule ever disagrees with a
    device, that is the first place to look.
    """
    seed = day.year * 10000 + day.month * 100 + day.day
    state = (seed * 6364136223846793005 + 1442695040888963407) & ((1 << 64) - 1)
    return (state * count) >> 64


def export_schedule(cases: list[dict], start, days: int) -> list[dict]:
    return [
        {
            "day": (start + datetime.timedelta(days=i)).isoformat(),
            "case_id": cases[legacy_daily_index(start + datetime.timedelta(days=i), len(cases))]["id"],
            "diagnosis": cases[legacy_daily_index(start + datetime.timedelta(days=i), len(cases))]["diagnosis"],
        }
        for i in range(days)
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", type=pathlib.Path)
    ap.add_argument("--out", default="build/content", type=pathlib.Path)
    ap.add_argument("--schedule-days", default=180, type=int,
                    help="Days of daily-case schedule to generate, matching the legacy algorithm.")
    ap.add_argument("--schedule-from", default=None,
                    help="ISO date to start the schedule (default: today).")
    args = ap.parse_args()

    cases = export_cases((args.root / "Rounds/CaseLibrary.swift").read_text())
    diagnoses = export_diagnoses((args.root / "Rounds/DiagnosisRegistry.swift").read_text())

    problems = []

    # A duplicate diagnosis name is fatal, not cosmetic: ids are derived from
    # the name, so two such cases are literally the same row and one would
    # silently overwrite the other on import.
    for name, n in Counter(c["diagnosis"].lower().strip() for c in cases).items():
        if n > 1:
            problems.append(f"duplicate diagnosis {name!r} appears {n}x — ids collide")

    for slug, n in Counter(d["slug"] for d in diagnoses).items():
        if n > 1:
            problems.append(f"duplicate diagnosis slug {slug!r} appears {n}x")

    slugs = {d["slug"] for d in diagnoses}
    for c in cases:
        if c["diagnosis_slug"] and c["diagnosis_slug"] not in slugs:
            problems.append(f"case {c['diagnosis']!r} references unknown slug {c['diagnosis_slug']!r}")

    # Matching is what makes a case playable. A case whose name reaches no
    # registry entry falls back to exact-name comparison only.
    by_name = {d["canonical_name"].lower().strip() for d in diagnoses}
    unmatched = [c["diagnosis"] for c in cases
                 if not c["diagnosis_slug"] and c["diagnosis"].lower().strip() not in by_name]

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "cases.json").write_text(json.dumps(cases, indent=2, ensure_ascii=False))
    (args.out / "diagnoses.json").write_text(json.dumps(diagnoses, indent=2, ensure_ascii=False))

    start = (datetime.date.fromisoformat(args.schedule_from) if args.schedule_from
             else datetime.date.today())
    schedule = export_schedule(cases, start, args.schedule_days)
    (args.out / "daily_schedule.json").write_text(json.dumps(schedule, indent=2, ensure_ascii=False))

    print(f"cases      {len(cases)}")
    print(f"schedule   {len(schedule)} days from {schedule[0]['day']} ({schedule[0]['diagnosis']})")
    print(f"diagnoses  {len(diagnoses)}")
    print(f"categories {len({c['category'] for c in cases})}")
    print(f"no registry match: {len(unmatched)}")
    for name in unmatched[:15]:
        print(f"   - {name}")
    if len(unmatched) > 15:
        print(f"   ... and {len(unmatched) - 15} more")

    for p in problems:
        print(f"FATAL: {p}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
