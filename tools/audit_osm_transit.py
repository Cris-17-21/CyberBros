#!/usr/bin/env python3
"""Audit OSM public-transport relations and stops from a local PBF extract.

Counts are evidence about tagging only. They do not claim service, fare,
geometry, schedule, or administrative coverage until the report says so.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import tempfile
from typing import Any

import osmium

DEFAULT_BBOX = (-12.35, -77.20, -11.70, -76.65)  # south, west, north, east; provisional
TRANSIT_MODES = {"bus", "trolleybus", "subway", "train", "light_rail", "tram"}
STOP_ROLES = {"stop", "platform", "stop_entry_only", "stop_exit_only"}


def parse_bbox(value: str) -> tuple[float, float, float, float]:
    south, west, north, east = (float(part.strip()) for part in value.split(","))
    if not (-90 <= south < north <= 90 and -180 <= west < east <= 180):
        raise ValueError("bbox debe ser south,west,north,east y tener rangos válidos")
    return south, west, north, east


def inside_bbox(lat: float, lon: float, bbox: tuple[float, float, float, float]) -> bool:
    south, west, north, east = bbox
    return south <= lat <= north and west <= lon <= east


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class FirstPass(osmium.SimpleHandler):
    def __init__(self, bbox: tuple[float, float, float, float]) -> None:
        super().__init__()
        self.bbox = bbox
        self.routes: dict[int, dict[str, Any]] = {}
        self.stops: dict[int, dict[str, Any]] = {}

    def node(self, node: osmium.osm.Node) -> None:
        if not node.location.valid() or not inside_bbox(node.lat, node.lon, self.bbox):
            return
        tags = dict(node.tags)
        if tags.get("highway") == "bus_stop" or tags.get("public_transport") in {"platform", "stop_position"}:
            self.stops[node.id] = {
                "id": node.id,
                "name": tags.get("name"),
                "lat": node.lat,
                "lon": node.lon,
                "highway": tags.get("highway"),
                "public_transport": tags.get("public_transport"),
                "source": f"osm:node/{node.id}",
            }

    def relation(self, relation: osmium.osm.Relation) -> None:
        tags = dict(relation.tags)
        mode = tags.get("route")
        if tags.get("type") != "route" or mode not in TRANSIT_MODES:
            return
        ways: list[dict[str, Any]] = []
        stops: list[dict[str, Any]] = []
        for member in relation.members:
            if member.type == "w" and member.role not in STOP_ROLES:
                ways.append({"id": member.ref, "role": member.role})
            elif member.type == "n" and member.role in STOP_ROLES:
                stops.append({"id": member.ref, "role": member.role})
        self.routes[relation.id] = {
            "id": relation.id,
            "name": tags.get("name"),
            "ref": tags.get("ref"),
            "mode": mode,
            "network": tags.get("network"),
            "operator": tags.get("operator"),
            "from": tags.get("from"),
            "to": tags.get("to"),
            "ways": ways,
            "stops": stops,
        }


class MemberGeometryPass(osmium.SimpleHandler):
    def __init__(self, route_way_ids: set[int], stop_ids: set[int], bbox: tuple[float, float, float, float]) -> None:
        super().__init__()
        self.route_way_ids = route_way_ids
        self.stop_ids = stop_ids
        self.bbox = bbox
        self.ways: dict[int, list[list[float]]] = {}
        self.relation_stops: dict[int, dict[str, Any]] = {}

    def way(self, way: osmium.osm.Way) -> None:
        if way.id not in self.route_way_ids:
            return
        coordinates: list[list[float]] = []
        for node in way.nodes:
            if node.location.valid():
                coordinates.append([node.lon, node.lat])
        self.ways[way.id] = coordinates

    def node(self, node: osmium.osm.Node) -> None:
        if node.id not in self.stop_ids or not node.location.valid():
            return
        if not inside_bbox(node.lat, node.lon, self.bbox):
            return
        self.relation_stops[node.id] = {
            "id": node.id,
            "name": node.tags.get("name"),
            "lat": node.lat,
            "lon": node.lon,
            "source": f"osm:node/{node.id}",
        }


def audit(pbf: Path, bbox: tuple[float, float, float, float], location_store: Path) -> dict[str, Any]:
    first = FirstPass(bbox)
    first.apply_file(str(pbf))

    route_way_ids = {way["id"] for route in first.routes.values() for way in route["ways"]}
    relation_stop_ids = {stop["id"] for route in first.routes.values() for stop in route["stops"]}
    second = MemberGeometryPass(route_way_ids, relation_stop_ids, bbox)
    # The Peru extract has millions of nodes. Keep the location index on disk;
    # sparse_mem_map can degrade badly on large extracts.
    second.apply_file(str(pbf), locations=True, idx=f"sparse_file_array,{location_store}")

    route_summaries = []
    for route in first.routes.values():
        member_geometries = [second.ways.get(way["id"], []) for way in route["ways"]]
        usable_ways = [geometry for geometry in member_geometries if len(geometry) >= 2]
        valid_stops = [stop for stop in route["stops"] if stop["id"] in second.relation_stops]
        route_summaries.append(
            {
                "id": route["id"],
                "name": route["name"],
                "ref": route["ref"],
                "mode": route["mode"],
                "network": route["network"],
                "operator": route["operator"],
                "from": route["from"],
                "to": route["to"],
                "member_way_count": len(route["ways"]),
                "member_way_geometry_count": len(usable_ways),
                "member_stop_count": len(route["stops"]),
                "member_stop_coordinate_count": len(valid_stops),
                "has_ordered_stops": len(valid_stops) >= 2,
                "has_geometry": bool(usable_ways),
                "source": f"osm:relation/{route['id']}",
            }
        )

    bbox_text = ",".join(str(part) for part in bbox)
    return {
        "retrieved_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "source": {
            "name": "OpenStreetMap via Geofabrik Peru extract",
            "url": "https://download.geofabrik.de/south-america/peru-latest.osm.pbf",
            "license": "Open Database License (ODbL) 1.0",
            "attribution": "© OpenStreetMap contributors",
            "pbf_file": pbf.name,
            "pbf_sha256": _sha256(pbf),
            "pbf_timestamp": "2026-10-16 (Geofabrik page snapshot; exact file timestamp is in the download metadata)",
        },
        "bbox_south_west_north_east": bbox_text,
        "bbox_status": "provisional; includes Lima/Callao vicinity and is not the final administrative coverage polygon",
        "counts": {
            "route_relations": len(route_summaries),
            "routes_with_any_member_way": sum(bool(route["member_way_count"]) for route in route_summaries),
            "routes_with_member_way_geometry": sum(route["has_geometry"] for route in route_summaries),
            "routes_with_at_least_two_ordered_stop_coordinates": sum(route["has_ordered_stops"] for route in route_summaries),
            "unique_tagged_stop_nodes_in_bbox": len(first.stops),
            "unique_relation_stop_nodes_in_bbox": len(second.relation_stops),
        },
        "routes": sorted(route_summaries, key=lambda route: (route["mode"], route["ref"] or "", route["name"] or "", route["id"])),
        "limitations": [
            "The bbox is provisional; no claim of full Lima coverage can be made from this audit.",
            "OSM relation presence does not confirm that a service is currently operating.",
            "No fare is established by this audit; fares without an authoritative source remain estimated or unavailable.",
            "A route with a member way and stop nodes still requires continuity, sequence, and field-quality review.",
            "Route summaries contain OSM source identifiers; all derived OSM data must retain ODbL attribution/share-alike obligations.",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pbf", type=Path, help="Ruta al extracto OSM .pbf local")
    parser.add_argument("--bbox", type=parse_bbox, default=DEFAULT_BBOX, help="south,west,north,east; provisional default")
    parser.add_argument("--output", type=Path, default=Path("data/reports/osm-lima-transit-audit.json"))
    parser.add_argument("--location-store", type=Path, default=Path(tempfile.gettempdir()) / "cyberon-osm-location-index", help="Archivo temporal para el índice de nodos")
    args = parser.parse_args()
    if not args.pbf.is_file():
        parser.error(f"no existe el extracto: {args.pbf}")
    args.location_store.parent.mkdir(parents=True, exist_ok=True)
    report = audit(args.pbf, args.bbox, args.location_store)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["counts"], ensure_ascii=False, indent=2))
    print(f"Informe: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
