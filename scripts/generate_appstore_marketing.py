from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# Colors
NAVY = "#0d1a40"
CREAM = "#f4f0df"
ORANGE = "#f27319"

# Canvas Size (iPhone 6.5" — required by App Store Connect)
CANVAS_WIDTH = 1284
CANVAS_HEIGHT = 2778

# File Mappings (new high-res screenshots from simulator)
SCREENSHOTS = {
    "iphone_01_dashboard.png": "Train With Your Cycle",
    "iphone_03_programs.png": "Structured Programs",
    "iphone_02_workouts.png": "Track Every Session",
    "iphone_04_maxes.png": "Know Your Strength",
    "iphone_05_settings.png": "Fully Customizable",
    "iphone_06_cycle.png": "Cycle-Aware Training"
}

# Fonts
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
HEADLINE_SIZE = 100
MARGIN_TOP = 180

# Screenshot Scaling — fill most of the canvas width
TARGET_WIDTH = 1050
CORNER_RADIUS = 50


def add_rounded_corners(im, radius):
    mask = Image.new('L', im.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0) + im.size, radius, fill=255)
    result = im.copy()
    result.putalpha(mask)
    return result


def generate_image(screenshot_filename, headline):
    print(f"Generating for {screenshot_filename}: {headline}...")

    # 1. Create Canvas
    canvas = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), NAVY)
    draw = ImageDraw.Draw(canvas)

    # 2. Add Headline
    try:
        font = ImageFont.truetype(FONT_PATH, HEADLINE_SIZE)
    except Exception:
        font = ImageFont.load_default()

    text_bbox = draw.textbbox((0, 0), headline, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_x = (CANVAS_WIDTH - text_width) // 2
    draw.text((text_x, MARGIN_TOP), headline, fill=CREAM, font=font)

    # 3. Load and Process Screenshot
    ss_path = os.path.join("screenshots", screenshot_filename)
    if not os.path.exists(ss_path):
        print(f"  ERROR: {ss_path} not found, skipping")
        return

    ss_img = Image.open(ss_path).convert("RGBA")

    # Scaling
    scale_factor = TARGET_WIDTH / ss_img.width
    new_height = int(ss_img.height * scale_factor)
    ss_img = ss_img.resize((TARGET_WIDTH, new_height), Image.Resampling.LANCZOS)

    # Rounded Corners
    ss_img = add_rounded_corners(ss_img, CORNER_RADIUS)

    # Position — center horizontally, place below headline with some breathing room
    ss_x = (CANVAS_WIDTH - TARGET_WIDTH) // 2
    headline_bottom = MARGIN_TOP + HEADLINE_SIZE + 100
    ss_y = headline_bottom

    # Crop if screenshot extends past canvas
    max_height = CANVAS_HEIGHT - ss_y - 40
    if new_height > max_height:
        ss_img = ss_img.crop((0, 0, TARGET_WIDTH, max_height))
        new_height = max_height

    # 4. Add Shadow
    shadow_offset = 12
    shadow_rect = [ss_x + shadow_offset, ss_y + shadow_offset,
                   ss_x + TARGET_WIDTH + shadow_offset, ss_y + new_height + shadow_offset]
    draw.rounded_rectangle(shadow_rect, CORNER_RADIUS, fill=(0, 0, 0, 120))

    # 5. Paste Screenshot
    canvas.paste(ss_img, (ss_x, ss_y), ss_img)

    # 6. Save
    output_filename = f"marketing_{screenshot_filename}"
    output_path = os.path.join("screenshots", "appstore", output_filename)
    canvas.save(output_path)
    print(f"  Saved to {output_path} ({canvas.size[0]}x{canvas.size[1]})")


if __name__ == "__main__":
    os.makedirs("screenshots/appstore", exist_ok=True)
    for filename, headline in SCREENSHOTS.items():
        generate_image(filename, headline)
    print("\nDone! All iPhone marketing images generated.")
