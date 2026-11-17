# Frame raw 9:16 game captures into 1080x1920 Play screenshots with a caption.
# Usage: python3 frame_shots.py <Roboto.ttf> <out_dir/> <captures_dir/>
# Roboto (SIL OFL): https://github.com/google/fonts/tree/main/ofl/roboto

import sys
from PIL import Image, ImageDraw, ImageFont
SRC = sys.argv[3] if len(sys.argv) > 3 else "shots/"  # folder with the st_*.png captures
FONT = sys.argv[1]
OUT = sys.argv[2]
W, H = 1080, 1920
shots = [
    ("st_hub_0.png", "01_hub.png", "Original 3D games", "Play the CPU · offline · no ads", (32, 22, 62)),
    ("st_snake_2.png", "02_serpent_grid.png", "Serpent Grid", "Out-turn a CPU snake on a neon grid", (24, 18, 64)),
    ("st_blocks_2.png", "03_stack_drop.png", "Stack Drop", "Race the CPU to clear the tower", (40, 22, 70)),
    ("st_pool_1.png", "04_break_and_bank_break.png", "Break & Bank", "Eight-ball billiards vs a smart CPU", (10, 52, 50)),
    ("st_pool_2.png", "05_break_and_bank_table.png", "Real ball physics", "Spin, cushions and pockets that feel right", (10, 52, 50)),
    ("st_blocks_3.png", "06_stack_drop_race.png", "Three difficulty levels", "Easy, Medium or Hard in every game", (40, 22, 70)),
]
def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    names = [a["name"] for a in f.get_variation_axes()]
    vals = {"Weight": weight, "Width": 100}
    f.set_variation_by_axes([vals.get(n.decode() if isinstance(n, bytes) else n, 100) for n in names])
    return f
for src, dst, title, sub, top in shots:
    canvas = Image.new("RGB", (W, H), (12, 10, 24))
    d = ImageDraw.Draw(canvas)
    for y in range(H):  # soft vertical gradient from the game's own tone
        t = min(1.0, y / 700.0)
        c = tuple(int(top[i] * (1 - t) + 12 * t) for i in range(3))
        d.line([(0, y), (W, y)], fill=c)
    shot = Image.open(SRC + src).convert("RGB")
    scale = 1500 / shot.height
    shot = shot.resize((int(shot.width * scale), 1500), Image.LANCZOS)
    x = (W - shot.width) // 2
    y0 = H - shot.height - 40
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width - 1, shot.height - 1], 36, fill=255)
    canvas.paste(shot, (x, y0), mask)
    ft = font(84, 800)
    fs = font(44, 500)
    tw = d.textlength(title, font=ft)
    d.text(((W - tw) / 2, 150), title, font=ft, fill=(255, 255, 255))
    sw = d.textlength(sub, font=fs)
    d.text(((W - sw) / 2, 268), sub, font=fs, fill=(255, 214, 102))
    canvas.save(OUT + dst, optimize=True)
    print(dst, canvas.size)
