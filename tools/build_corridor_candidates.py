#!/usr/bin/env python3
"""Build a guarded pilot graph from geometrically matching ATU/OSM routes.

This asset is not evidence of current service or a journey quote. The mobile
planner must keep the source and uncertainty attached to every result.
"""

from __future__ import annotations

import json
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ATU = ROOT / 'app/cyber_bros/assets/data/atu_sit_routes.json'
OSM = ROOT / 'app/cyber_bros/assets/data/osm_route_stops.json'
CROSSWALK = ROOT / 'data/reports/atu-osm-route-crosswalk.json'
FARES = ROOT / 'data/raw/atu/general_fares.json'
ASSET = ROOT / 'app/cyber_bros/assets/data/corridor_candidates.json'


def main() -> None:
    atu = {route['id']: route for route in json.loads(ATU.read_text(encoding='utf-8'))['routes']}
    osm = {route['id']: route for route in json.loads(OSM.read_text(encoding='utf-8'))['routes']}
    crosswalk = json.loads(CROSSWALK.read_text(encoding='utf-8'))
    fare_book = json.loads(FARES.read_text(encoding='utf-8'))
    routes = []
    for match in crosswalk['matches']:
        if not match['plausible_geometry']:
            continue
        source_route = osm[match['osm_relation_id']]
        official_geometry = atu[match['best_candidate']['atu_route_id']]
        service = official_geometry['service']
        fare = fare_book['services'].get(service)
        if fare is None:
            continue
        routes.append({
            'id': source_route['id'],
            'name': source_route['name'],
            'code': source_route['ref'],
            'service': service,
            'atu_geometry_id': official_geometry['id'],
            'stop_sequence_source': source_route['source'],
            'geometry_source': 'https://geovisor.atumovilidad.pe/data/sit_actual.geojson',
            'stop_count': len(source_route['ordered_stops_in_bbox']),
            'stops': source_route['ordered_stops_in_bbox'],
            'general_fare_cents': fare['fare_cents'],
            'fare_source': fare['source_url'],
            'fare_source_date': fare['source_date'],
            'match_median_metres': match['best_candidate']['median_stop_to_line_metres'],
            'match_p90_metres': match['best_candidate']['p90_stop_to_line_metres'],
            'certainty': {
                'geometry': 'published_by_atu_2026_01',
                'stop_sequence': 'osm_community_unverified',
                'operation': 'unverified',
                'general_fare': 'published_by_atu_2026_04',
                'fare_applicability': 'estimate_check_promotions_and_card',
                'duration': 'estimated',
            },
        })
    routes.sort(key=lambda item: item['id'])
    payload = {
        'schema_version': 1,
        'dataset_id': 'corridor-pilot-' + hashlib.sha256(
            ATU.read_bytes() + OSM.read_bytes() + FARES.read_bytes()
        ).hexdigest()[:16],
        'scope': 'corridor_pilot_only',
        'planning_ready_for_all_lima': False,
        'route_count': len(routes),
        'fare_warning': fare_book['warning'],
        'attribution': 'Rutas SIT © ATU; paraderos © OpenStreetMap contributors (ODbL 1.0)',
        'routes': routes,
    }
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    ASSET.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print(json.dumps({'candidate_routes': len(routes),
                      'unique_stops': len({stop['id'] for route in routes for stop in route['stops']})}, indent=2))


if __name__ == '__main__':
    main()
