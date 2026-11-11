#!/usr/bin/env python3
"""Make sharper, bigger copies of the game's pictures with classic resizing (no AI):
Lanczos upscaling (alpha handled premultiplied) followed by a light unsharp mask.
Output: CookieClicker/sharp/<app path>.webp and sharp/manifest.json (app path -> original [w, h])."""
import json, os, sys
from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'CookieClicker')
OUT = os.path.join(ROOT, 'sharp')
SOURCES = [('www/img', 'img'), ('mods/minigames/img', 'mgimg')]
EXTRA = [('mods/icons.png', 'override/icons.png'), ('mods/buildings.png', 'override/buildings.png')]
# huge sheets get 2x so the phone's memory stays comfortable
SCALE = {'override/icons.png': 2, 'img/starbg.jpg': 2}
SKIP = {'perfectCookie.png', 'icons.png', 'buildings.png'}  # the big cookie keeps its own sharper version; the app's own sheets replace these

def sharpen(src, scale):
    im = Image.open(src)
    has_alpha = im.mode in ('RGBA', 'LA', 'P') and (im.mode != 'P' or 'transparency' in im.info)
    im = im.convert('RGBA' if has_alpha else 'RGB')
    w, h = im.size
    big = im.resize((w * scale, h * scale), Image.LANCZOS)
    rgb = big.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1.5 * scale / 2, percent=70, threshold=2))
    if has_alpha:
        rgb.putalpha(big.getchannel('A'))
    return rgb, (w, h)

def main():
    manifest = {}
    jobs = []
    for d, app in SOURCES:
        for f in sorted(os.listdir(os.path.join(ROOT, d))):
            if f.lower().endswith(('.png', '.jpg')) and f not in SKIP:
                jobs.append((os.path.join(ROOT, d, f), app + '/' + f))
    for s, app in EXTRA:
        jobs.append((os.path.join(ROOT, s), app))
    for src, app in jobs:
        try:
            img, size = sharpen(src, SCALE.get(app, 4))
        except Exception as e:
            print('skip', app, e); continue
        dst = os.path.join(OUT, app.rsplit('.', 1)[0] + '.webp')
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        img.save(dst, 'WEBP', quality=90, alpha_quality=100, method=6)
        manifest[app] = list(size)
    with open(os.path.join(OUT, 'manifest.json'), 'w') as f:
        json.dump(manifest, f, indent=0, sort_keys=True)
    print(len(manifest), 'pictures')

main()
