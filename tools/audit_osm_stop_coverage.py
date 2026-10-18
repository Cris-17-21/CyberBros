#!/usr/bin/env python3
"""Measure OSM tagged-stop distribution against ATU's referential district polygons."""

from __future__ import annotations

import collections
import json
from pathlib import Path

from shapely.geometry import Point, shape
from shapely.prepared import prep

ROOT = Path(__file__).resolve().parents[1]
STOPS = ROOT / 'app/cyber_bros/assets/data/osm_stops.json'
DISTRICTS = ROOT / 'data/raw/atu/distritos.geojson'
REPORT = ROOT / 'data/reports/osm-stop-coverage.json'


def main() -> None:
    stops = json.loads(STOPS.read_text(encoding='utf-8'))
    districts = json.loads(DISTRICTS.read_text(encoding='utf-8'))
    areas = []
    for feature in districts['features']:
        properties = feature['properties']
        areas.append((
            str(properties['nombdep']).upper(),
            str(properties['nombre']).upper(),
            prep(shape(feature['geometry'])),
        ))
    counts: collections.Counter[tuple[str, str]] = collections.Counter()
    outside = 0
    for stop in stops['stops']:
        point = Point(stop['lon'], stop['lat'])
        match = next(((province, district) for province, district, polygon in areas if polygon.covers(point)), None)
        if match is None:
            outside += 1
        else:
            counts[match] += 1
    lima = [{'district': district, 'tagged_nodes': counts[(province, district)]}
            for province, district, _ in areas if province == 'LIMA']
    report = {
        'source': stops['source'],
        'license': stops['license'],
        'source_bbox_south_west_north_east': stops['bbox_south_west_north_east'],
        'reference_boundaries': 'ATU geovisor / INEI 2017 census districts; not official territorial boundaries',
        'total_tagged_nodes_in_bbox': len(stops['stops']),
        'lima_tagged_nodes': sum(item['tagged_nodes'] for item in lima),
        'lima_reference_districts': len(lima),
        'lima_reference_districts_with_tagged_nodes': sum(item['tagged_nodes'] > 0 for item in lima),
        'callao_tagged_nodes': sum(count for (province, _), count in counts.items() if province == 'CALLAO'),
        'outside_reference_polygons': outside,
        'lima_districts': sorted(lima, key=lambda item: item['district']),
        'limitations': [
            'A tagged OSM point is not proof that a stop currently operates.',
            'This count does not establish which routes serve a stop or whether boarding is permitted.',
            'The extract uses a provisional bounding box and may omit points beyond it.',
            'The ATU district polygons are referential census boundaries, not official territorial limits.',
        ],
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in (
        'total_tagged_nodes_in_bbox', 'lima_tagged_nodes',
        'lima_reference_districts_with_tagged_nodes', 'callao_tagged_nodes',
        'outside_reference_polygons')}, indent=2))


if __name__ == '__main__':
    main()
