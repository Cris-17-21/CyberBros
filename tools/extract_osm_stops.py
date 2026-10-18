#!/usr/bin/env python3
"""Extract tagged public transport nodes around Lima from a local OSM PBF.

These are map features, not verified operating stops or boarding points.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path

import osmium

BBOX = (-12.35, -77.20, -11.70, -76.65)  # south, west, north, east; provisional


class StopCollector(osmium.SimpleHandler):
    def __init__(self) -> None:
        super().__init__()
        self.stops: list[dict] = []

    def node(self, node: osmium.osm.Node) -> None:
        if not node.location.valid():
            return
        if not (BBOX[0] <= node.lat <= BBOX[2] and BBOX[1] <= node.lon <= BBOX[3]):
            return
        tags = node.tags
        if tags.get('highway') != 'bus_stop' and tags.get('public_transport') not in {'platform', 'stop_position'}:
            return
        self.stops.append({
            'id': f'osm:node:{node.id}',
            'name': tags.get('name') or tags.get('official_name'),
            'lat': round(node.lat, 7),
            'lon': round(node.lon, 7),
            'highway': tags.get('highway'),
            'public_transport': tags.get('public_transport'),
            'source': f'https://www.openstreetmap.org/node/{node.id}',
        })


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pbf', type=Path)
    parser.add_argument('--output', type=Path, default=Path('app/cyber_bros/assets/data/osm_stops.json'))
    args = parser.parse_args()
    if not args.pbf.is_file():
        parser.error(f'No existe {args.pbf}')
    collector = StopCollector()
    collector.apply_file(str(args.pbf))
    payload = {
        'schema_version': 1,
        'source': 'OpenStreetMap via Geofabrik Peru extract',
        'license': 'ODbL 1.0',
        'attribution': '© OpenStreetMap contributors',
        'generated_at_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
        'bbox_south_west_north_east': BBOX,
        'status': 'crowdsourced map features; operation and route membership unverified',
        'stops': sorted(collector.stops, key=lambda stop: stop['id']),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print(json.dumps({'tagged_stop_nodes': len(collector.stops), 'output': str(args.output)}))


if __name__ == '__main__':
    main()
