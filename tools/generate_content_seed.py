#!/usr/bin/env python3
"""
Turn the exported JSON into idempotent seed SQL.

Split by table and batched so each file can be pasted into the Supabase SQL
editor without hitting a statement-size limit. Every insert is an upsert, so
re-running after a re-export applies changes rather than failing on conflicts.

Order matters: diagnoses before cases (cases carry an FK to a slug), cases
before the daily schedule (which carries an FK to a case id).
"""

import json
import pathlib

BATCH = 50
SRC = pathlib.Path("build/content")
OUT = pathlib.Path("supabase/seed")


def q(text: str) -> str:
    """Postgres string literal."""
    return "'" + text.replace("'", "''") + "'"


def arr(items: list[str]) -> str:
    if not items:
        return "'{}'::text[]"
    return "array[" + ", ".join(q(i) for i in items) + "]::text[]"


def batched(rows, size=BATCH):
    for i in range(0, len(rows), size):
        yield rows[i:i + size]


def write(name: str, header: str, statements: list[str]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(header + "\n\n" + "\n\n".join(statements) + "\n")
    print(f"{name}: {len(statements)} statements")


def main() -> None:
    diagnoses = json.loads((SRC / "diagnoses.json").read_text())
    cases = json.loads((SRC / "cases.json").read_text())
    schedule = json.loads((SRC / "daily_schedule.json").read_text())

    # --- diagnoses ---
    stmts = []
    for batch in batched(diagnoses):
        values = ",\n    ".join(
            f"({q(d['slug'])}, {q(d['canonical_name'])}, {arr(d['alternative_names'])}, {q(d['category'])})"
            for d in batch
        )
        stmts.append(
            "insert into public.diagnoses (slug, canonical_name, alternative_names, category) values\n"
            f"    {values}\n"
            "on conflict (slug) do update set\n"
            "    canonical_name    = excluded.canonical_name,\n"
            "    alternative_names = excluded.alternative_names,\n"
            "    category          = excluded.category,\n"
            "    updated_at        = now();"
        )
    write("01_diagnoses.sql",
          "-- Rounds — diagnosis vocabulary (366 rows). Run FIRST: cases reference these slugs.",
          stmts)

    # --- cases ---
    stmts = []
    for offset in range(0, len(cases), BATCH):
        batch = cases[offset:offset + BATCH]
        values = ",\n    ".join(
            "({}, {}, {}, {}, {}, {}, {}, {})".format(
                q(c["id"]), q(c["diagnosis"]),
                q(c["diagnosis_slug"]) if c["diagnosis_slug"] else "null",
                arr(c["alternative_names"]), arr(c["hints"]),
                q(c["category"]), c["difficulty"],
                # sort_order preserves the library's source order, which is the
                # order Browse Cases shows and the order the legacy daily-case
                # pick indexed into.
                offset + n,
            )
            for n, c in enumerate(batch)
        )
        stmts.append(
            "insert into public.cases\n"
            "    (id, diagnosis, diagnosis_slug, alternative_names, hints, category, difficulty, sort_order)\n"
            f"values\n    {values}\n"
            "on conflict (id) do update set\n"
            "    diagnosis         = excluded.diagnosis,\n"
            "    diagnosis_slug    = excluded.diagnosis_slug,\n"
            "    alternative_names = excluded.alternative_names,\n"
            "    hints             = excluded.hints,\n"
            "    category          = excluded.category,\n"
            "    difficulty        = excluded.difficulty,\n"
            "    sort_order        = excluded.sort_order,\n"
            "    updated_at        = now();"
        )
    write("02_cases.sql",
          "-- Rounds — the case library (514 rows).\n"
          "-- ids are imported, never generated: they are what every CaseHistoryEntry points at.",
          stmts)

    # --- daily schedule ---
    stmts = []
    for batch in batched(schedule):
        values = ",\n    ".join(f"({q(s['day'])}, {q(s['case_id'])})" for s in batch)
        stmts.append(
            f"insert into public.daily_cases (day, case_id) values\n    {values}\n"
            "on conflict (day) do nothing;"
        )
    write("03_daily_schedule.sql",
          "-- Rounds — daily case schedule.\n"
          "-- Reproduces the legacy seeded pick exactly, so devices on older builds\n"
          "-- agree with the schedule through the rollout. `do nothing` on conflict:\n"
          "-- a day already scheduled by hand must never be overwritten by a re-run.",
          stmts)


if __name__ == "__main__":
    main()
