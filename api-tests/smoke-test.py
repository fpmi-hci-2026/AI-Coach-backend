#!/usr/bin/env python3
"""Smoke-тесты AI Fitness Coach API (Prism mock или реальный backend).

Запуск из корня репозитория AI-Coach-backend:
    python api-tests/smoke-test.py
    python api-tests/smoke-test.py --base-url http://localhost:8000
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbm5hQGV4YW1wbGUuY29tIn0.signature"


def request(base: str, method: str, path: str, body=None, form=None, auth=False):
    url = base + path
    data = None
    headers = {"Accept": "application/json", "X-Request-ID": "smoke-test"}
    if form is not None:
        data = urllib.parse.urlencode(form).encode("utf-8")
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif body is not None:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if auth:
        headers["Authorization"] = f"Bearer {TOKEN}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", errors="replace")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://localhost:4010")
    args = parser.parse_args()
    base = args.base_url.rstrip("/")
    print(f"Base URL: {base}")

    cases = [
        ("health", "GET", "/health", None, None, False, 200),
        ("form-data", "GET", "/api/workouts/form-data", None, None, False, 200),
        (
            "register",
            "POST",
            "/api/users/register",
            {"name": "Анна", "email": "anna@example.com", "password": "Password123!"},
            None,
            False,
            201,
        ),
        (
            "login",
            "POST",
            "/api/users/login",
            None,
            {"username": "anna@example.com", "password": "Password123!"},
            False,
            200,
        ),
        ("me", "GET", "/api/users/me", None, None, True, 200),
        (
            "generate",
            "POST",
            "/api/workouts/generate",
            {
                "target_muscles": ["Quadriceps", "Glutes"],
                "duration": 45,
                "user_level_str": "Intermediate",
                "equipment": ["Body Only", "Dumbbell"],
                "injuries": ["Spine (Позвоночник)"],
            },
            None,
            True,
            200,
        ),
        (
            "feedback",
            "POST",
            "/api/workouts/feedback",
            {"workout_item_id": 101, "rating": 8, "difficulty": "normal"},
            None,
            True,
            200,
        ),
        ("history", "GET", "/api/workouts/history?skip=0&limit=10", None, None, True, 200),
        ("catalog", "GET", "/api/exercises?body_part=Quadriceps&limit=5", None, None, False, 200),
        ("admin-injuries", "GET", "/api/admin/injuries", None, None, True, 200),
        (
            "admin-create-injury",
            "POST",
            "/api/admin/injuries",
            {"name": "Кифоз", "word": "Spine_Load"},
            None,
            True,
            201,
        ),
        (
            "admin-settings",
            "PUT",
            "/api/admin/settings/1",
            {
                "name": "Профиль для зала",
                "weight_body": 0.7,
                "weight_equip": 0.2,
                "weight_level": 0.5,
                "is_active": True,
            },
            None,
            True,
            200,
        ),
        ("admin-audit", "GET", "/api/admin/audit-log?limit=20", None, None, True, 200),
        (
            "invalid-generate",
            "POST",
            "/api/workouts/generate",
            {"target_muscles": [], "duration": 20, "user_level_str": "Beginner"},
            None,
            True,
            422,
        ),
    ]

    passed = 0
    failed = 0
    for name, method, path, body, form, auth, expected in cases:
        code, payload = request(base, method, path, body=body, form=form, auth=auth)
        ok = code == expected
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {method:6} {path:45} {name:22} -> {code} (expected {expected})")
        if not ok:
            print("       " + payload[:500])
            failed += 1
        else:
            passed += 1

    print(f"\nИтого: PASS={passed}, FAIL={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
