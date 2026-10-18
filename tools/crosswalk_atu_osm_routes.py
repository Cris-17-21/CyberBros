#!/usr/bin/env python3
"""Measure geometry agreement between ATU SIT lines and OSM stop sequences.

A match is only a data-quality candidate. It does not confirm boarding,
operation, schedule, fare, or that the two publishers describe the same trip.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import statistics
import unicodedata

from shapely.geometry import LineString, MultiLineString, Point

ROOT = Path(__file__).resolve().parents[1]
ATU = ROOT / 'app/cyber_bros/assets/data/atu_sit_routes.json'
OSM = ROOT / 'app/cyber_bros/assets/data/osm_route_stops.json'
REPORT = ROOT / 'data/reports/atu-osm-route-crosswalk.json'
LON_SCALE = 111195 * math.cos(math.radians(-12.05))
LAT_SCALE = 111195


def norm(value: str | None) -> str:
    return ''.join(c for c in unicodedata.normalize('NFKD', value or '').lower()
                   if not unicodedata.combining(c))


def family(atu_service: str, osm_name: str) -> bool:
    service = norm(atu_service)
    name = norm(osm_name)
    if 'corredor azul' in service:
        return 'corredor azul' in name
    if 'corredor rojo' in service:
        return 'corredor rojo' in name
    if 'corredor morado' in service:
        return 'corredor morado' in name
    if 'metropolitano' in service:
        return 'metropolitano' in name
    if 'metro de lima' in service:
        return 'linea' in name or 'metro' in name
    return False


def projected_line(route: dict) -> MultiLineString:
    return MultiLineString([
        LineString([(lon * LON_SCALE, lat * LAT_SCALE) for lon, lat in segment])
        for segment in route['geometry']['coordinates']
    ])


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1)]


def main() -> None:
    atu = json.loads(ATU.read_text(encoding='utf-8'))['routes']
    osm = json.loads(OSM.read_text(encoding='utf-8'))['routes']
    lines = {route['id']: projected_line(route) for route in atu}
    matches = []
    no_candidate = []
    for relation in osm:
        stops = relation['ordered_stops_in_bbox']
        if len(stops) < 5:
            continue
        candidates = [route for route in atu
                      if relation['ref'] and route['code'] == relation['ref']
                      and family(route['service'], relation['name'] or '')]
        if not candidates:
            no_candidate.append(relation['id'])
            continue
        scored = []
        for route in candidates:
            line = lines[route['id']]
            distances = [line.distance(Point(stop['lon'] * LON_SCALE, stop['lat'] * LAT_SCALE))
                         for stop in stops]
            scored.append({
                'atu_route_id': route['id'],
                'atu_name': route['name'],
                'median_stop_to_line_metres': round(statistics.median(distances)),
                'p90_stop_to_line_metres': round(percentile(distances, .9)),
                'within_100_metres': sum(distance <= 100 for distance in distances),
                'stop_count': len(stops),
            })
        scored.sort(key=lambda item: (
            item['p90_stop_to_line_metres'], item['median_stop_to_line_metres'], item['atu_route_id']))
        best = scored[0]
        matches.append({
            'osm_relation_id': relation['id'],
            'osm_name': relation['name'],
            'osm_ref': relation['ref'],
            'best_candidate': best,
            'plausible_geometry': best['p90_stop_to_line_metres'] <= 150
                                  and best['median_stop_to_line_metres'] <= 70,
            'candidate_count': len(scored),
        })
    report = {
        'method': 'same route ref and named service family, then stop-to-line distances in local equirectangular metres',
        'thresholds_metres': {'median': 70, 'p90': 150},
        'osm_relations_with_at_least_five_stops': sum(len(route['ordered_stops_in_bbox']) >= 5 for route in osm),
        'same_code_and_service_candidates': len(matches),
        'plausible_geometry_matches': sum(item['plausible_geometry'] for item in matches),
        'without_same_code_service_candidate': no_candidate,
        'matches': matches,
        'limitations': [
            'An OSM stop near an ATU line does not prove that boarding is allowed there.',
            'Direction, route validity, operating status, fares, and timetables remain unverified.',
            'The local distance projection is an approximation suitable for data screening, not navigation.',
            'Combining ATU and OSM data for public redistribution requires review of ATU terms and ODbL obligations.',
        ],
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in (
        'osm_relations_with_at_least_five_stops', 'same_code_and_service_candidates',
        'plausible_geometry_matches')}, indent=2))


if __name__ == '__main__':
    main()
