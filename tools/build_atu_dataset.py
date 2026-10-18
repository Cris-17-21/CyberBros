#!/usr/bin/env python3
"""Validate ATU's published SIT geometries and build the Flutter map asset.

This is a route-geometry dataset. It has no stop order, fares or timetables, so
the planner must not infer a ride from these lines alone.
"""

from __future__ import annotations

import collections
import hashlib
import json
import math
from pathlib import Path
from typing import Any, Iterable

from shapely.geometry import shape


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw" / "atu"
ASSET = ROOT / "app" / "cyber_bros" / "assets" / "data" / "atu_sit_routes.json"
REPORT = ROOT / "data" / "reports" / "atu-sit-coverage.json"
MIN_DISTRICT_ROUTE_METRES = 100


def read_verified_geojson(name: str, manifest: dict[str, Any]) -> dict[str, Any]:
    file_entry = next((item for item in manifest["files"] if item["name"] == name), None)
    if file_entry is None:
        raise ValueError(f"Source manifest is missing {name}")
    payload = (RAW / name).read_bytes()
    actual_hash = hashlib.sha256(payload).hexdigest()
    if actual_hash != file_entry["sha256"]:
        raise ValueError(f"SHA256 mismatch for {name}; fetch sources again")
    data = json.loads(payload.decode("utf-8-sig"))
    if data.get("type") != "FeatureCollection" or not isinstance(data.get("features"), list):
        raise ValueError(f"{name} is not a GeoJSON FeatureCollection")
    return data


def haversine_metres(first: tuple[float, float], second: tuple[float, float]) -> float:
    lon1, lat1 = first
    lon2, lat2 = second
    rlat1, rlat2 = math.radians(lat1), math.radians(lat2)
    dlat = rlat2 - rlat1
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlon / 2) ** 2
    return 2 * 6371008.8 * math.asin(min(1.0, math.sqrt(a)))


def line_length_metres(geometry: Any) -> float:
    if geometry.is_empty:
        return 0.0
    if geometry.geom_type in {"LineString", "LinearRing"}:
        coords = list(geometry.coords)
        return sum(
            haversine_metres((a[0], a[1]), (b[0], b[1]))
            for a, b in zip(coords, coords[1:])
        )
    if hasattr(geometry, "geoms"):
        return sum(line_length_metres(part) for part in geometry.geoms)
    return 0.0


def clean_segments(raw_segments: Iterable[list[list[float]]]) -> list[list[list[float]]]:
    segments: list[list[list[float]]] = []
    for raw_segment in raw_segments:
        segment: list[list[float]] = []
        for coordinate in raw_segment:
            if len(coordinate) < 2:
                raise ValueError("A route coordinate has fewer than two dimensions")
            longitude, latitude = coordinate[:2]
            if not (
                isinstance(longitude, (int, float))
                and isinstance(latitude, (int, float))
                and math.isfinite(longitude)
                and math.isfinite(latitude)
                and -180 <= longitude <= 180
                and -90 <= latitude <= 90
            ):
                raise ValueError("A route has invalid longitude or latitude")
            point = [round(float(longitude), 6), round(float(latitude), 6)]
            if not segment or point != segment[-1]:
                segment.append(point)
        if len(segment) < 2:
            raise ValueError("A route segment has fewer than two distinct points")
        segments.append(segment)
    if not segments:
        raise ValueError("A route has no segments")
    return segments


def service_name(source_label: str) -> str:
    lowered = source_label.lower()
    if "corredor rojo" in lowered:
        return "Corredor Rojo"
    if "corredore azul" in lowered or "corredor azul" in lowered:
        return "Corredor Azul"
    if "corredor morado" in lowered:
        return "Corredor Morado"
    if "lima" in lowered and "2" in lowered:
        return "Metro de Lima · Línea 2"
    if "lima" in lowered and "1" in lowered:
        return "Metro de Lima · Línea 1"
    if "metropolitano" in lowered:
        return "Metropolitano"
    return source_label


def main() -> int:
    manifest = json.loads((RAW / "source.json").read_text(encoding="utf-8"))
    routes_source = read_verified_geojson("sit_actual.geojson", manifest)
    districts_source = read_verified_geojson("distritos.geojson", manifest)

    routes: list[dict[str, Any]] = []
    route_shapes = []
    seen_ids: set[int] = set()
    services = collections.Counter()
    bbox = [180.0, 90.0, -180.0, -90.0]

    for feature in routes_source["features"]:
        properties = feature.get("properties") or {}
        feature_id = properties.get("fid")
        if not isinstance(feature_id, int) or feature_id in seen_ids:
            raise ValueError(f"Missing or duplicate ATU route fid: {feature_id}")
        seen_ids.add(feature_id)
        geometry = feature.get("geometry") or {}
        if geometry.get("type") != "MultiLineString":
            raise ValueError(f"ATU route {feature_id} is not a MultiLineString")
        clean = clean_segments(geometry.get("coordinates") or [])
        line = shape({"type": "MultiLineString", "coordinates": clean})
        if not line.is_valid or line.is_empty:
            raise ValueError(f"ATU route {feature_id} has invalid geometry")
        route_shapes.append(line)

        original_label = str(properties.get("servicio") or "").strip()
        if not original_label:
            raise ValueError(f"ATU route {feature_id} has no service label")
        service = service_name(original_label)
        services[service] += 1
        code = str(properties["ruta"]).strip() if properties.get("ruta") is not None else None
        if code == "":
            code = None
        name = f"{service} {code}" if code else service
        for segment in clean:
            for longitude, latitude in segment:
                bbox[0] = min(bbox[0], longitude)
                bbox[1] = min(bbox[1], latitude)
                bbox[2] = max(bbox[2], longitude)
                bbox[3] = max(bbox[3], latitude)

        routes.append(
            {
                "id": f"atu:sit:{feature_id}",
                "name": name,
                "code": code,
                "service": service,
                "direction": properties.get("sentido"),
                "source_label": original_label,
                "length_metres": round(line_length_metres(line)),
                "geometry": {"type": "MultiLineString", "coordinates": clean},
                "data_quality": {
                    "geometry": "published_by_atu",
                    "stop_sequence": "unavailable",
                    "fare": "unavailable",
                    "schedule": "unavailable",
                    "realtime": False,
                },
            }
        )

    districts: list[tuple[str, str, Any]] = []
    for feature in districts_source["features"]:
        properties = feature.get("properties") or {}
        province = str(properties.get("nombdep") or "").upper()
        name = str(properties.get("nombre") or "").upper()
        polygon = shape(feature.get("geometry"))
        if not province or not name or polygon.is_empty:
            raise ValueError("The ATU reference boundaries contain an invalid district")
        districts.append((province, name, polygon))

    covered_lima = []
    uncovered_lima = []
    for province, name, polygon in districts:
        if province != "LIMA":
            continue
        route_metres = sum(line_length_metres(line.intersection(polygon)) for line in route_shapes)
        target = covered_lima if route_metres >= MIN_DISTRICT_ROUTE_METRES else uncovered_lima
        target.append({"name": name, "published_route_metres": round(route_metres)})

    source_entry = next(item for item in manifest["files"] if item["name"] == "sit_actual.geojson")
    dataset_id = f"atu-sit-2026-01-{source_entry['sha256'][:12]}"
    asset = {
        "schema_version": 1,
        "dataset_id": dataset_id,
        "source": {
            "publisher": manifest["publisher"],
            "url": source_entry["url"],
            "portal": manifest["portal"],
            "retrieved_at_utc": manifest["retrieved_at_utc"],
            "published_route_currency": "2026-01",
            "http_last_modified": source_entry["http_last_modified"],
            "raw_sha256": source_entry["sha256"],
        },
        "coverage_bbox_west_south_east_north": [round(value, 6) for value in bbox],
        "planning_ready": False,
        "routes": sorted(routes, key=lambda route: route["id"]),
    }
    report = {
        "dataset_id": dataset_id,
        "source": asset["source"],
        "boundary_source": next(item["url"] for item in manifest["files"] if item["name"] == "distritos.geojson"),
        "boundary_warning": manifest["boundary_warning"],
        "geometry": {
            "directional_routes": len(routes),
            "valid_directional_routes": len(route_shapes),
            "coordinate_points": sum(sum(len(segment) for segment in route["geometry"]["coordinates"]) for route in routes),
            "service_counts": dict(sorted(services.items())),
            "bbox_west_south_east_north": asset["coverage_bbox_west_south_east_north"],
        },
        "districts": {
            "lima_reference_count": sum(province == "LIMA" for province, _, _ in districts),
            "callao_reference_count": sum(province == "CALLAO" for province, _, _ in districts),
            "threshold_route_metres": MIN_DISTRICT_ROUTE_METRES,
            "lima_touched_by_published_sit_routes": sorted(covered_lima, key=lambda item: item["name"]),
            "lima_not_touched_by_published_sit_routes": sorted(uncovered_lima, key=lambda item: item["name"]),
        },
        "limitations": [
            "These are ATU concession SIT route centerlines, not Lima's complete transport network.",
            "The dataset has no stop sequence, fares, travel times or active-vehicle confirmation; it cannot support itinerary planning by itself.",
            "The geovisor describes the 2017 INEI district polygons as reference census boundaries, not official territorial limits.",
            "Route currency is January 2026 according to the ATU geovisor; it is not real-time data.",
            "The geovisor page does not state a dataset-specific license; retain ATU attribution and confirm publication terms before redistribution.",
        ],
    }
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    ASSET.write_text(json.dumps(asset, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "dataset_id": dataset_id,
                "routes": len(routes),
                "lima_reference_districts_touched": len(covered_lima),
                "lima_reference_districts_total": report["districts"]["lima_reference_count"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
