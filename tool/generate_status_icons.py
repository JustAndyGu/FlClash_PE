#!/usr/bin/env python3
"""Regenerate the tray and app icons from assets_source with resvg.

    pip install resvg_py
    python tool/generate_status_icons.py

Run it from the repository root; it rewrites the files under
assets/images/tray/ and windows/runner/resources/. The renderer is not librsvg,
so the PNG bytes differ from what the Dart script emits.
"""

from __future__ import annotations

import base64
import re
import struct
from pathlib import Path
from collections.abc import Sequence

import resvg_py

SOURCE_DIR = Path('assets_source/images/icon')
UNIX_DIR = Path('assets/images/tray/unix')
WINDOWS_DIR = Path('assets/images/tray/windows')
MACOS_DIR = Path('assets/images/tray/macos')
APP_SOURCE = Path('assets/images/icon.png')
APP_OUTPUT = Path('windows/runner/resources/app_icon.ico')

# status_1_b is a black variant of the stopped glyph, kept for light tray
# backgrounds on Linux and Windows, so it needs the same UNIX/WINDOWS outputs.
STATUS_ICONS = ('status_1', 'status_1_b', 'status_2', 'status_3', 'status_4')
# macOS draws its menu bar icon as a template, where color is lost.
MACOS_SOURCES = {'status_1': 'glyph.svg', 'status_4': 'status_4.svg'}

TRAY_BASE = 18
TRAY_SCALES = (1, 2, 3, 4)
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)
TRAY_ICO_SIZES = (16, 20, 24, 32, 40, 48, 64)

MONOCHROME = re.compile(r'\b(fill|stroke)="(?!none")[^"]*"')


def render(svg: str, size: int) -> bytes:
    return resvg_py.svg_to_bytes(svg_string=svg, width=size, height=size)


def write_pngs(svg: str, name: str, output_dir: Path) -> None:
    for scale in TRAY_SCALES:
        folder = output_dir if scale == 1 else output_dir / f'{scale}.0x'
        folder.mkdir(parents=True, exist_ok=True)
        output = folder / f'{name}.png'
        output.write_bytes(render(svg, TRAY_BASE * scale))
        print(f'wrote {output}')


def write_ico(svg: str, output: Path, sizes: Sequence[int]) -> None:
    images = [(size, render(svg, size)) for size in sizes]
    directory = bytearray(struct.pack('<HHH', 0, 1, len(images)))
    blob = bytearray()
    offset = 6 + 16 * len(images)
    for size, png in images:
        dimension = 0 if size == 256 else size
        directory += struct.pack(
            '<BBBBHHII',
            dimension,
            dimension,
            0,
            0,
            1,
            32,
            len(png),
            offset,
        )
        blob += png
        offset += len(png)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(bytes(directory + blob))
    print(f'wrote {output}')


def main() -> None:
    for name in STATUS_ICONS:
        svg = (SOURCE_DIR / f'{name}.svg').read_text(encoding='utf-8')
        write_pngs(svg, name, UNIX_DIR)
        write_ico(svg, WINDOWS_DIR / f'{name}.ico', [256])

#     for name, filename in MACOS_SOURCES.items():
#         source = (SOURCE_DIR / filename).read_text(encoding='utf-8')
#         write_pngs(MONOCHROME.sub(r'\1="#000000"', source), name, MACOS_DIR)

#     data = base64.b64encode(APP_SOURCE.read_bytes()).decode()
#     wrapper = (
#         '<svg xmlns="http://www.w3.org/2000/svg" '
#         'xmlns:xlink="http://www.w3.org/1999/xlink" '
#         'width="256" height="256" viewBox="0 0 256 256">'
#         f'<image xlink:href="data:image/png;base64,{data}" '
#         'width="256" height="256"/>'
#         '</svg>'
#     )
#     write_ico(wrapper, APP_OUTPUT, ICO_SIZES)


if __name__ == '__main__':
    main()
