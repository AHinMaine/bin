#!/usr/bin/env python3
"""
Export photos from an Apple Photos album and generate a standalone,
full-screen slideshow HTML file you can open directly in a browser.

Requires osxphotos: pip3 install osxphotos

Usage:
    python3 build_slideshow.py                 # export originals, no JPEG conversion
    python3 build_slideshow.py --convert-to-jpeg --jpeg-quality 0.9
    python3 build_slideshow.py --purge          # empty the output dir first, then export

Edit the CONFIG block below for album name, output dir, interval, and color.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------- CONFIG ----------------
ALBUM_NAME = "Family Slideshow"
OUTPUT_DIR = Path.home() / "Desktop" / "family_slideshow"
IMAGES_SUBDIR = "images"
SLIDE_INTERVAL_SECONDS = 6
BACKGROUND_COLOR = "#000000"   # any CSS color: "#000", "black", "rgb(20,20,20)"
SHUFFLE = False
# -----------------------------------------

# HEIC/HEIF are included because Safari renders them natively in <img> tags.
# Chrome does not, so if you switch browsers later, use --convert-to-jpeg.
IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".tiff", ".tif", ".gif", ".bmp", ".webp",
    ".heic", ".heif",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--convert-to-jpeg",
        action="store_true",
        help="Convert non-JPEG originals (e.g. HEIC) to JPEG on export. "
             "Off by default, since Safari renders HEIC natively.",
    )
    parser.add_argument(
        "--jpeg-quality",
        type=float,
        default=0.9,
        help="JPEG quality 0.0-1.0, only used with --convert-to-jpeg. Default 0.9.",
    )
    parser.add_argument(
        "--purge",
        action="store_true",
        help="Delete and recreate the output directory before exporting.",
    )
    return parser.parse_args()


def purge_output_dir():
    if OUTPUT_DIR.exists():
        print(f"Purging {OUTPUT_DIR}")
        shutil.rmtree(OUTPUT_DIR)


def export_album(convert_to_jpeg: bool, jpeg_quality: float) -> Path:
    images_dir = OUTPUT_DIR / IMAGES_SUBDIR
    images_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "osxphotos", "export", str(images_dir),
        "--album", ALBUM_NAME,
    ]
    if convert_to_jpeg:
        cmd += ["--convert-to-jpeg", "--jpeg-quality", str(jpeg_quality)]

    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(
            "osxphotos export failed. Is it installed? Try: pip3 install osxphotos",
            file=sys.stderr,
        )
        sys.exit(1)

    return images_dir


def build_html(images_dir: Path) -> Path:
    files = sorted(
        p.name for p in images_dir.iterdir()
        if p.suffix.lower() in IMAGE_EXTENSIONS
    )

    if not files:
        print(f"No images found in {images_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(files)} images.")

    file_list_js = ",\n".join(f'  "{IMAGES_SUBDIR}/{name}"' for name in files)

    html = HTML_TEMPLATE.format(
        file_list=file_list_js,
        interval_ms=SLIDE_INTERVAL_SECONDS * 1000,
        bg_color=BACKGROUND_COLOR,
        shuffle_js="true" if SHUFFLE else "false",
    )

    out_path = OUTPUT_DIR / "slideshow.html"
    out_path.write_text(html)
    print(f"Wrote {out_path}")
    return out_path


HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Family Slideshow</title>
<style>
  html, body {{
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    background-color: {bg_color};
    overflow: hidden;
  }}
  #stage {{
    width: 100vw;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: {bg_color};
  }}
  #stage img {{
    max-width: 100vw;
    max-height: 100vh;
    width: auto;
    height: auto;
    object-fit: contain;
    transition: opacity 0.8s ease-in-out;
  }}
  #hint {{
    position: fixed;
    bottom: 12px;
    right: 16px;
    color: rgba(255,255,255,0.35);
    font: 12px -apple-system, sans-serif;
    pointer-events: none;
  }}
</style>
</head>
<body>
<div id="stage"><img id="photo" src="" alt=""></div>
<div id="hint">click for fullscreen &middot; space to pause &middot; esc to exit</div>

<script>
const images = [
{file_list}
];

const SHUFFLE = {shuffle_js};
const INTERVAL_MS = {interval_ms};

// order is the playback sequence. When SHUFFLE is off, it's just images
// in file order. When SHUFFLE is on, it's a full random permutation of
// every image, walked in order, so nothing repeats until the whole list
// has been shown once.
function shuffleArray(arr) {{
  for (let i = arr.length - 1; i > 0; i--) {{
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }}
}}

let order = images.slice();
if (SHUFFLE) {{
  shuffleArray(order);
}}

let idx = 0;
let paused = false;
let timer = null;
const img = document.getElementById('photo');

function showImage(i) {{
  img.style.opacity = 0;
  setTimeout(() => {{
    img.src = order[i];
    img.style.opacity = 1;
  }}, 200);
}}

function next() {{
  idx += 1;
  if (idx >= order.length) {{
    idx = 0;
    // Reached the end of the pass. Reshuffle for the next lap, but if
    // SHUFFLE landed the same image at the start that just finished at
    // the end, swap it elsewhere so you never see the same photo twice
    // back to back across the loop boundary.
    if (SHUFFLE && order.length > 1) {{
      const lastShown = order[order.length - 1];
      shuffleArray(order);
      if (order[0] === lastShown) {{
        const swapIdx = 1 + Math.floor(Math.random() * (order.length - 1));
        [order[0], order[swapIdx]] = [order[swapIdx], order[0]];
      }}
    }}
  }}
  showImage(idx);
}}

function startTimer() {{
  stopTimer();
  timer = setInterval(next, INTERVAL_MS);
}}

function stopTimer() {{
  if (timer) clearInterval(timer);
  timer = null;
}}

document.body.addEventListener('click', () => {{
  if (!document.fullscreenElement) {{
    document.documentElement.requestFullscreen().catch(() => {{}});
  }}
}});

document.addEventListener('keydown', (e) => {{
  if (e.code === 'Space') {{
    paused = !paused;
    if (paused) stopTimer(); else startTimer();
    e.preventDefault();
  }} else if (e.code === 'ArrowRight') {{
    next();
  }} else if (e.code === 'ArrowLeft') {{
    idx = (idx - 1 + order.length) % order.length;
    showImage(idx);
  }}
}});

showImage(idx);
startTimer();
</script>
</body>
</html>
"""


if __name__ == "__main__":
    args = parse_args()

    if args.purge:
        purge_output_dir()

    images_dir = export_album(args.convert_to_jpeg, args.jpeg_quality)
    html_path = build_html(images_dir)
    print(f"\nDone. Open this file in Safari, then click once to go fullscreen:\n  {html_path}")
