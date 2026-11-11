#!/usr/bin/env python3
"""Use the AI-enlarged pictures (CookieClicker/hd) but give back every pixel of the original:
iterative back-projection makes each block of the big picture average to exactly the original pixel,
so detail the AI smoothed away or changed comes back while the AI's extra sharpness stays.
Writes CookieClicker/sharp/<app path>.webp (+ manifest), replacing the classic-resize copies for those pictures."""
import json, os, sys
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'CookieClicker')
OUT = os.path.join(ROOT, 'sharp')
OVERRIDE = {'icons.png': 'mods/icons.png', 'buildings.png': 'mods/buildings.png'}
KEEP_AI_AS_IS = {'perfectCookie.png'}

def premul(a):
    a = a.astype(np.float32) / 255
    if a.shape[2] == 4:
        a[..., :3] *= a[..., 3:4]
    return a

def unpremul(a):
    a = np.clip(a, 0, 1)
    if a.shape[2] == 4:
        al = a[..., 3:4]
        a[..., :3] = np.where(al > 1e-4, a[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)

def down(H, f):
    h, w, c = H.shape
    return H.reshape(h // f, f, w // f, f, c).mean(axis=(1, 3))

def up_smooth(E, f):
    h, w, c = E.shape
    return np.stack([np.asarray(Image.fromarray(E[..., i]).resize((w * f, h * f), Image.BICUBIC)) for i in range(c)], axis=2)

def up_nearest(E, f):
    return E.repeat(f, axis=0).repeat(f, axis=1)

def fix(orig_path, ai_path):
    o = Image.open(orig_path)
    alpha = o.mode in ('RGBA', 'LA') or (o.mode == 'P' and 'transparency' in o.info)
    mode = 'RGBA' if alpha else 'RGB'
    O = premul(np.asarray(o.convert(mode)))
    ai = Image.open(ai_path).convert(mode)
    f = max(1, round(ai.size[0] / o.size[0]))
    ai = ai.resize((o.size[0] * f, o.size[1] * f), Image.LANCZOS) if ai.size != (o.size[0] * f, o.size[1] * f) else ai
    H = premul(np.asarray(ai))
    for _ in range(8):
        H = H + up_smooth(O - down(H, f), f)
    H = H + up_nearest(O - down(H, f), f)   # exact: every block averages to its original pixel
    return Image.fromarray(unpremul(H), mode), o.size, f

def main():
    hd = json.load(open(os.path.join(ROOT, 'hd', 'manifest.json')))
    man_p = os.path.join(OUT, 'manifest.json')
    man = json.load(open(man_p))
    names = sys.argv[1:] or sorted(hd)
    for name in names:
        if name in KEEP_AI_AS_IS:
            continue
        if name in OVERRIDE:
            src, app = OVERRIDE[name], 'override/' + name
        elif os.path.exists(os.path.join(ROOT, 'www/img', name)):
            src, app = 'www/img/' + name, 'img/' + name
        elif os.path.exists(os.path.join(ROOT, 'mods/minigames/img', name)):
            src, app = 'mods/minigames/img/' + name, 'mgimg/' + name
        else:
            print('no original for', name); continue
        osrc = os.path.join(ROOT, src)
        if Image.open(osrc).size != tuple(int(v) for v in hd[name]):
            print('size differs, skipped', name); continue
        img, size, f = fix(osrc, os.path.join(ROOT, 'hd', name.rsplit('.', 1)[0] + '.webp'))
        dst = os.path.join(OUT, app.rsplit('.', 1)[0] + '.webp')
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        img.save(dst, 'WEBP', quality=92, alpha_quality=100, method=6)
        man[app] = list(size)
        print(app, f, flush=True)
    json.dump(man, open(man_p, 'w'), indent=0, sort_keys=True)

main()
