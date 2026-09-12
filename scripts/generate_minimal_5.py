import math
from PIL import Image, ImageDraw, ImageFilter

WIDTH = 1080
HEIGHT = 1920

def create_option_5():
    # Contemporary Ivory & Crimson Minimalist Aesthetic
    img = Image.new('RGB', (WIDTH, HEIGHT), '#100507')
    draw = ImageDraw.Draw(img)

    center_x, center_y = WIDTH // 2, HEIGHT // 3 + 20
    crimson = (183, 28, 28)
    gold = (216, 155, 24)
    ivory = (255, 248, 240)

    # Ambient deep red radial background
    for r in range(WIDTH, 0, -10):
        factor = 1.0 - (r / WIDTH)
        red = int(16 + (140 - 16) * factor)
        green = int(5 + (20 - 5) * factor)
        blue = int(7 + (22 - 7) * factor)
        draw.ellipse([center_x - r, center_y - r, center_x + r, center_y + r], fill=(red, green, blue))

    # Large Sacred Sun / Aura Circle
    aura_r = 340
    draw.ellipse([center_x - aura_r, center_y - aura_r, center_x + aura_r, center_y + aura_r], outline=gold, width=3)
    draw.ellipse([center_x - aura_r - 20, center_y - aura_r - 20, center_x + aura_r + 20, center_y + aura_r + 20], outline=(140, 95, 20), width=1)

    # Modern Graphic Trishul (Solid clean silhouette)
    ty = center_y + 140
    # Central spear shaft
    draw.line([center_x, ty - 280, center_x, ty + 300], fill=gold, width=8)
    # Trident center arrowhead
    draw.polygon([
        (center_x, ty - 340),
        (center_x - 30, ty - 270),
        (center_x + 30, ty - 270)
    ], fill=gold)

    # Left curved wing
    draw.line([center_x, ty - 120, center_x - 140, ty - 200, center_x - 130, ty - 280], fill=gold, width=8)
    draw.polygon([(center_x - 130, ty - 280), (center_x - 145, ty - 230), (center_x - 115, ty - 230)], fill=gold)

    # Right curved wing
    draw.line([center_x, ty - 120, center_x + 140, ty - 200, center_x + 130, ty - 280], fill=gold, width=8)
    draw.polygon([(center_x + 130, ty - 280), (center_x + 115, ty - 230), (center_x + 145, ty - 230)], fill=gold)

    # Damru at the center of Trishul
    draw.polygon([(center_x - 40, ty + 40), (center_x + 40, ty + 40), (center_x - 40, ty + 100), (center_x + 40, ty + 100)], outline=gold, width=4)

    # Expressive Durga Eyes (Modern graphic line)
    ey = center_y - 120
    draw.line([center_x - 220, ey + 10, center_x - 160, ey - 30, center_x - 40, ey + 20], fill=ivory, width=6)
    draw.line([center_x - 220, ey + 10, center_x - 130, ey + 35, center_x - 40, ey + 20], fill=ivory, width=5)
    draw.ellipse([center_x - 140, ey - 5, center_x - 110, ey + 25], fill=gold)

    draw.line([center_x + 40, ey + 20, center_x + 160, ey - 30, center_x + 220, ey + 10], fill=ivory, width=6)
    draw.line([center_x + 40, ey + 20, center_x + 130, ey + 35, center_x + 220, ey + 10], fill=ivory, width=5)
    draw.ellipse([center_x + 110, ey - 5, center_x + 140, ey + 25], fill=gold)

    # Red Sindoor Third Eye Flame
    draw.polygon([
        (center_x, ey - 85),
        (center_x - 16, ey - 45),
        (center_x, ey - 30),
        (center_x + 16, ey - 45)
    ], fill=crimson)

    # Bottom border accent
    draw.line([100, HEIGHT - 180, WIDTH - 100, HEIGHT - 180], fill=gold, width=2)
    draw.line([240, HEIGHT - 168, WIDTH - 240, HEIGHT - 168], fill=(140, 95, 20), width=1)

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(r'C:\Users\arnab\.gemini\antigravity-ide\brain\2703e1d3-e5b5-449d-9ad0-17cbdb2b7957\durga_minimal_5.jpg', quality=95)
    img.save(r'c:\Users\arnab\Desktop\puja_proj\app\assets\images\durga_minimal_5.jpg', quality=95)

create_option_5()
print('OPTION 5 GENERATED!')
