#!/usr/bin/env python3
"""Fetch the ATU geovisor's published SIT route and reference boundary layers."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "data" / "raw" / "atu"
PORTAL = "https://geovisor.atumovilidad.pe/"
FILES = {
    "sit_actual.geojson": f"{PORTAL}data/sit_actual.geojson",
    "distritos.geojson": f"{PORTAL}data/distritos.geojson",
}
MAX_DOWNLOAD_BYTES = 25 * 1024 * 1024


def fetch_file(name: str, url: str) -> dict[str, object]:
    request = Request(
        url,
        headers={"User-Agent": "Cyberon/0.1 (ATU public-data import)"},
    )
    with urlopen(request, timeout=45) as response:
        payload = response.read(MAX_DOWNLOAD_BYTES + 1)
        if len(payload) > MAX_DOWNLOAD_BYTES:
            raise ValueError(f"{name}: exceeds the configured download limit")
        source_last_modified = response.headers.get("Last-Modified")
        content_type = response.headers.get("Content-Type")

    decoded = json.loads(payload.decode("utf-8-sig"))
    if decoded.get("type") != "FeatureCollection" or not isinstance(decoded.get("features"), list):
        raise ValueError(f"{name}: invalid GeoJSON FeatureCollection")

    destination = OUTPUT_DIR / name
    temporary = OUTPUT_DIR / f"{name}.download"
    temporary.write_bytes(payload)
    temporary.replace(destination)
    return {
        "name": name,
        "url": url,
        "sha256": hashlib.sha256(payload).hexdigest(),
        "bytes": len(payload),
        "features": len(decoded["features"]),
        "http_last_modified": source_last_modified,
        "content_type": content_type,
    }


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    files = [fetch_file(name, url) for name, url in FILES.items()]
    manifest = {
        "publisher": "Autoridad de Transporte Urbano para Lima y Callao (ATU)",
        "portal": PORTAL,
        "retrieved_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "portal_statement": "The geovisor states that SIT concession routes were updated in January 2026.",
        "boundary_warning": "The geovisor describes its 2017 INEI census boundaries as referential, not official territorial limits.",
        "files": files,
    }
    (OUTPUT_DIR / "source.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps({item["name"]: item["features"] for item in files}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
