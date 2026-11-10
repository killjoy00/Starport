#!/usr/bin/env python3
"""Deterministic original scene art for Episode 02, The Thirteenth Car.

Draws eight interior scenes as flat, lamp-lit night pictures and writes them
into Starport/Assets.xcassets. The cover has its own script,
generate_car_thirteen_cover.py. Re-run after editing a scene:

    python3 scripts/generate_car_thirteen_art.py
"""
import json
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Starport" / "Assets.xcassets"
S = 2  # supersampling factor
NAVY, DEEP, FOG = (9, 17, 31), (5, 9, 20), (120, 140, 165)
GOLD, AMBER, PALE = (247, 190, 92), (226, 142, 54), (255, 236, 190)
TEAL, ICE, GREY = (92, 205, 196), (190, 226, 240), (132, 142, 158)
CAR, CAR_DARK = (196, 150, 70), (118, 86, 42)


class Canvas:
    def __init__(self, w, h, top=DEEP, bottom=NAVY, seed=1):
        self.w, self.h = w * S, h * S
        self.rng = random.Random(seed)
        self.img = Image.new("RGBA", (self.w, self.h))
        d = ImageDraw.Draw(self.img)
        for y in range(self.h):
            t = y / self.h
            d.line([(0, y), (self.w, y)],
                   fill=tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,))

    def layer(self, blur=0):
        return Layer(self, blur)

    def stars(self, n, y_max=1.0):
        with self.layer() as d:
            for _ in range(n):
                x, y = self.rng.uniform(0, self.w), self.rng.uniform(0, self.h * y_max)
                r = self.rng.choice([1, 1, 1.5, 2, 3]) * S / 2
                d.ellipse((x - r, y - r, x + r, y + r), fill=(235, 240, 255, self.rng.randint(90, 230)))

    def glow(self, x, y, r, color=GOLD, alpha=120):
        with self.layer(blur=r * S * 0.45) as d:
            d.ellipse(box(x - r, y - r, x + r, y + r), fill=color + (alpha,))

    def fog(self, y, height, n=9, alpha=38, color=FOG):
        with self.layer(blur=height * S * 0.35) as d:
            for _ in range(n):
                x = self.rng.uniform(-0.1, 1.1) * self.w / S
                w = self.rng.uniform(0.25, 0.6) * self.w / S
                yy = y + self.rng.uniform(-0.5, 0.5) * height
                d.ellipse(box(x - w / 2, yy - height / 2, x + w / 2, yy + height / 2), fill=color + (alpha,))

    def save(self, name):
        folder = ASSETS / f"{name}.imageset"
        folder.mkdir(parents=True, exist_ok=True)
        out = self.img.convert("RGB").resize((self.w // S, self.h // S), Image.LANCZOS)
        grain = Image.effect_noise(out.size, 9).convert("RGB")
        out = Image.blend(out, grain, 0.035)
        out.save(folder / f"{name}.jpg", quality=90, optimize=True)
        (folder / "Contents.json").write_text(json.dumps(
            {"images": [{"filename": f"{name}.jpg", "idiom": "universal"}],
             "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


class Layer:
    def __init__(self, canvas, blur):
        self.canvas, self.blur = canvas, blur

    def __enter__(self):
        self.im = Image.new("RGBA", self.canvas.img.size, (0, 0, 0, 0))
        return ImageDraw.Draw(self.im)

    def __exit__(self, *exc):
        if self.blur:
            self.im = self.im.filter(ImageFilter.GaussianBlur(self.blur))
        self.canvas.img.alpha_composite(self.im)


def box(*v):
    return tuple(int(x * S) for x in v)


def pts(points):
    return [(int(x * S), int(y * S)) for x, y in points]


def lantern(c, x, y, r=7, lit=True):
    if lit:
        c.glow(x, y, r * 5, GOLD, 110)
    with c.layer() as d:
        d.ellipse(box(x - r, y - r, x + r, y + r), fill=(PALE if lit else (45, 52, 66)) + (255,))


def train(c, x, y, cars, car_w=120, car_h=46, gap=10, frost_index=None, lit=True):
    """A row of gold freight cars on a thin rail of light, engine leading on the right."""
    with c.layer() as d:
        d.line(pts([(x - 40, y + car_h + 9), (x + cars * (car_w + gap) + 60, y + car_h + 9)]),
               fill=GOLD + (120,), width=2 * S)
    for i in range(cars):
        cx = x + i * (car_w + gap)
        frosty = i == frost_index
        body = (214, 232, 242) if frosty else CAR
        if frosty:
            c.glow(cx + car_w / 2, y + car_h / 2, car_h * 1.3, ICE, 80)
        with c.layer() as d:
            d.rounded_rectangle(box(cx, y, cx + car_w, y + car_h), radius=7 * S, fill=body + (255,),
                                outline=CAR_DARK + (255,), width=2 * S)
            d.rectangle(box(cx, y + car_h - 10, cx + car_w, y + car_h - 6), fill=CAR_DARK + (255,))
            if i < cars - 1:
                d.rectangle(box(cx + car_w, y + car_h / 2 - 3, cx + car_w + gap, y + car_h / 2 + 3),
                            fill=CAR_DARK + (255,))
            if not frosty:
                for k in range(3):
                    wx = cx + 16 + k * 34
                    d.rounded_rectangle(box(wx, y + 10, wx + 20, y + 24), radius=3 * S,
                                        fill=(PALE if lit else (60, 58, 52)) + (255,))
            for k in (0.22, 0.78):
                wx = cx + car_w * k
                d.ellipse(box(wx - 7, y + car_h - 3, wx + 7, y + car_h + 11), fill=(40, 34, 30, 255),
                          outline=GOLD + (255,), width=S)
    ex = x + cars * (car_w + gap)
    with c.layer() as d:
        d.polygon(pts([(ex, y), (ex + 70, y), (ex + 118, y + car_h), (ex, y + car_h)]),
                  fill=(226, 172, 78, 255), outline=CAR_DARK + (255,))
        d.rounded_rectangle(box(ex + 18, y + 9, ex + 56, y + 24), radius=3 * S, fill=TEAL + (255,))
    c.glow(ex + 120, y + car_h - 8, 46, PALE, 120)


def ray(c, x, y, span, color=GOLD, alpha=255, veins=True, tilt=0.0):
    """A lantern ray seen from below: a wide kite with swept wings and a tail."""
    def at(px, py):
        ca, sa = math.cos(tilt), math.sin(tilt)
        return (x + (px * ca - py * sa) * span, y + (px * sa + py * ca) * span)
    outline = [(0, -0.22), (0.18, -0.16), (0.5, -0.02), (0.36, 0.08), (0.14, 0.14), (0.04, 0.2),
               (0, 0.46), (-0.04, 0.2), (-0.14, 0.14), (-0.36, 0.08), (-0.5, -0.02), (-0.18, -0.16)]
    c.glow(x, y, span * 0.42, color, 70)
    with c.layer(blur=1.2 * S) as d:
        d.polygon(pts([at(*p) for p in outline]), fill=tuple(int(v * 0.42) for v in color) + (alpha,))
    if veins:
        with c.layer(blur=1.5 * S) as d:
            for side in (-1, 1):
                for k in range(4):
                    tip = (side * (0.46 - k * 0.1), -0.02 + k * 0.045)
                    d.line(pts([at(0, -0.12 + k * 0.05), at(side * 0.2, -0.1 + k * 0.05), at(*tip)]),
                           fill=color + (230,), width=max(S, int(span * 0.008 * S)), joint="curve")
            d.line(pts([at(0, -0.2), at(0, 0.44)]), fill=PALE + (220,), width=max(S, int(span * 0.008 * S)))


def moth_ship(c, x, y, size, lamp=True):
    with c.layer(blur=0.6 * S) as d:
        for side in (-1, 1):
            d.polygon(pts([(x, y - size * 0.1), (x + side * size, y - size * 0.75),
                           (x + side * size * 0.7, y + size * 0.1), (x, y + size * 0.2)]),
                      fill=GREY + (215,), outline=(86, 96, 112, 255))
            d.line(pts([(x, y), (x + side * size * 0.85, y - size * 0.55)]), fill=(86, 96, 112, 255), width=S)
        d.polygon(pts([(x - size * 0.16, y), (x + size * 0.16, y), (x + size * 0.07, y + size * 0.5),
                       (x - size * 0.07, y + size * 0.5)]), fill=(70, 78, 94, 255))
    if lamp:
        lantern(c, x, y + size * 0.52, max(2.5, size * 0.07))


def figure(c, x, y, h, coat=TEAL, mirrors=False):
    with c.layer() as d:
        d.rounded_rectangle(box(x - h * 0.17, y - h * 0.62, x + h * 0.17, y - h * 0.05), radius=int(h * 0.08 * S),
                            fill=coat + (255,))
        d.rectangle(box(x - h * 0.15, y - h * 0.08, x - h * 0.03, y + h * 0.3), fill=(40, 48, 66, 255))
        d.rectangle(box(x + h * 0.03, y - h * 0.08, x + h * 0.15, y + h * 0.3), fill=(40, 48, 66, 255))
        d.ellipse(box(x - h * 0.19, y - h, x + h * 0.19, y - h * 0.62), fill=(214, 224, 236, 255),
                  outline=(60, 70, 90, 255), width=S)
        d.chord(box(x - h * 0.13, y - h * 0.93, x + h * 0.13, y - h * 0.69), 200, 340, fill=(40, 54, 80, 255))
        if mirrors:
            for i in range(9):
                mx = x - h * 0.12 + (i % 3) * h * 0.12
                my = y - h * 0.52 + (i // 3) * h * 0.14
                d.rectangle(box(mx - 2, my - 2, mx + 2, my + 2), fill=(240, 250, 255, 255))


def frost(c, x0, y0, x1, y1, n=60):
    with c.layer(blur=0.5 * S) as d:
        for _ in range(n):
            x, y = c.rng.uniform(x0, x1), c.rng.uniform(y0, y1)
            r = c.rng.uniform(4, 16)
            for k in range(6):
                a = math.radians(k * 60 + c.rng.uniform(-6, 6))
                d.line(pts([(x, y), (x + math.cos(a) * r, y + math.sin(a) * r)]),
                       fill=(225, 242, 250, c.rng.randint(80, 200)), width=S)


def scene_train():
    c = Canvas(1200, 720, seed=11)
    c.stars(260, 0.8)
    for i in range(7):
        t = i / 6
        lantern(c, 70 + t * 1100, 250 - math.sin(t * math.pi) * 110, 5 + t * 5, lit=i != 4)
    with c.layer(blur=2 * S) as d:
        d.line(pts([(70 + (i / 40) * 1100, 250 - math.sin((i / 40) * math.pi) * 110) for i in range(41)]),
               fill=GOLD + (60,), width=2 * S)
    c.fog(600, 150, n=8, alpha=26)
    train(c, 60, 470, 7, car_w=118, frost_index=1)
    c.save("car13-scene-train")


def scene_door():
    c = Canvas(1200, 720, top=(20, 26, 40), bottom=(34, 30, 34), seed=12)
    with c.layer() as d:
        d.rectangle(box(0, 0, 1200, 720), fill=(54, 44, 36, 255))
        for x in range(0, 1200, 150):
            d.line(pts([(x, 0), (x, 720)]), fill=(36, 30, 26, 255), width=3 * S)
        d.rectangle(box(0, 630, 1200, 720), fill=(28, 26, 30, 255))
        d.rounded_rectangle(box(390, 70, 810, 660), radius=26 * S, fill=(196, 220, 234, 255),
                            outline=(120, 150, 172, 255), width=5 * S)
    c.glow(600, 360, 300, ICE, 60)
    frost(c, 400, 80, 800, 650, n=170)
    with c.layer(blur=1.2 * S) as d:
        for k in range(46):
            a = k * 0.42
            r = 14 + k * 4.2
            d.arc(box(600 - r, 300 - r, 600 + r, 300 + r), math.degrees(a), math.degrees(a) + 62,
                  fill=(255, 255, 255, 150), width=2 * S)
    c.glow(600, 430, 70, GOLD, 120)
    with c.layer() as d:
        d.ellipse(box(552, 382, 648, 478), fill=(238, 228, 200, 255), outline=AMBER + (255,), width=3 * S)
        d.rounded_rectangle(box(580, 420, 620, 458), radius=10 * S, fill=AMBER + (255,))
        for i, fx in enumerate((580, 591, 602, 613)):
            d.rounded_rectangle(box(fx, 398 - (4 if i in (1, 2) else 0), fx + 8, 426), radius=4 * S,
                                fill=AMBER + (255,))
        d.rounded_rectangle(box(566, 426, 582, 436), radius=4 * S, fill=AMBER + (255,))
    c.glow(150, 560, 120, GOLD, 70)
    figure(c, 190, 610, 150, coat=(190, 120, 60))
    c.save("car13-scene-door")


def scene_ember():
    c = Canvas(1200, 720, top=(14, 30, 52), bottom=(30, 52, 78), seed=13)
    with c.layer(blur=0.8 * S) as d:
        for i in range(34):
            x = 20 + i * 35 + c.rng.uniform(-8, 8)
            ln = c.rng.uniform(50, 190)
            d.polygon(pts([(x - 9, 0), (x + 9, 0), (x, ln)]), fill=(205, 232, 246, 200))
        for side in (0, 1):
            for i in range(9):
                x = 40 + i * 30 if side == 0 else 1160 - i * 30
                base = 720
                for k in range(7):
                    y = base - k * (60 - i * 3)
                    d.line(pts([(x, y), (x + (18 if k % 2 else -18), y - 34)]), fill=(190, 226, 240, 170), width=2 * S)
                d.line(pts([(x, base), (x, base - 7 * (60 - i * 3))]), fill=(190, 226, 240, 190), width=2 * S)
        d.rectangle(box(0, 640, 1200, 720), fill=(22, 40, 62, 255))
    c.glow(600, 420, 280, GOLD, 80)
    with c.layer() as d:
        d.chord(box(430, 430, 770, 700), 0, 180, fill=(200, 232, 246, 120), outline=(230, 246, 255, 255), width=3 * S)
        d.line(pts([(470, 668), (440, 700)]), fill=(230, 246, 255, 255), width=3 * S)
        d.line(pts([(730, 668), (760, 700)]), fill=(230, 246, 255, 255), width=3 * S)
        d.arc(box(520, 540, 600, 610), 190, 350, fill=GOLD + (255,), width=3 * S)
    ray(c, 600, 300, 300, GOLD, tilt=-0.18)
    c.glow(600, 290, 90, PALE, 150)
    frost(c, 0, 600, 1200, 720, n=60)
    c.save("car13-scene-ember")


def scene_moths():
    c = Canvas(1200, 720, top=(10, 14, 28), bottom=(44, 56, 76), seed=14)
    c.stars(120, 0.45)
    c.fog(430, 240, n=12, alpha=44)
    for x, y, s in [(260, 250, 88), (520, 170, 60), (760, 240, 76), (980, 150, 52), (120, 420, 46),
                    (640, 400, 110), (1050, 380, 70)]:
        moth_ship(c, x, y, s)
    c.fog(560, 160, n=10, alpha=40)
    train(c, 380, 610, 5, car_w=96, car_h=36, gap=8)
    c.save("car13-scene-moths")


def scene_roof():
    c = Canvas(1200, 720, top=(8, 12, 26), bottom=(40, 52, 74), seed=15)
    c.stars(180, 0.5)
    c.fog(300, 220, n=10, alpha=36)
    with c.layer() as d:
        d.polygon(pts([(0, 560), (1200, 470), (1200, 720), (0, 720)]), fill=CAR + (255,))
        d.polygon(pts([(0, 560), (1200, 470), (1200, 486), (0, 580)]), fill=(232, 190, 104, 255))
        for i in range(1, 5):
            x = i * 250
            y = 560 - x * 0.075
            d.line(pts([(x, y), (x + 14, y + 190)]), fill=CAR_DARK + (255,), width=5 * S)
        for i in range(24):
            x = 30 + i * 50
            y = 590 - x * 0.075
            d.ellipse(box(x - 4, y - 4, x + 4, y + 4), fill=CAR_DARK + (255,))
    c.glow(1010, 240, 190, GOLD, 34)
    figure(c, 520, 500, 150, coat=(92, 110, 140), mirrors=True)
    figure(c, 330, 520, 160, coat=(190, 120, 60))
    moth_ship(c, 960, 200, 70)
    moth_ship(c, 160, 170, 44)
    c.fog(640, 110, n=8, alpha=30)
    c.save("car13-scene-roof")


def scene_engine():
    c = Canvas(1200, 720, top=(8, 20, 40), bottom=(14, 30, 52), seed=16)
    with c.layer() as d:
        for i in range(7):
            y = 60 + i * 44
            d.rounded_rectangle(box(0, y, 1200, y + 18), radius=9 * S, fill=(30 + i * 4, 60 + i * 4, 88 + i * 4, 255))
            for x in range(60, 1200, 190):
                d.rectangle(box(x + i * 13, y - 3, x + i * 13 + 14, y + 21), fill=(20, 40, 62, 255))
        d.rectangle(box(0, 600, 1200, 720), fill=(18, 28, 44, 255))
        for x in range(0, 1200, 60):
            d.line(pts([(x, 600), (x - 40, 720)]), fill=(30, 46, 68, 255), width=2 * S)
    c.glow(820, 380, 300, TEAL, 70)
    with c.layer() as d:
        d.ellipse(box(700, 250, 950, 500), fill=(18, 44, 66, 255), outline=TEAL + (255,), width=6 * S)
        for k in range(12):
            a = math.radians(k * 30)
            d.line(pts([(825 + math.cos(a) * 96, 375 + math.sin(a) * 96),
                        (825 + math.cos(a) * 112, 375 + math.sin(a) * 112)]), fill=ICE + (255,), width=3 * S)
        d.line(pts([(825, 375), (880, 300)]), fill=AMBER + (255,), width=6 * S)
        d.ellipse(box(813, 363, 837, 387), fill=GOLD + (255,))
        d.rounded_rectangle(box(300, 470, 620, 600), radius=12 * S, fill=(54, 46, 40, 255),
                            outline=AMBER + (255,), width=3 * S)
        d.line(pts([(460, 470), (520, 300)]), fill=GOLD + (255,), width=12 * S)
        d.ellipse(box(496, 270, 548, 322), fill=AMBER + (255,), outline=PALE + (255,), width=3 * S)
        d.rounded_rectangle(box(110, 520, 200, 600), radius=8 * S, fill=(150, 60, 50, 255))
        d.rectangle(box(118, 510, 192, 524), fill=(196, 196, 200, 255))
    c.glow(522, 296, 60, GOLD, 110)
    figure(c, 980, 610, 170, coat=(120, 96, 70))
    c.save("car13-scene-engine")


def scene_oldgold():
    c = Canvas(1200, 720, top=(6, 10, 24), bottom=(30, 40, 62), seed=17)
    c.stars(200, 0.9)
    c.fog(360, 300, n=12, alpha=30)
    ray(c, 600, 300, 1120, GOLD, tilt=0.08)
    c.fog(560, 130, n=10, alpha=34)
    for x, y, s in [(110, 560, 30), (1090, 540, 34), (930, 620, 24)]:
        moth_ship(c, x, y, s)
    train(c, 330, 630, 6, car_w=70, car_h=26, gap=6, frost_index=1)
    c.save("car13-scene-oldgold")


def scene_lampcar():
    c = Canvas(1200, 720, top=(8, 12, 26), bottom=(38, 48, 70), seed=18)
    c.stars(150, 0.5)
    with c.layer(blur=10 * S) as d:
        for k in range(7):
            a = math.radians(-24 + k * 8)
            d.polygon(pts([(470, 360), (470 + math.cos(a) * 900, 360 + math.sin(a) * 900 - 12),
                           (470 + math.cos(a) * 900, 360 + math.sin(a) * 900 + 12)]), fill=GOLD + (60,))
    c.fog(420, 240, n=10, alpha=34)
    with c.layer() as d:
        d.rounded_rectangle(box(80, 470, 620, 640), radius=14 * S, fill=CAR + (255,), outline=CAR_DARK + (255,), width=3 * S)
        d.rectangle(box(80, 610, 620, 622), fill=CAR_DARK + (255,))
        d.ellipse(box(330, 200, 610, 480), fill=(190, 224, 240, 70), outline=PALE + (255,), width=5 * S)
        for k in range(1, 4):
            d.line(pts([(330 + k * 70, 215 + abs(2 - k) * 30), (330 + k * 70, 470)]), fill=PALE + (150,), width=2 * S)
        d.rectangle(box(440, 300, 500, 470), fill=(150, 110, 50, 255))
        d.ellipse(box(424, 300, 516, 392), fill=AMBER + (255,), outline=PALE + (255,), width=3 * S)
    c.glow(470, 346, 150, PALE, 150)
    figure(c, 200, 470, 130, coat=(92, 110, 140), mirrors=True)
    for x, y, s in [(930, 200, 64), (1090, 380, 46), (780, 110, 36)]:
        moth_ship(c, x, y, s)
    c.save("car13-scene-lampcar")


if __name__ == "__main__":
    for make in (scene_train, scene_door, scene_ember, scene_moths, scene_roof, scene_engine,
                 scene_oldgold, scene_lampcar):
        make()
    print("Wrote 8 scenes to", ASSETS)
