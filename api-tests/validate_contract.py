#!/usr/bin/env python3
"""Проверка OpenAPI-контракта AI Fitness Coach.

Запуск из корня репозитория AI-Coach-backend:
    python api-tests/validate_contract.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "openapi" / "openapi.yaml"


def resolve_ref(spec: dict, ref: str):
    node = spec
    for part in ref.lstrip("#/").split("/"):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


def main() -> int:
    with SPEC_PATH.open(encoding="utf-8") as fh:
        spec = yaml.safe_load(fh)

    operations = []
    for path, item in spec.get("paths", {}).items():
        for method, op in item.items():
            if method.lower() in {"get", "post", "put", "delete", "patch"}:
                operations.append((method.upper(), path, op))

    operation_ids = [op.get("operationId") for _, _, op in operations]
    unique_ids = len(operation_ids) == len(set(operation_ids)) and all(operation_ids)

    text = SPEC_PATH.read_text(encoding="utf-8")
    refs = set(re.findall(r'\$ref: "#([^"]+)"', text))
    missing_refs = sorted(ref for ref in refs if resolve_ref(spec, ref) is None)

    missing_body = [
        f"{method} {path}"
        for method, path, op in operations
        if method in {"POST", "PUT"} and "requestBody" not in op
    ]

    missing_success = [
        f"{method} {path}"
        for method, path, op in operations
        if not any(str(code).startswith("2") for code in op.get("responses", {}))
    ]

    print(
        f"paths={len(spec.get('paths', {}))} operations={len(operations)} "
        f"unique_operation_ids={unique_ids} refs={len(refs)} missing_refs={len(missing_refs)}"
    )
    print(f"POST/PUT without requestBody: {missing_body}")
    if missing_refs:
        print(f"Missing refs: {missing_refs}")
    if missing_success:
        print(f"Operations without 2xx response: {missing_success}")

    ok = unique_ids and not missing_refs and not missing_body and not missing_success
    if ok:
        print("OpenAPI contract checks passed")
        return 0
    print("OpenAPI contract checks failed")
    return 1


if __name__ == "__main__":
    sys.exit(main())
