#!/usr/bin/env python3
"""Extract ordered OSM route-member stops within the provisional Lima bbox.

OSM route relations are community data. The result is a candidate graph, not
proof that a service operates, that every stop permits boarding, or of a fare.
"""

from __future__ import annotations

import argparse
import collections
import datetime as dt
import json
from pathlib import Path

from audit_osm_transit import DEFAULT_BBOX, FirstPass

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / 'app/cyber_bros/assets/data/osm_route_stops.json'
REPORT = ROOT / 'data/reports/osm-route-stops.json'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pbf', type=Path)
    args = parser.parse_args()
    if not args.pbf.is_file():
        parser.error(f'No existe {args.pbf}')
    collector = FirstPass(DEFAULT_BBOX)
    collector.apply_file(str(args.pbf))

    routes = []
    mode_counts: collections.Counter[str] = collections.Counter()
    for relation in collector.routes.values():
        ordered = []
        for member in relation['stops']:
            stop = collector.stops.get(member['id'])
            if stop is None:
                continue
            ordered.append({
                'id': f"osm:node:{stop['id']}",
                'name': stop['name'],
                'lat': round(stop['lat'], 7),
                'lon': round(stop['lon'], 7),
                'role': member['role'],
            })
        if len(ordered) < 2:
            continue
        mode_counts[relation['mode']] += 1
        routes.append({
            'id': f"osm:relation:{relation['id']}",
            'name': relation['name'],
            'ref': relation['ref'],
            'mode': relation['mode'],
            'network': relation['network'],
            'operator': relation['operator'],
            'from': relation['from'],
            'to': relation['to'],
            'ordered_stops_in_bbox': ordered,
            'source': f"https://www.openstreetmap.org/relation/{relation['id']}",
            'data_quality': {
                'operating_status': 'unverified',
                'stop_completeness': 'unverified',
                'boarding_permissions': 'unverified',
                'fare': 'unavailable',
                'schedule': 'unavailable',
            },
        })
    routes.sort(key=lambda route: route['id'])
    payload = {
        'schema_version': 1,
        'source': 'OpenStreetMap via Geofabrik Peru extract',
        'license': 'ODbL 1.0',
        'attribution': '© OpenStreetMap contributors',
        'generated_at_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
        'bbox_south_west_north_east': DEFAULT_BBOX,
        'planning_ready': False,
        'routes': routes,
    }
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    ASSET.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    report = {
        'route_relations_scanned_in_peru': len(collector.routes),
        'tagged_stops_in_bbox': len(collector.stops),
        'relations_with_at_least_two_ordered_tagged_stops_in_bbox': len(routes),
        'mode_counts': dict(sorted(mode_counts.items())),
        'total_ordered_stop_members': sum(len(route['ordered_stops_in_bbox']) for route in routes),
        'limitations': [
            'OSM relation presence does not confirm current operation.',
            'Only node members with stop/platform roles and tagged stop points in the bbox were included.',
            'Relation member order may be incomplete or incorrect; no topology verification was performed.',
            'No fares, schedules, boarding permissions, transfer policies, or route geometry were verified.',
        ],
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
