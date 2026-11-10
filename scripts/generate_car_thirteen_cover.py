#!/usr/bin/env python3
"""Deterministic cover art for Episode 02, The Thirteenth Car.

A night platform in space: the frosted thirteenth car glows in the foreground,
the rest of the Marigold recedes along the lantern line, Old Gold spreads her
wings across the sky and the young coupler raises a hand lamp at the door.

The train is built from 3D boxes and projected in perspective; flat textures are
painted per car and warped onto each side. Needs Pillow, numpy and the Caladea
and Inter fonts (paths below). Writes Starport/Assets.xcassets/cover-car-thirteen.

    python3 scripts/generate_car_thirteen_cover.py
"""
import json
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Starport" / "Assets.xcassets" / "cover-car-thirteen.imageset"
TITLE_FONT = "/usr/share/fonts/truetype/crosextra/Caladea-Bold.ttf"
LABEL_FONT = "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf"

W, H = 900, 1350
SS = 2                       # supersampling
F = 760.0 * SS               # focal length in pixels
CX, CY = 300.0 * SS, 880.0 * SS   # vanishing point
RNG = random.Random(13)

GOLD, AMBER, PALE = (247, 190, 92), (226, 142, 54), (255, 236, 196)
ICE, FROST = (176, 220, 240), (226, 243, 252)
CAR, CAR_DARK = (198, 146, 66), (104, 70, 34)


# ───────────────────────── helpers ─────────────────────────

def project(x, y, z):
    return (CX + F * x / z, CY - F * y / z)


def blank():
    return Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))


def over(base, layer, blur=0):
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur * SS))
    base.alpha_composite(layer)


def glow(base, x, y, r, color, alpha):
    layer = blank()
    ImageDraw.Draw(layer).ellipse((x - r * SS, y - r * SS, x + r * SS, y + r * SS), fill=color + (alpha,))
    over(base, layer, blur=r * 0.5)


def perspective_coeffs(dst, src):
    """Coefficients mapping output quad `dst` back to input quad `src` for Image.transform."""
    rows, rhs = [], []
    for (x, y), (u, v) in zip(dst, src):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); rhs.append(u)
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y]); rhs.append(v)
    return np.linalg.solve(np.array(rows, float), np.array(rhs, float)).tolist()


def warp(base, texture, quad):
    """Paint a flat RGBA texture onto a projected quad (TL, TR, BR, BL)."""
    w, h = texture.size
    coeffs = perspective_coeffs(quad, [(0, 0), (w, 0), (w, h), (0, h)])
    warped = texture.transform(base.size, Image.PERSPECTIVE, coeffs, Image.BICUBIC)
    mask = Image.new("L", base.size, 0)
    ImageDraw.Draw(mask).polygon(quad, fill=255)
    warped.putalpha(Image.fromarray(np.minimum(np.array(warped.getchannel("A")), np.array(mask))))
    base.alpha_composite(warped)


# ───────────────────────── sky ─────────────────────────

def sky():
    y = np.linspace(0, 1, H * SS)[:, None]
    top, mid, low = np.array([6, 10, 26]), np.array([16, 30, 58]), np.array([40, 52, 82])
    col = np.where(y < 0.55, top + (mid - top) * (y / 0.55), mid + (low - mid) * ((y - 0.55) / 0.45))
    img = np.repeat(col[:, None, :], W * SS, axis=1).reshape(H * SS, W * SS, 3)
    base = Image.fromarray(img.astype(np.uint8)).convert("RGBA")

    # nebula wash
    neb = blank(); d = ImageDraw.Draw(neb)
    for cx, cy, rx, ry, c, a in [(700, 420, 520, 260, (40, 92, 120), 70), (150, 260, 380, 200, (70, 50, 110), 60),
                                 (520, 640, 460, 150, (90, 70, 60), 45), (820, 150, 300, 200, (30, 70, 110), 50)]:
        d.ellipse([v * SS for v in (cx - rx, cy - ry, cx + rx, cy + ry)], fill=c + (a,))
    over(base, neb, blur=110)

    # stars, denser in a diagonal band
    st = blank(); d = ImageDraw.Draw(st)
    for _ in range(1500):
        x, yy = RNG.uniform(0, W), RNG.uniform(0, 900)
        band = math.exp(-((yy - (650 - x * 0.55)) / 160) ** 2)
        if RNG.random() > 0.25 + 0.75 * band:
            continue
        r = RNG.choice([0.5, 0.6, 0.7, 0.9, 1.1, 1.5]) * SS
        a = RNG.randint(80, 255)
        tint = RNG.choice([(255, 255, 255), (210, 225, 255), (255, 236, 210)])
        d.ellipse((x * SS - r, yy * SS - r, x * SS + r, yy * SS + r), fill=tint + (a,))
    over(base, st)
    for x, yy in [(120, 470), (780, 600), (560, 380), (60, 720)]:
        glow(base, x * SS, yy * SS, 9, (230, 240, 255), 160)
    return base


def old_gold(base):
    """The great lantern ray gliding over the platform, lit from within."""
    cx, cy, span = 360 * SS, 600 * SS, 760 * SS
    tilt = math.radians(150)    # head toward the train, tail trailing up and away

    def at(px, py):
        ca, sa = math.cos(tilt), math.sin(tilt)
        return (cx + (px * ca - py * sa) * span, cy + (px * sa + py * ca) * span)

    body = [(0, -0.2), (0.12, -0.17), (0.26, -0.11), (0.4, -0.04), (0.5, 0.02), (0.38, 0.05), (0.24, 0.08),
            (0.1, 0.12), (0.045, 0.17), (0.012, 0.22), (0.0, 0.52), (-0.012, 0.22), (-0.045, 0.17), (-0.1, 0.12),
            (-0.24, 0.08), (-0.38, 0.05), (-0.5, 0.02), (-0.4, -0.04), (-0.26, -0.11), (-0.12, -0.17)]
    poly = [at(*p) for p in body]
    halo = blank()
    ImageDraw.Draw(halo).polygon(poly, fill=(250, 180, 90, 120))
    over(base, halo, blur=50)
    fill = blank()
    ImageDraw.Draw(fill).polygon(poly, fill=(128, 92, 70, 130))
    over(base, fill, blur=3)
    core = blank()
    ccx, ccy = at(0, -0.03)
    cr = 0.12 * span
    ImageDraw.Draw(core).ellipse((ccx - cr, ccy - cr, ccx + cr, ccy + cr), fill=(255, 214, 140, 170))
    over(base, core, blur=48)
    rim = blank()
    ImageDraw.Draw(rim).line(poly + [poly[0]], fill=PALE + (210,), width=2 * SS, joint="curve")
    over(base, rim, blur=1.5)
    over(base, rim, blur=10)
    veins = blank(); d = ImageDraw.Draw(veins)
    for side in (-1, 1):
        for k in range(6):
            p0 = at(side * 0.02, -0.15 + k * 0.045)
            p1 = at(side * (0.14 + k * 0.01), -0.13 + k * 0.05)
            p2 = at(side * (0.46 - k * 0.07), 0.0 + k * 0.025)
            d.line([p0, p1, p2], fill=GOLD + (240 - k * 20,), width=int((4 - k * 0.4) * SS), joint="curve")
    d.line([at(0, -0.19), at(0, 0.5)], fill=PALE + (220,), width=3 * SS)
    over(base, veins, blur=1.5)
    over(base, veins, blur=12)
    # sparks trailing off the wingtips
    sp = blank(); d = ImageDraw.Draw(sp)
    for side in (-1, 1):
        tx, ty = at(side * 0.5, 0.02)
        for i in range(26):
            x = tx + side * RNG.uniform(0, 90) * SS
            y = ty + RNG.uniform(-30, 60) * SS
            r = RNG.uniform(0.8, 2.4) * SS
            d.ellipse((x - r, y - r, x + r, y + r), fill=PALE + (RNG.randint(120, 230),))
    over(base, sp, blur=0.6)


def lantern_line(base):
    """Golden beacons strung away toward the vanishing point; one is dark."""
    pts = []
    for i, z in enumerate([10, 14, 19, 26, 36, 50, 70, 100]):
        x, y = project(9.0, 8.5 - z * 0.03, z)
        pts.append((x, y, z, i))
    thread = blank()
    ImageDraw.Draw(thread).line([(x, y) for x, y, _, _ in pts], fill=GOLD + (70,), width=2 * SS, joint="curve")
    over(base, thread, blur=1.5)
    for x, y, z, i in pts:
        r = max(2.2, 34 / z * 3.2)
        if i == 3:
            d = ImageDraw.Draw(base)
            d.ellipse((x - r * SS, y - r * SS, x + r * SS, y + r * SS), fill=(48, 56, 72, 255),
                      outline=(90, 100, 120, 255), width=SS)
            continue
        glow(base, x, y, r * 6, GOLD, 120)
        d = ImageDraw.Draw(base)
        d.ellipse((x - r * SS, y - r * SS, x + r * SS, y + r * SS), fill=PALE + (255,))


# ───────────────────────── train ─────────────────────────

X0, X1 = 2.4, 5.2            # train side faces the platform at X0
Y0, Y1 = -1.15, 1.85         # car floor and roof relative to the eye
PLAT = -1.6                  # platform level
CAR_LEN, GAP = 11.0, 1.1


def side_quad(z0, z1):
    return [project(X0, Y1, z1), project(X0, Y1, z0), project(X0, Y0, z0), project(X0, Y0, z1)]


def gold_texture(seed):
    rng = random.Random(seed)
    tw, th = 1100, 300
    t = Image.new("RGBA", (tw, th), CAR + (255,))
    d = ImageDraw.Draw(t)
    for y in range(th):
        k = y / th
        d.line([(0, y), (tw, y)], fill=tuple(int(c * (1.06 - 0.3 * k)) for c in CAR) + (255,))
    d.rectangle((0, 0, tw, 14), fill=(236, 196, 118, 255))
    d.rectangle((0, th - 46, tw, th - 34), fill=CAR_DARK + (255,))
    for px in range(0, tw, 110):
        d.line([(px, 16), (px, th - 48)], fill=(150, 104, 46, 255), width=3)
    for k in range(5):
        x = 60 + k * 205
        lit = rng.random() > 0.2
        d.rounded_rectangle((x, 70, x + 120, 150), radius=14,
                            fill=(255, 226, 160, 255) if lit else (70, 60, 50, 255), outline=CAR_DARK + (255,), width=5)
        if lit:
            d.line([(x + 60, 72), (x + 60, 148)], fill=(220, 170, 90, 255), width=4)
    for x in range(30, tw, 40):
        d.ellipse((x - 3, th - 40 - 3, x + 3, th - 40 + 3), fill=(80, 52, 24, 255))
    return t


def frost_texture():
    """Car 13: no windows, frost from end to end, a door with gold light leaking round it."""
    rng = random.Random(1313)
    tw, th = 1100, 300
    t = Image.new("RGBA", (tw, th))
    a = np.zeros((th, tw, 3))
    yy, xx = np.mgrid[0:th, 0:tw]
    a[...] = np.array(ICE) * 0.82
    a += (np.array(FROST) - np.array(ICE) * 0.82) * (0.5 + 0.5 * np.sin(xx / 70.0 + yy / 45.0))[..., None] * 0.35
    a *= (1.05 - 0.28 * (yy / th))[..., None]
    t = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(t)
    d.rectangle((0, th - 46, tw, th - 34), fill=(110, 140, 162, 255))
    # frost swirl
    sw = Image.new("RGBA", (tw, th), (0, 0, 0, 0)); ds = ImageDraw.Draw(sw)
    cx, cy = 720, 140
    for k in range(70):
        ang = k * 0.38
        r = 10 + k * 5.2
        ds.arc((cx - r, cy - r * 0.7, cx + r, cy + r * 0.7), math.degrees(ang), math.degrees(ang) + 70,
               fill=(255, 255, 255, 150), width=3)
    sw = sw.filter(ImageFilter.GaussianBlur(1.2))
    t.alpha_composite(sw)
    # frost crystals
    cr = Image.new("RGBA", (tw, th), (0, 0, 0, 0)); dc = ImageDraw.Draw(cr)
    for _ in range(700):
        x, y = rng.uniform(0, tw), rng.uniform(0, th - 50)
        r = rng.uniform(3, 9)
        for k in range(6):
            ang = math.radians(k * 60 + rng.uniform(-8, 8))
            dc.line([(x, y), (x + math.cos(ang) * r, y + math.sin(ang) * r)], fill=(255, 255, 255, rng.randint(90, 220)), width=2)
    t.alpha_composite(cr.filter(ImageFilter.GaussianBlur(0.6)))
    # the door, with gold light leaking round its seams
    dx0, dx1, dy0, dy1 = 620, 820, 34, th - 52
    seam = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ImageDraw.Draw(seam).rounded_rectangle((dx0, dy0, dx1, dy1), radius=18, outline=GOLD + (255,), width=10)
    t.alpha_composite(seam.filter(ImageFilter.GaussianBlur(9)))
    t.alpha_composite(seam.filter(ImageFilter.GaussianBlur(2)))
    d.rounded_rectangle((dx0 + 5, dy0 + 5, dx1 - 5, dy1 - 5), radius=14, fill=(200, 230, 244, 255))
    # hand panel
    hx, hy = (dx0 + dx1) // 2, 150
    d.ellipse((hx - 30, hy - 30, hx + 30, hy + 30), fill=(255, 238, 200, 255), outline=AMBER + (255,), width=5)
    d.rounded_rectangle((hx - 13, hy - 4, hx + 13, hy + 20), radius=7, fill=AMBER + (255,))
    for i, fx in enumerate((-13, -6, 1, 8)):
        d.rounded_rectangle((hx + fx, hy - 20 + (3 if i in (0, 3) else 0), hx + fx + 6, hy), radius=3, fill=AMBER + (255,))
    # stencilled number
    font = ImageFont.truetype(TITLE_FONT, 190)
    lab = Image.new("RGBA", (tw, th), (0, 0, 0, 0)); dl = ImageDraw.Draw(lab)
    dl.text((300, 22), "13", font=font, fill=(84, 118, 148, 230))
    dl.text((306, 222), "NOT ON THE LIST", font=ImageFont.truetype(LABEL_FONT, 22), fill=(84, 118, 148, 210))
    t.alpha_composite(lab)
    return t


def end_face(base, z, color, edge):
    q = [project(X0, Y1, z), project(X1, Y1, z), project(X1, Y0, z), project(X0, Y0, z)]
    ImageDraw.Draw(base).polygon(q, fill=color + (255,), outline=edge + (255,))


def train(base):
    cars = []
    z = 2.4
    for i in range(9):
        cars.append((z, z + CAR_LEN))
        z += CAR_LEN + GAP
    # track and rail glow under the train
    rail = blank(); d = ImageDraw.Draw(rail)
    for x in (X0 + 0.45, X1 - 0.45):
        d.line([project(x, PLAT + 0.05, 2.2), project(x, PLAT + 0.05, 140)], fill=GOLD + (200,), width=4 * SS)
    over(base, rail, blur=6)
    over(base, rail, blur=1)

    # engine headlight at the far end
    ex, ey = project(X0 + 1.5, 0.3, cars[-1][1] + 4)
    glow(base, ex, ey, 70, PALE, 170)
    glow(base, ex, ey, 22, (255, 255, 255), 230)

    for i in reversed(range(len(cars))):
        z0, z1 = cars[i]
        quad = side_quad(z0, z1)
        if i == 0:
            continue
        warp(base, gold_texture(i), quad)
        # coupling to the next car toward the camera
        d = ImageDraw.Draw(base)
        a, b = project(X0, -0.3, z0 - GAP), project(X0, -0.3, z0)
        d.line([a, b], fill=CAR_DARK + (255,), width=max(2, int(18 / z0 * SS * 3)))
        end_face(base, z0, (120, 86, 44), CAR_DARK)

    # car 13, nearest and frosted
    z0, z1 = cars[0]
    q = side_quad(z0, z1)
    glow(base, *project(X0, 0.3, z0 + 5), 300, ICE, 70)
    warp(base, frost_texture(), q)
    # cold mist rolling off the car onto the platform
    mist = blank(); dm = ImageDraw.Draw(mist)
    for _ in range(26):
        zz = RNG.uniform(z0, z1)
        x, y = project(X0 - RNG.uniform(0, 1.4), PLAT + RNG.uniform(0.0, 0.5), zz)
        r = RNG.uniform(60, 140) * SS * 4 / zz
        dm.ellipse((x - r * 1.6, y - r * 0.5, x + r * 1.6, y + r * 0.5), fill=(214, 236, 248, 46))
    over(base, mist, blur=18)
    # Ember peeking out of the roof vent
    vx, vy = project(X0 + 0.3, Y1 + 0.08, z0 + 6.5)
    glow(base, vx, vy, 60, GOLD, 170)
    glow(base, vx, vy, 16, PALE, 255)


def platform(base):
    d = ImageDraw.Draw(base)
    near, far = 1.6, 160
    poly = [project(-30, PLAT, near), project(X0 - 0.15, PLAT, near), project(X0 - 0.15, PLAT, far), project(-30, PLAT, far)]
    d.polygon(poly, fill=(30, 36, 52, 255))
    # tiles
    for k in range(1, 40):
        z = near * (1.14 ** k)
        d.line([project(-30, PLAT, z), project(X0 - 0.15, PLAT, z)], fill=(40, 48, 66, 255), width=SS)
    for x in np.arange(-12, X0, 1.2):
        d.line([project(x, PLAT, near), project(x, PLAT, far)], fill=(40, 48, 66, 255), width=SS)
    # gold safety line along the edge
    edge = blank()
    ImageDraw.Draw(edge).polygon([project(X0 - 0.75, PLAT, near), project(X0 - 0.45, PLAT, near),
                                  project(X0 - 0.45, PLAT, far), project(X0 - 0.75, PLAT, far)], fill=GOLD + (150,))
    over(base, edge)
    over(base, edge, blur=8)
    # lamp posts on the platform
    for z in (9, 21, 40):
        b, t = project(-2.2, PLAT, z), project(-2.2, 2.4, z)
        d.line([b, t], fill=(70, 78, 96, 255), width=max(SS, int(70 / z * SS)))
        glow(base, t[0], t[1], 360 / z, GOLD, 150)
        d.ellipse((t[0] - 40 / z * SS, t[1] - 40 / z * SS, t[0] + 40 / z * SS, t[1] + 40 / z * SS), fill=PALE + (255,))


# ───────────────────────── the coupler ─────────────────────────

def coupler(base):
    """The young coupler from behind, lamp raised toward the door."""
    s = SS
    fig = blank(); d = ImageDraw.Draw(fig)
    hx, hy = 210, 1010           # head centre
    jacket, shade, trim = (196, 112, 52), (140, 74, 34), (238, 184, 92)
    # legs and back, cropped by the bottom edge
    d.polygon([(p[0] * s, p[1] * s) for p in [(120, 1350), (128, 1200), (300, 1200), (310, 1350)]], fill=(34, 38, 56, 255))
    d.rounded_rectangle((108 * s, 1066 * s, 318 * s, 1300 * s), radius=46 * s, fill=jacket + (255,))
    d.rounded_rectangle((108 * s, 1066 * s, 166 * s, 1300 * s), radius=40 * s, fill=shade + (255,))
    d.rectangle((140 * s, 1066 * s, 166 * s, 1300 * s), fill=shade + (255,))
    d.rectangle((112 * s, 1196 * s, 318 * s, 1212 * s), fill=(60, 50, 44, 255))
    d.line([(214 * s, 1072 * s), (214 * s, 1196 * s)], fill=shade + (255,), width=3 * s)
    d.rectangle((150 * s, 1112 * s, 280 * s, 1120 * s), fill=trim + (255,))
    # left arm hanging
    d.polygon([(p[0] * s, p[1] * s) for p in [(124, 1100), (104, 1110), (92, 1236), (114, 1240), (130, 1140)]], fill=shade + (255,))
    # right arm raised toward the car, holding the lamp
    d.polygon([(p[0] * s, p[1] * s) for p in [(272, 1080), (300, 1096), (382, 1012), (370, 994)]], fill=jacket + (255,))
    d.polygon([(p[0] * s, p[1] * s) for p in [(370, 994), (382, 1012), (424, 964), (414, 950)]], fill=shade + (255,))
    # collar and neck
    d.ellipse(((hx - 34) * s, (hy + 30) * s, (hx + 34) * s, (hy + 66) * s), fill=(150, 104, 80, 255))
    d.polygon([(p[0] * s, p[1] * s) for p in [(160, 1074), (182, 1044), (240, 1044), (262, 1074)]], fill=trim + (255,))
    # head, from behind: dark hair with a bun
    d.ellipse(((hx - 44) * s, (hy - 50) * s, (hx + 44) * s, (hy + 46) * s), fill=(42, 30, 28, 255))
    d.ellipse(((hx - 22) * s, (hy - 80) * s, (hx + 22) * s, (hy - 38) * s), fill=(46, 32, 30, 255))
    d.arc(((hx - 44) * s, (hy - 50) * s, (hx + 44) * s, (hy + 46) * s), 300, 40, fill=(226, 160, 92, 255), width=4 * s)
    d.ellipse(((hx + 36) * s, (hy - 4) * s, (hx + 50) * s, (hy + 18) * s), fill=(190, 132, 100, 255))
    over(base, fig, blur=0.5)
    # rim light from the frost car
    rim = blank(); dr = ImageDraw.Draw(rim)
    dr.arc(((hx - 44) * s, (hy - 50) * s, (hx + 44) * s, (hy + 46) * s), 280, 60, fill=ICE + (230,), width=3 * s)
    dr.line([(300 * s, 1100 * s), (318 * s, 1230 * s)], fill=ICE + (200,), width=3 * s)
    over(base, rim, blur=1.5)
    # the hand lamp and its beam
    lx, ly = 430 * s, 952 * s
    beam = blank()
    door = project(X0, 0.25, 6.2)
    ImageDraw.Draw(beam).polygon([(lx, ly - 10 * s), door[0:1] + (door[1] - 160 * s,), (door[0], door[1] + 160 * s), (lx, ly + 10 * s)],
                                 fill=PALE + (60,))
    over(base, beam, blur=22)
    glow(base, lx, ly, 120, GOLD, 170)
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((lx - 18 * s, ly - 22 * s, lx + 18 * s, ly + 22 * s), radius=8 * s, fill=(255, 244, 212, 255),
                        outline=(120, 86, 40, 255), width=3 * s)
    d.arc((lx - 16 * s, ly - 44 * s, lx + 16 * s, ly - 14 * s), 180, 360, fill=(120, 86, 40, 255), width=3 * s)


# ───────────────────────── title ─────────────────────────

def gradient_text(base, text, font, y, top=(255, 233, 176), bottom=(226, 150, 60), tracking=0, glow_alpha=150):
    """Centered text with a vertical gold gradient, dark outline and soft glow."""
    widths = [font.getbbox(ch)[2] - font.getbbox(ch)[0] for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (W * SS - total) / 2
    mask = Image.new("L", base.size, 0); dm = ImageDraw.Draw(mask)
    cx = x
    for ch, w in zip(text, widths):
        dm.text((cx - font.getbbox(ch)[0], y), ch, font=font, fill=255)
        cx += w + tracking
    bbox = mask.getbbox()
    if not bbox:
        return
    halo = Image.new("RGBA", base.size, GOLD + (0,))
    halo.putalpha(mask.point(lambda v: v * glow_alpha // 255))
    over(base, halo, blur=16)
    shadow = Image.new("RGBA", base.size, (10, 8, 20, 0))
    shadow.putalpha(mask.filter(ImageFilter.MaxFilter(7)).point(lambda v: v * 210 // 255))
    over(base, shadow, blur=1.2)
    y0, y1 = bbox[1], bbox[3]
    grad = np.zeros((base.size[1], base.size[0], 4), np.uint8)
    k = np.clip((np.arange(base.size[1]) - y0) / max(1, y1 - y0), 0, 1)[:, None]
    for c in range(3):
        grad[..., c] = (top[c] + (bottom[c] - top[c]) * k).astype(np.uint8)
    grad[..., 3] = np.array(mask)
    base.alpha_composite(Image.fromarray(grad))


def title(base):
    shade = blank()
    ImageDraw.Draw(shade).rectangle((0, 0, W * SS, 330 * SS), fill=(4, 6, 16, 120))
    over(base, shade, blur=60)
    small = ImageFont.truetype(TITLE_FONT, 46 * SS)
    big = ImageFont.truetype(TITLE_FONT, 132 * SS)
    car = ImageFont.truetype(TITLE_FONT, 150 * SS)
    tag = ImageFont.truetype(LABEL_FONT, 21 * SS)
    gradient_text(base, "THE", small, 40 * SS, tracking=14 * SS)
    gradient_text(base, "THIRTEENTH", big, 82 * SS, tracking=1 * SS)
    gradient_text(base, "CAR", car, 196 * SS, tracking=18 * SS)
    d = ImageDraw.Draw(base)
    text = "A STARPORT ADVENTURE"
    track = 5 * SS
    tw = sum(tag.getbbox(c)[2] - tag.getbbox(c)[0] for c in text) + track * (len(text) - 1)
    y = 380 * SS
    x = (W * SS - tw) / 2
    for side, x0 in ((-1, x - 22 * SS), (1, x + tw + 22 * SS)):
        d.line([(x0, y), (x0 + side * 120 * SS, y)], fill=GOLD + (210,), width=2 * SS)
        d.ellipse((x0 - 4 * SS, y - 4 * SS, x0 + 4 * SS, y + 4 * SS), fill=GOLD + (240,))
    for ch in text:
        d.text((x - tag.getbbox(ch)[0], y - 15 * SS), ch, font=tag, fill=(236, 226, 206, 240))
        x += tag.getbbox(ch)[2] - tag.getbbox(ch)[0] + track


# ───────────────────────── finish ─────────────────────────

def finish(base):
    img = base.convert("RGB")
    a = np.asarray(img).astype(np.float32) / 255
    # bloom
    bright = np.clip((a - 0.62) / 0.38, 0, 1)
    bloom = Image.fromarray((bright * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18 * SS))
    a = 1 - (1 - a) * (1 - np.asarray(bloom).astype(np.float32) / 255 * 0.55)
    # vignette
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    r = np.sqrt(((xx / a.shape[1]) - 0.5) ** 2 + ((yy / a.shape[0]) - 0.52) ** 2)
    a *= np.clip(1.12 - r * 0.85, 0.55, 1)[..., None]
    # lift the exposure so it sits beside the brighter Episode 01 cover
    a = np.clip(a * 1.1, 0, 1) ** 0.9
    out = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((W, H), Image.LANCZOS)
    grain = Image.effect_noise((W, H), 14).convert("RGB")
    return Image.blend(out, grain, 0.03)


def main():
    base = sky()
    old_gold(base)
    lantern_line(base)
    platform(base)
    train(base)
    coupler(base)
    title(base)
    OUT.mkdir(parents=True, exist_ok=True)
    finish(base).save(OUT / "cover-car-thirteen.jpg", quality=90, optimize=True)
    (OUT / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": "cover-car-thirteen.jpg", "idiom": "universal"}],
         "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print("Wrote", OUT / "cover-car-thirteen.jpg")


if __name__ == "__main__":
    main()
