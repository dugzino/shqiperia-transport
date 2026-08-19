#!/usr/bin/env python3
"""Build lib/data/sample/prishtina_network.dart from OSM extracts.

The generated file is the hand-editable source of truth. Re-running this
script overwrites it — prefer editing the Dart arrays directly.
"""

from __future__ import annotations

import json
import math
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

STOPS_LOG = Path(
    "/home/dugzino/.grok/sessions/%2Fhome%2Fdugzino%2FDevelopment%2FRepositories%2FDugzino%2Fshqiperia-transport/01a019d6-9a0e-7d41-bfeb-747190f1d1b5/terminal/call-777b0aa0-b5b7-43f8-8a42-802979d4c9ab-138.log"
)
ROUTES_JSON = Path("/tmp/pr_network.json")
OUT = Path(__file__).resolve().parents[1] / "lib/data/sample/prishtina_network.dart"

SNAP_METERS = 90.0
MERGE_METERS = 45.0
CHAIN_METERS = 20.0

REPL = str.maketrans(
    {
        "ë": "e",
        "Ë": "e",
        "ç": "c",
        "Ç": "c",
        "ä": "a",
        "ö": "o",
        "ü": "u",
        "š": "s",
        "ć": "c",
        "č": "c",
        "ž": "z",
        "đ": "d",
        "á": "a",
        "í": "i",
        "ó": "o",
        "ú": "u",
    }
)


def slugify(name: str) -> str:
    s = name.translate(REPL).lower()
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s or "stop"


def meters(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1 = a
    lat2, lon2 = b
    return math.hypot((lat1 - lat2) * 111_000, (lon1 - lon2) * 111_000 * math.cos(math.radians(lat1)))


def dist_to_segment(p, a, b) -> tuple[float, float]:
    """Return (meters to segment, t in 0..1)."""
    ax, ay = 0.0, 0.0
    bx = (b[1] - a[1]) * 111_000 * math.cos(math.radians(a[0]))
    by = (b[0] - a[0]) * 111_000
    px = (p[1] - a[1]) * 111_000 * math.cos(math.radians(a[0]))
    py = (p[0] - a[0]) * 111_000
    ab2 = bx * bx + by * by
    if ab2 == 0:
        return math.hypot(px, py), 0.0
    t = max(0.0, min(1.0, (px * bx + py * by) / ab2))
    dx = px - t * bx
    dy = py - t * by
    return math.hypot(dx, dy), t


def dart_str(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def load_named_stops() -> list[dict]:
    text = STOPS_LOG.read_text()
    data = json.loads(text[text.find("{") :])
    stops = []
    for el in data["elements"]:
        name = (el.get("tags") or {}).get("name")
        if not name:
            continue
        stops.append(
            {
                "name": name.strip(),
                "lat": float(el["lat"]),
                "lng": float(el["lon"]),
            }
        )
    return stops


def merge_stops(raw: list[dict]) -> list[dict]:
    clusters: list[dict] = []
    for stop in raw:
        placed = False
        for cluster in clusters:
            if cluster["name"].casefold() != stop["name"].casefold():
                continue
            if meters((cluster["lat"], cluster["lng"]), (stop["lat"], stop["lng"])) <= MERGE_METERS:
                n = cluster["n"]
                cluster["lat"] = (cluster["lat"] * n + stop["lat"]) / (n + 1)
                cluster["lng"] = (cluster["lng"] * n + stop["lng"]) / (n + 1)
                cluster["n"] += 1
                placed = True
                break
        if not placed:
            clusters.append({**stop, "n": 1})

    used: dict[str, int] = {}
    out = []
    for cluster in clusters:
        base = slugify(cluster["name"])
        count = used.get(base, 0) + 1
        used[base] = count
        slug = base if count == 1 else f"{base}-{count}"
        out.append(
            {
                "name": cluster["name"],
                "nameSlug": slug,
                "lat": round(cluster["lat"], 6),
                "lng": round(cluster["lng"], 6),
            }
        )
    out.sort(key=lambda s: (s["name"].casefold(), s["nameSlug"]))
    return out


def chain_polyline(segments: list[list[tuple[float, float]]]) -> list[tuple[float, float]]:
    if not segments:
        return []
    unused = [list(seg) for seg in segments if len(seg) >= 2]
    if not unused:
        return []
    result = unused.pop(0)

    def close(a, b) -> bool:
        return meters(a, b) <= CHAIN_METERS

    changed = True
    while changed and unused:
        changed = False
        for i, seg in enumerate(unused):
            if close(result[-1], seg[0]):
                result.extend(seg[1:])
            elif close(result[-1], seg[-1]):
                result.extend(reversed(seg[:-1]))
            elif close(result[0], seg[-1]):
                result = seg[:-1] + result
            elif close(result[0], seg[0]):
                result = list(reversed(seg[1:])) + result
            else:
                continue
            unused.pop(i)
            changed = True
            break
    return result


def project(point, polyline) -> tuple[float, float]:
    best_d = float("inf")
    best_along = 0.0
    along = 0.0
    for i in range(len(polyline) - 1):
        a, b = polyline[i], polyline[i + 1]
        seglen = meters(a, b)
        d, t = dist_to_segment(point, a, b)
        if d < best_d:
            best_d = d
            best_along = along + t * seglen
        along += seglen
    return best_d, best_along


def line_name(tags: dict, snapped: list[dict]) -> str:
    raw = tags.get("name") or f"Linja {tags.get('ref', '')}"
    raw = re.sub(r"^Trafiku Urban\s+", "", raw).strip()
    m = re.match(r"^[0-9A-Za-z]+\s*\((.+)\)\s*$", raw)
    if m:
        return m.group(1).replace(" - ", " – ")
    if snapped:
        return f"{snapped[0]['name']} – {snapped[-1]['name']}"
    return raw


def build_lines(stops: list[dict]) -> list[dict]:
    data = json.loads(ROUTES_JSON.read_text())
    nodes = {e["id"]: e for e in data["elements"] if e["type"] == "node"}
    ways = {e["id"]: e for e in data["elements"] if e["type"] == "way"}
    rels = [e for e in data["elements"] if e["type"] == "relation"]

    best_by_ref: dict[str, dict] = {}
    for rel in rels:
        tags = rel.get("tags") or {}
        if tags.get("type") != "route":
            continue
        ref = (tags.get("ref") or "").strip()
        name = tags.get("name") or ""
        if not ref or "Prizren" in name or "Prishtina - Prizren" in name:
            continue
        segments = []
        for member in rel.get("members", []):
            if member["type"] != "way":
                continue
            way = ways.get(member["ref"])
            if not way:
                continue
            pts = []
            for nid in way.get("nodes", []):
                node = nodes.get(nid)
                if node and "lat" in node:
                    pts.append((node["lat"], node["lon"]))
            if len(pts) >= 2:
                segments.append(pts)
        polyline = chain_polyline(segments)
        if len(polyline) < 2:
            continue

        snapped = []
        for stop in stops:
            d, along = project((stop["lat"], stop["lng"]), polyline)
            if d <= SNAP_METERS:
                snapped.append({**stop, "along": along, "off": d})
        snapped.sort(key=lambda s: s["along"])
        unique = []
        for stop in snapped:
            if unique and unique[-1]["nameSlug"] == stop["nameSlug"]:
                continue
            if unique and meters(
                (unique[-1]["lat"], unique[-1]["lng"]),
                (stop["lat"], stop["lng"]),
            ) < 30:
                continue
            unique.append(stop)

        candidate = {
            "number": ref,
            "name": line_name(tags, unique),
            "stops": [
                {"stopNumber": i + 1, "nameSlug": s["nameSlug"]}
                for i, s in enumerate(unique)
            ],
            "_count": len(unique),
        }
        prev = best_by_ref.get(ref)
        if prev is None or candidate["_count"] > prev["_count"]:
            best_by_ref[ref] = candidate

    # Official Trafiku Urban lines that OSM has no usable geometry for yet.
    for ref, name in (
        ("5", "Bregu i Diellit – Sofali"),
    ):
        best_by_ref.setdefault(
            ref,
            {"number": ref, "name": name, "stops": [], "_count": 0},
        )

    def ref_key(item: dict) -> tuple:
        num = item["number"]
        m = re.match(r"(\d+)([A-Za-z]*)$", num)
        if m:
            return (int(m.group(1)), m.group(2))
        return (999, num)

    lines = [best_by_ref[k] for k in best_by_ref]
    lines.sort(key=ref_key)
    for line in lines:
        line.pop("_count", None)
    return lines


def write_dart(stops: list[dict], lines: list[dict]) -> None:
    parts = [
        "// Hand-editable Prishtina network (Trafiku Urban).",
        "//",
        "// Add a stop: append to [prishtinaBusStops] with a unique [nameSlug].",
        "// Add a line: append to [prishtinaLines] and list stops in order",
        "//   as {stopNumber, nameSlug} where nameSlug matches a bus stop.",
        "//",
        "// Seeded from OpenStreetMap (ODbL) named bus_stop nodes, with line",
        "// sequences inferred by snapping those stops onto OSM route geometry.",
        "// Official line list: https://trafikurban-pr.com/2022/orari-dhe-linjat/",
        "// Sequences are a starting point — fix names and order here.",
        "",
        "class RawBusStop {",
        "  const RawBusStop({",
        "    required this.name,",
        "    required this.nameSlug,",
        "    required this.lat,",
        "    required this.lng,",
        "  });",
        "",
        "  final String name;",
        "  final String nameSlug;",
        "  final double lat;",
        "  final double lng;",
        "}",
        "",
        "class RawLineStop {",
        "  const RawLineStop({",
        "    required this.stopNumber,",
        "    required this.nameSlug,",
        "  });",
        "",
        "  final int stopNumber;",
        "  final String nameSlug;",
        "}",
        "",
        "class RawLine {",
        "  const RawLine({",
        "    required this.name,",
        "    required this.stops,",
        "    this.number,",
        "  });",
        "",
        "  final String name;",
        "  final String? number;",
        "  final List<RawLineStop> stops;",
        "}",
        "",
        "const prishtinaBusStops = <RawBusStop>[",
    ]
    for stop in stops:
        parts.append("  RawBusStop(")
        parts.append(f"    name: {dart_str(stop['name'])},")
        parts.append(f"    nameSlug: {dart_str(stop['nameSlug'])},")
        parts.append(f"    lat: {stop['lat']},")
        parts.append(f"    lng: {stop['lng']},")
        parts.append("  ),")
    parts.append("];")
    parts.append("")
    parts.append("const prishtinaLines = <RawLine>[")
    for line in lines:
        parts.append("  RawLine(")
        if line.get("number"):
            parts.append(f"    number: {dart_str(line['number'])},")
        parts.append(f"    name: {dart_str(line['name'])},")
        parts.append("    stops: [")
        for st in line["stops"]:
            parts.append(
                "      RawLineStop("
                f"stopNumber: {st['stopNumber']}, "
                f"nameSlug: {dart_str(st['nameSlug'])}),"
            )
        parts.append("    ],")
        parts.append("  ),")
    parts.append("];")
    parts.append("")
    OUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(f"wrote {OUT} ({len(stops)} stops, {len(lines)} lines)")


def main() -> None:
    stops = merge_stops(load_named_stops())
    lines = build_lines(stops)
    write_dart(stops, lines)
    for line in lines:
        print(f"  {line['number']:>4}  {len(line['stops']):3} stops  {line['name']}")


if __name__ == "__main__":
    main()
