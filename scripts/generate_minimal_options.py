import math
from PIL import Image, ImageDraw, ImageFilter

WIDTH = 1080
HEIGHT = 1920

def create_option_3():
    # Deep imperial maroon and golden glow
    img = Image.new('RGB', (WIDTH, HEIGHT), '#180306')
    draw = ImageDraw.Draw(img)

    # Radial gradient background
    center_x, center_y = WIDTH // 2, HEIGHT // 3
    for r in range(WIDTH, 0, -8):
        factor = 1.0 - (r / WIDTH)
        red = int(24 + (90 - 24) * factor)
        green = int(3 + (15 - 3) * factor)
        blue = int(6 + (20 - 6) * factor)
        draw.ellipse([center_x - r, center_y - r, center_x + r, center_y + r], fill=(red, green, blue))

    # Sacred concentric circles with delicate dash effect
    gold = (220, 168, 48)
    gold_faint = (140, 100, 30)
    for radius in [220, 260, 320, 420]:
        draw.ellipse([center_x - radius, center_y - radius, center_x + radius, center_y + radius], outline=gold_faint, width=2)

    # Trishul Line Art (Center)
    ty = center_y + 120
    # Central spear
    draw.line([center_x, ty - 260, center_x, ty + 280], fill=gold, width=8)
    # Spearhead diamond
    draw.polygon([
        (center_x, ty - 320),
        (center_x - 28, ty - 260),
        (center_x, ty - 240),
        (center_x + 28, ty - 260)
    ], fill=gold)

    # Left and right curved prongs
    # Left prong
    left_points = []
    for a in range(0, 180, 5):
        rad = math.radians(a)
        px = center_x - 120 * math.sin(rad)
        py = ty - 100 * math.cos(rad) - 60
        left_points.append((px, py))
    draw.line(left_points, fill=gold, width=7)
    draw.polygon([
        (center_x - 120, ty - 220),
        (center_x - 140, ty - 180),
        (center_x - 100, ty - 180)
    ], fill=gold)

    # Right prong
    right_points = []
    for a in range(0, 180, 5):
        rad = math.radians(a)
        px = center_x + 120 * math.sin(rad)
        py = ty - 100 * math.cos(rad) - 60
        right_points.append((px, py))
    draw.line(right_points, fill=gold, width=7)
    draw.polygon([
        (center_x + 120, ty - 220),
        (center_x + 100, ty - 180),
        (center_x + 140, ty - 180)
    ], fill=gold)

    # Maa Durga Eyes above Trishul
    ey = center_y - 120
    # Left eye curve
    draw.arc([center_x - 220, ey - 30, center_x - 40, ey + 40], start=200, end=340, fill=gold, width=6)
    draw.arc([center_x - 220, ey - 40, center_x - 40, ey + 30], start=20, end=160, fill=gold, width=6)
    draw.ellipse([center_x - 140, ey - 8, center_x - 120, ey + 12], fill=gold)

    # Right eye curve
    draw.arc([center_x + 40, ey - 30, center_x + 220, ey + 40], start=200, end=340, fill=gold, width=6)
    draw.arc([center_x + 40, ey - 40, center_x + 220, ey + 30], start=20, end=160, fill=gold, width=6)
    draw.ellipse([center_x + 120, ey - 8, center_x + 140, ey + 12], fill=gold)

    # Glowing Red Third Eye & Bindi
    draw.ellipse([center_x - 18, ey - 80, center_x + 18, ey - 44], fill=(225, 25, 35))
    draw.ellipse([center_x - 8, ey - 20, center_x + 8, ey - 4], fill=(225, 25, 35))

    # Border frame
    inset = 40
    draw.rectangle([inset, inset, WIDTH - inset, HEIGHT - inset], outline=gold_faint, width=3)
    draw.rectangle([inset + 14, inset + 14, WIDTH - inset - 14, HEIGHT - inset - 14], outline=gold_faint, width=1)

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(r'C:\Users\arnab\.gemini\antigravity-ide\brain\2703e1d3-e5b5-449d-9ad0-17cbdb2b7957\durga_minimal_3.jpg', quality=95)
    img.save(r'c:\Users\arnab\Desktop\puja_proj\app\assets\images\durga_minimal_3.jpg', quality=95)

def create_option_4():
    # Luxury charcoal night with minimalist golden lotus crown and trishul
    img = Image.new('RGB', (WIDTH, HEIGHT), '#0D0E11')
    draw = ImageDraw.Draw(img)

    center_x, center_y = WIDTH // 2, HEIGHT // 3 + 40
    gold = (235, 185, 65)
    soft_gold = (160, 125, 45)
    bright_red = (235, 30, 45)

    # Background subtle golden glow
    for r in range(500, 50, -10):
        alpha = int((1.0 - (r / 500)) * 40)
        draw.ellipse([center_x - r, center_y - r, center_x + r, center_y + r], fill=(13 + alpha, 14 + int(alpha * 0.8), 17))

    # Minimalist Lotus Mukut (Crown) Petals
    cy = center_y - 180
    for petal_angle in [-45, -30, -15, 0, 15, 30, 45]:
        rad = math.radians(petal_angle)
        px = center_x + int(160 * math.sin(rad))
        py = cy - int(160 * math.cos(rad))
        draw.polygon([(center_x, cy), (px - 15, py + 30), (px, py), (px + 15, py + 30)], outline=gold, fill=None)

    # Curved Crescent Moon
    draw.arc([center_x - 180, cy + 20, center_x + 180, cy + 280], start=30, end=150, fill=gold, width=5)

    # Elegant Trishul Silhouette
    ty = center_y + 160
    draw.line([center_x, ty - 220, center_x, ty + 260], fill=gold, width=6)
    # Trishul side flames
    draw.arc([center_x - 140, ty - 180, center_x + 140, ty + 40], start=10, end=170, fill=gold, width=6)
    draw.polygon([(center_x, ty - 280), (center_x - 22, ty - 220), (center_x + 22, ty - 220)], fill=gold)
    draw.polygon([(center_x - 140, ty - 180), (center_x - 155, ty - 140), (center_x - 125, ty - 140)], fill=gold)
    draw.polygon([(center_x + 140, ty - 180), (center_x + 125, ty - 140), (center_x + 155, ty - 140)], fill=gold)

    # Divine Durga Eyes
    ey = center_y - 20
    # Left eye
    draw.arc([center_x - 200, ey - 30, center_x - 30, ey + 40], start=210, end=330, fill=gold, width=5)
    draw.arc([center_x - 200, ey - 40, center_x - 30, ey + 30], start=30, end=150, fill=gold, width=5)
    draw.ellipse([center_x - 125, ey - 5, center_x - 105, ey + 15], fill=gold)

    # Right eye
    draw.arc([center_x + 30, ey - 30, center_x + 200, ey + 40], start=210, end=330, fill=gold, width=5)
    draw.arc([center_x + 30, ey - 40, center_x + 200, ey + 30], start=30, end=150, fill=gold, width=5)
    draw.ellipse([center_x + 105, ey - 5, center_x + 125, ey + 15], fill=gold)

    # Sacred Red Third Eye
    draw.ellipse([center_x - 14, ey - 60, center_x + 14, ey - 30], fill=bright_red)
    draw.ellipse([center_x - 8, ey + 8, center_x + 8, ey + 24], fill=bright_red)

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(r'C:\Users\arnab\.gemini\antigravity-ide\brain\2703e1d3-e5b5-449d-9ad0-17cbdb2b7957\durga_minimal_4.jpg', quality=95)
    img.save(r'c:\Users\arnab\Desktop\puja_proj\app\assets\images\durga_minimal_4.jpg', quality=95)

create_option_3()
create_option_4()
print('OPTIONS 3 and 4 GENERATED!')
