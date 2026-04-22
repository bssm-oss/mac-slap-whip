#!/usr/bin/env python3

from __future__ import annotations

import math
import os
import struct
import subprocess
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "Branding"
ICONSET = BRANDING / "AppIcon.iconset"
MENU_ICON = ROOT / "Sources" / "MacWhip" / "Resources" / "MenuBarIconTemplate.png"
SVG_PATH = BRANDING / "MacWhipLogo.svg"
ICNS_PATH = BRANDING / "AppIcon.icns"

BG = (32, 29, 29, 255)
BG_ALT = (48, 44, 44, 255)
LIGHT = (253, 252, 252, 255)
ACCENT = (72, 203, 178, 255)
MENU = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)


def clamp(v: float) -> int:
    return max(0, min(255, int(round(v))))


def blend(top, bottom):
    ta = top[3] / 255.0
    ba = bottom[3] / 255.0
    oa = ta + ba * (1 - ta)
    if oa <= 0:
        return (0, 0, 0, 0)
    return tuple(
        clamp(((top[i] * ta) + (bottom[i] * ba * (1 - ta))) / oa) for i in range(3)
    ) + (clamp(oa * 255),)


def blank(size, color=TRANSPARENT):
    return [[color for _ in range(size)] for _ in range(size)]


def rounded_rect_mask(x, y, w, h, r, px, py):
    cx = min(max(px, x + r), x + w - r)
    cy = min(max(py, y + r), y + h - r)
    dx = px - cx
    dy = py - cy
    if dx * dx + dy * dy <= r * r:
        return 1.0
    return 0.0


def segment_distance(px, py, ax, ay, bx, by):
    vx = bx - ax
    vy = by - ay
    wx = px - ax
    wy = py - ay
    length_sq = vx * vx + vy * vy
    if length_sq == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, (wx * vx + wy * vy) / length_sq))
    projx = ax + t * vx
    projy = ay + t * vy
    return math.hypot(px - projx, py - projy)


def paint_if_closer(canvas, weight_map, x, y, color, alpha, distance):
    size = len(canvas)
    if 0 <= x < size and 0 <= y < size and alpha > 0:
        existing = weight_map[y][x]
        if existing is None or distance < existing:
            weight_map[y][x] = distance
            overlay = color[:3] + (clamp(alpha * color[3]),)
            canvas[y][x] = blend(overlay, canvas[y][x])


def draw_background(canvas):
    size = len(canvas)
    radius = size * 0.225
    inset = size * 0.055
    inner = blank(size)
    for y in range(size):
        for x in range(size):
            if rounded_rect_mask(
                inset,
                inset,
                size - 2 * inset,
                size - 2 * inset,
                radius,
                x + 0.5,
                y + 0.5,
            ):
                inner[y][x] = BG
            else:
                inner[y][x] = TRANSPARENT

    for y in range(size):
        for x in range(size):
            canvas[y][x] = inner[y][x]

    edge_inset = inset + size * 0.02
    edge_radius = radius - size * 0.018
    for y in range(size):
        for x in range(size):
            outer = rounded_rect_mask(
                inset,
                inset,
                size - 2 * inset,
                size - 2 * inset,
                radius,
                x + 0.5,
                y + 0.5,
            )
            inner_mask = rounded_rect_mask(
                edge_inset,
                edge_inset,
                size - 2 * edge_inset,
                size - 2 * edge_inset,
                edge_radius,
                x + 0.5,
                y + 0.5,
            )
            if outer and not inner_mask:
                canvas[y][x] = blend(BG_ALT[:3] + (120,), canvas[y][x])


def draw_mark(canvas, stroke_color, stop_color):
    size = len(canvas)
    weight_map = [[None for _ in range(size)] for _ in range(size)]

    left_a = (size * 0.27, size * 0.67)
    apex = (size * 0.49, size * 0.35)
    right_b = (size * 0.73, size * 0.55)
    stop_x = size * 0.77
    stop_y = size * 0.38
    stop_h = size * 0.28
    stroke = size * 0.085

    for y in range(size):
        for x in range(size):
            px = x + 0.5
            py = y + 0.5
            d1 = segment_distance(px, py, *left_a, *apex)
            d2 = segment_distance(px, py, *apex, *right_b)
            dist = min(d1, d2)
            alpha = max(0.0, min(1.0, 1.0 - (dist - stroke * 0.5) / (stroke * 0.35)))
            if alpha > 0:
                paint_if_closer(canvas, weight_map, x, y, stroke_color, alpha, dist)

            if stop_x <= px <= stop_x + size * 0.06 and stop_y <= py <= stop_y + stop_h:
                canvas[y][x] = blend(stop_color, canvas[y][x])


def downsample(canvas, final_size):
    src = len(canvas)
    scale = src // final_size
    output = blank(final_size)
    for y in range(final_size):
        for x in range(final_size):
            rgba = [0, 0, 0, 0]
            for sy in range(scale):
                for sx in range(scale):
                    px = canvas[y * scale + sy][x * scale + sx]
                    for i in range(4):
                        rgba[i] += px[i]
            total = scale * scale
            output[y][x] = tuple(clamp(v / total) for v in rgba)
    return output


def write_png(path: Path, canvas):
    path.parent.mkdir(parents=True, exist_ok=True)
    size = len(canvas)
    raw = bytearray()
    for row in canvas:
        raw.append(0)
        for r, g, b, a in row:
            raw.extend([r, g, b, a])
    compressed = zlib.compress(bytes(raw), level=9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def generate_icon(size: int):
    scale = 4
    large = blank(size * scale)
    draw_background(large)
    draw_mark(large, LIGHT, ACCENT)
    return downsample(large, size)


def generate_menu_icon(size: int = 18):
    scale = 8
    large = blank(size * scale)
    draw_mark(large, MENU, MENU)
    return downsample(large, size)


def write_svg(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="none">
  <rect x="14" y="14" width="228" height="228" rx="52" fill="#201d1d"/>
  <rect x="19" y="19" width="218" height="218" rx="47" stroke="#302c2c" stroke-width="10"/>
  <path d="M68 172L126 88L185 142" stroke="#fdfcfc" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="196" y="98" width="14" height="74" rx="5" fill="#48cbb2"/>
</svg>
"""
    path.write_text(svg, encoding="utf-8")


def generate_iconset():
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    if ICONSET.exists():
        for file in ICONSET.iterdir():
            file.unlink()
    ICONSET.mkdir(parents=True, exist_ok=True)
    for name, size in sizes.items():
        write_png(ICONSET / name, generate_icon(size))


def build_icns():
    if ICNS_PATH.exists():
        ICNS_PATH.unlink()
    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET), "-o", str(ICNS_PATH)], check=True
    )


def main():
    write_svg(SVG_PATH)
    generate_iconset()
    build_icns()
    write_png(MENU_ICON, generate_menu_icon())
    print(f"Generated branding assets in {BRANDING} and {MENU_ICON}")


if __name__ == "__main__":
    main()
