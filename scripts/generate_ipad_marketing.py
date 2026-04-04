from PIL import Image, ImageDraw, ImageFont
import os

# Colors
NAVY = "#0d1a40"
CREAM = "#f4f0df"

# Canvas Size (iPad Pro 12.9" requirement: 2048x2732)
CANVAS_WIDTH = 2048
CANVAS_HEIGHT = 2732

# File Mappings (new high-res screenshots from iPad Pro 13" simulator)
SCREENSHOTS = {
    "ipad_01_dashboard.png": "Train With Your Cycle",
    "ipad_03_programs.png": "Structured Programs",
    "ipad_04_maxes.png": "Know Your Strength",
    "ipad_07_cycle.png": "Cycle-Aware Training",
    "ipad_06_settings.png": "Fully Customizable"
}

# Fonts
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
HEADLINE_SIZE = 140
MARGIN_TOP = 180

# Screenshot Scaling
TARGET_WIDTH = 1700
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

    # Resize — native iPad is 2064x2752, scale to fit TARGET_WIDTH
    scale_factor = TARGET_WIDTH / ss_img.width
    new_height = int(ss_img.height * scale_factor)
    ss_img = ss_img.resize((TARGET_WIDTH, new_height), Image.Resampling.LANCZOS)

    # Rounded Corners
    ss_img = add_rounded_corners(ss_img, CORNER_RADIUS)

    # Position
    ss_x = (CANVAS_WIDTH - TARGET_WIDTH) // 2
    headline_bottom = MARGIN_TOP + HEADLINE_SIZE + 80
    ss_y = headline_bottom

    # Crop if screenshot extends past canvas
    max_height = CANVAS_HEIGHT - ss_y - 40
    if new_height > max_height:
        ss_img = ss_img.crop((0, 0, TARGET_WIDTH, max_height))
        new_height = max_height

    # 4. Add Shadow
    shadow_offset = 15
    shadow_rect = [ss_x + shadow_offset, ss_y + shadow_offset,
                   ss_x + TARGET_WIDTH + shadow_offset, ss_y + new_height + shadow_offset]
    draw.rounded_rectangle(shadow_rect, CORNER_RADIUS, fill=(0, 0, 0, 100))

    # 5. Paste Screenshot
    canvas.paste(ss_img, (ss_x, ss_y), ss_img)

    # 6. Save
    output_filename = f"marketing_{screenshot_filename}"
    output_path = os.path.join("screenshots", "appstore_ipad", output_filename)
    canvas.save(output_path)
    print(f"  Saved to {output_path} ({canvas.size[0]}x{canvas.size[1]})")


if __name__ == "__main__":
    os.makedirs("screenshots/appstore_ipad", exist_ok=True)
    for filename, headline in SCREENSHOTS.items():
        generate_image(filename, headline)
    print("\nDone! All iPad marketing images generated.")
