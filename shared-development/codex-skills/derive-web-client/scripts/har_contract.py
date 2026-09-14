#!/usr/bin/env python3
"""Create a credential-free, deterministic HTTP contract from a HAR file."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import OrderedDict
from pathlib import Path
from urllib.parse import parse_qsl, urlsplit


SENSITIVE_HEADER = re.compile(
    r"^(authorization|cookie|set-cookie|proxy-authorization|x-(?:api-key|csrf|xsrf|auth(?:entication)?-token)|csrf-token)$",
    re.IGNORECASE,
)
SENSITIVE_QUERY = re.compile(
    r"(?:token|secret|password|pass|key|signature|sig|auth|session|cookie|code)$",
    re.IGNORECASE,
)
SAFE_HEADERS = {"accept", "accept-language", "content-type"}


def operation_name(method: str, path: str) -> str:
    parts = [part for part in path.split("/") if part]
    words = [method.lower()] + [re.sub(r"[^a-zA-Z0-9]+", " ", part).title().replace(" ", "") for part in parts]
    name = "".join(words) or method.lower()
    return name[:96]


def normalise_headers(headers: object) -> list[dict[str, str]]:
    safe: list[dict[str, str]] = []
    for header in headers if isinstance(headers, list) else []:
        if not isinstance(header, dict):
            continue
        name = str(header.get("name", "")).strip()
        value = str(header.get("value", "")).strip()
        if name and value and name.lower() in SAFE_HEADERS and not SENSITIVE_HEADER.match(name):
            safe.append({"name": name.lower(), "value": value})
    return sorted(safe, key=lambda item: (item["name"], item["value"]))


def entry_contract(entry: object) -> dict[str, object] | None:
    if not isinstance(entry, dict) or not isinstance(entry.get("request"), dict):
        return None
    request = entry["request"]
    url = str(request.get("url", ""))
    parsed = urlsplit(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return None
    method = str(request.get("method", "GET")).upper()
    query_keys = sorted(
        {key for key, _ in parse_qsl(parsed.query, keep_blank_values=True) if not SENSITIVE_QUERY.search(key)}
    )
    post_data = request.get("postData") if isinstance(request.get("postData"), dict) else {}
    response = entry.get("response") if isinstance(entry.get("response"), dict) else {}
    response_content = response.get("content") if isinstance(response.get("content"), dict) else {}
    return {
        "name": operation_name(method, parsed.path),
        "method": method,
        "origin": f"{parsed.scheme}://{parsed.netloc}",
        "path": parsed.path or "/",
        "queryKeys": query_keys,
        "requestHeaders": normalise_headers(request.get("headers")),
        "requestMimeType": str(post_data.get("mimeType", "")),
        "responseStatus": int(response.get("status", 0) or 0),
        "responseMimeType": str(response_content.get("mimeType", "")),
    }


def signature(operation: dict[str, object]) -> tuple[object, ...]:
    return (
        operation["method"], operation["origin"], operation["path"],
        tuple(operation["queryKeys"]), operation["requestMimeType"],
    )


def build_contract(payload: object, source_name: str) -> dict[str, object]:
    log = payload.get("log") if isinstance(payload, dict) else None
    entries = log.get("entries") if isinstance(log, dict) else None
    if not isinstance(entries, list):
        raise ValueError("Expected a HAR 1.2 object with log.entries")

    unique: OrderedDict[tuple[object, ...], dict[str, object]] = OrderedDict()
    for entry in entries:
        operation = entry_contract(entry)
        if operation is None:
            continue
        key = signature(operation)
        if key in unique:
            unique[key]["occurrences"] = int(unique[key]["occurrences"]) + 1
        else:
            operation["occurrences"] = 1
            unique[key] = operation

    operations = sorted(unique.values(), key=lambda item: signature(item))
    names: dict[str, int] = {}
    for operation in operations:
        base = str(operation["name"])
        names[base] = names.get(base, 0) + 1
        if names[base] > 1:
            operation["name"] = f"{base}{names[base]}"
    return {"version": 1, "source": source_name, "operations": operations}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--har", required=True, type=Path, help="input HAR file")
    parser.add_argument("--out", required=True, type=Path, help="credential-free JSON contract")
    args = parser.parse_args()
    try:
        payload = json.loads(args.har.read_text(encoding="utf-8"))
        contract = build_contract(payload, args.har.name)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"har_contract: {error}", file=sys.stderr)
        return 1
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(contract, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {len(contract['operations'])} operations to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
