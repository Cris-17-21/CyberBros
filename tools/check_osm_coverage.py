#!/usr/bin/env python3
"""Audit public-transport feature counts in an approximate Lima metro bbox.

Counts are a coverage signal only. They do not prove that a route is complete,
current, or suitable for routing. The default bbox is provisional and can be
overridden once the team fixes its exact geographic boundary.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ENDPOINTS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
)
DEFAULT_BBOX = (-12.35, -77.20, -11.70, -76.65)  # south, west, north, east; provisional


def parse_bbox(value: str) -> tuple[float, float, float, float]:
    try:
        values = tuple(float(part.strip()) for part in value.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError("bbox debe ser south,west,north,east") from exc
    if len(values) != 4:
        raise argparse.ArgumentTypeError("bbox debe tener cuatro valores: south,west,north,east")
    south, west, north, east = values
    if not (-90 <= south < north <= 90 and -180 <= west < east <= 180):
        raise argparse.ArgumentTypeError("bbox inválido: verifica el orden y los rangos")
    return values


def overpass_query(selector: str, bbox: tuple[float, float, float, float]) -> str:
    south, west, north, east = bbox
    return (
        f"[out:json][timeout:20];"
        f"{selector}({south},{west},{north},{east});"
        "out count;"
    )


def fetch_count(query: str, timeout: int = 25) -> dict:
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    errors: list[str] = []
    for endpoint in ENDPOINTS:
        request = urllib.request.Request(
            endpoint,
            data=body,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
                "User-Agent": "Cyberon-Lima-CoverageAudit/0.1 (Hack the Andes project)",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                payload = json.load(response)
            elements = payload.get("elements", [])
            tags = elements[0].get("tags", {}) if elements else {}
            total = tags.get("total")
            if total is None:
                raise ValueError("Overpass no devolvió un total en la respuesta")
            return {"total": int(total), "endpoint": endpoint}
        except (OSError, urllib.error.URLError, urllib.error.HTTPError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"{endpoint}: {exc}")
            time.sleep(0.5)
    raise RuntimeError("No se pudo consultar Overpass. " + " | ".join(errors))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--bbox",
        type=parse_bbox,
        default=DEFAULT_BBOX,
        help="south,west,north,east (default: bbox metropolitano aproximado y provisional)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/reports/osm-lima-coverage.json"),
        help="ruta del informe JSON",
    )
    args = parser.parse_args()

    south, west, north, east = args.bbox
    bbox_text = f"{south},{west},{north},{east}"
    selectors = {
        "bus_route_relations": 'rel["route"~"^(bus|trolleybus)$"]',
        "rail_route_relations": 'rel["route"~"^(subway|train|light_rail|tram)$"]',
        "bus_stop_objects": 'nwr["highway"="bus_stop"]',
        "public_transport_stop_positions": 'nwr["public_transport"="stop_position"]',
        "public_transport_platforms": 'nwr["public_transport"="platform"]',
    }

    results: dict[str, dict] = {}
    failures: list[dict[str, str]] = []
    for name, selector in selectors.items():
        print(f"Consultando {name}…", flush=True)
        try:
            results[name] = fetch_count(overpass_query(selector, args.bbox))
        except Exception as exc:
            failures.append({"category": name, "error": str(exc)})
            break

    report = {
        "status": "complete" if not failures else "incomplete",
        "source": "OpenStreetMap via Overpass API",
        "retrieved_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "bbox_south_west_north_east": bbox_text,
        "bbox_status": "provisional; confirm the metropolitan boundary before claiming full Lima coverage",
        "counts": results,
        "failures": failures,
        "limitations": [
            "Element counts do not establish route completeness or data freshness.",
            "Overlapping OSM tagging can make stop categories overlap; do not sum them as unique stops.",
            "Route geometry, ordered stops, names, fares, and source dates require a separate quality review.",
            "The bbox may include places outside metropolitan Lima and may omit edge areas.",
        ],
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"Informe guardado en {args.output}")
    return 1 if failures else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit("Cancelado.")
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)

