#!/usr/bin/env python3
"""Génère lib/features/menu/main_menu/mascot_outline_data.dart.

Pour chaque mascotte (PNG détourée RGBA), extrait le contour extérieur de la
silhouette (plus grande composante opaque, traçage Moore, simplification
Douglas-Peucker) puis écrit les points normalisés entre 0 et 1.

Usage : python3 tool/gen_mascot_outlines.py
Dépendances : Pillow, numpy.
"""

import collections
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASCOT_DIR = os.path.join(ROOT, 'assets', 'images', 'mascots')
OUT_FILE = os.path.join(
    ROOT, 'lib', 'features', 'menu', 'main_menu', 'mascot_outline_data.dart')

ALPHA_THRESHOLD = 127
SIMPLIFY_EPSILON = 1.2  # en pixels de l'image source
MAX_POINTS = 400

# Huit voisins, dans l'ordre (rotation régulière autour du pixel courant).
DIRS = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]


def largest_component(mask):
    """Garde uniquement la plus grosse composante connexe (8-voisinage)."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    best = []
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
                continue
            comp = []
            queue = collections.deque([(x, y)])
            seen[y, x] = True
            while queue:
                cx, cy = queue.popleft()
                comp.append((cx, cy))
                for dx, dy in DIRS:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    out = np.zeros_like(mask, dtype=bool)
    for x, y in best:
        out[y, x] = True
    return out


def trace_outline(mask):
    """Traçage Moore du contour extérieur, à partir du premier pixel en ordre de balayage."""
    h, w = mask.shape
    ys, xs = np.nonzero(mask)
    start = (int(xs[0]), int(ys[0]))  # premier pixel : son voisin de gauche est vide
    cur = start
    back = (start[0] - 1, start[1])
    boundary = [cur]
    for _ in range(4 * w * h):
        bi = DIRS.index((back[0] - cur[0], back[1] - cur[1]))
        nxt = None
        for k in range(1, 9):
            dx, dy = DIRS[(bi + k) % 8]
            cx, cy = cur[0] + dx, cur[1] + dy
            if 0 <= cx < w and 0 <= cy < h and mask[cy, cx]:
                pdx, pdy = DIRS[(bi + k - 1) % 8]
                back = (cur[0] + pdx, cur[1] + pdy)
                nxt = (cx, cy)
                break
        if nxt is None:
            break
        cur = nxt
        if cur == start:
            break
        boundary.append(cur)
    return boundary


def douglas_peucker(points, epsilon):
    """Simplifie une polyligne ouverte en gardant les points qui s'écartent de plus de epsilon."""
    if len(points) < 3:
        return list(points)
    (x0, y0), (x1, y1) = points[0], points[-1]
    dx, dy = x1 - x0, y1 - y0
    norm = (dx * dx + dy * dy) ** 0.5
    best_d, best_i = -1.0, 0
    for i in range(1, len(points) - 1):
        px, py = points[i]
        if norm == 0:
            d = ((px - x0) ** 2 + (py - y0) ** 2) ** 0.5
        else:
            d = abs(dy * px - dx * py + x1 * y0 - y1 * x0) / norm
        if d > best_d:
            best_d, best_i = d, i
    if best_d > epsilon:
        left = douglas_peucker(points[:best_i + 1], epsilon)
        right = douglas_peucker(points[best_i:], epsilon)
        return left[:-1] + right
    return [points[0], points[-1]]


def outline_for(path):
    img = Image.open(path).convert('RGBA')
    alpha = np.array(img.split()[-1]) > ALPHA_THRESHOLD
    comp = largest_component(alpha)
    boundary = trace_outline(comp)
    closed = boundary + [boundary[0]]
    simple = douglas_peucker(closed, SIMPLIFY_EPSILON)
    if simple[-1] == simple[0]:
        simple = simple[:-1]
    if len(simple) > MAX_POINTS:
        sys.exit(f'{path} : {len(simple)} points, maximum {MAX_POINTS}')
    width, height = img.size
    norm = [((x + 0.5) / width, (y + 0.5) / height) for x, y in simple]
    return width, height, norm


def render(name, width, height, points):
    lines = [f"  '{name}': MascotOutlineData(", f'    width: {width},', f'    height: {height},', '    points: [']
    for x, y in points:
        lines.append(f'      Offset({x:.4f}, {y:.4f}),')
    lines.append('    ],')
    lines.append('  ),')
    return '\n'.join(lines)


HEADER = """// GÉNÉRÉ par tool/gen_mascot_outlines.py : ne pas modifier à la main.
// Contours extérieurs des mascottes, coordonnées normalisées entre 0 et 1.
import 'dart:ui' show Offset;

/// Contour d'une mascotte : dimensions de la photo source et points du contour.
class MascotOutlineData {
  const MascotOutlineData({
    required this.width,
    required this.height,
    required this.points,
  });

  /// Largeur de l'image source, en pixels.
  final int width;

  /// Hauteur de l'image source, en pixels.
  final int height;

  /// Points du contour fermé, dans l'ordre, normalisés entre 0 et 1.
  final List<Offset> points;
}

const mascotOutlines = <String, MascotOutlineData>{
"""


def main():
    names = ['belote', 'chkobba', 'domino', 'rami']
    blocks = []
    for name in names:
        path = os.path.join(MASCOT_DIR, f'{name}.png')
        width, height, pts = outline_for(path)
        print(f'{name}: {width}x{height}, {len(pts)} points', file=sys.stderr)
        blocks.append(render(name, width, height, pts))
    with open(OUT_FILE, 'w', encoding='utf-8') as f:
        f.write(HEADER + '\n'.join(blocks) + '\n};\n')
    print(f'écrit : {OUT_FILE}', file=sys.stderr)


if __name__ == '__main__':
    main()
