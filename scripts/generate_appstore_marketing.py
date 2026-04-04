from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# Colors
NAVY = "#0d1a40"
CREAM = "#f4f0df"
ORANGE = "#f27319"

# Canvas Size (iPhone 6.5")
CANVAS_WIDTH = 1284
CANVAS_HEIGHT = 2778

# File Mappings
SCREENSHOTS = {
    "01_dashboard.png": "Train With Your Cycle",
    "02_programs.png": "Structured Programs",
    "03_workouts.png": "Track Every Session",
    "04_maxes.png": "Know Your Strength",
    "06_settings.png": "Fully Customizable",
    "07_cycle_calendar.png": "Cycle-Aware Training"
}

# Fonts
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
HEADLINE_SIZE = 90
MARGIN_TOP = 250
MARGIN_BOTTOM = 200

# Screenshot Scaling
TARGET_WIDTH = 1000  # Leave some margin
CORNER_RADIUS = 60

def add_rounded_corners(im, radius):
    mask = Image.new('L', im.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0) + im.size, radius, fill=255)
    result = im.copy()
    result.putalpha(mask)
    return result

def add_shadow(im, offset=(20, 20), background_color=NAVY):
    shadow_size = (im.size[0] + 60, im.size[1] + 60)
    shadow = Image.new('RGBA', shadow_size, (0, 0, 0, 0))
    
    # Draw rounded rectangle for shadow
    shadow_mask = Image.new('L', shadow_size, 0)
    shadow_draw = ImageDraw.Draw(shadow_mask)
    shadow_draw.rounded_rectangle((30, 30, shadow_size[0]-30, shadow_size[1]-30), CORNER_RADIUS, fill=100)
    
    shadow_layer = Image.new('RGBA', shadow_size, (0, 0, 0, 200))
    shadow_layer.putalpha(shadow_mask)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(25))
    
    # Create final canvas for the image with shadow
    return shadow_layer

def generate_image(screenshot_filename, headline):
    print(f"Generating for {screenshot_filename}: {headline}...")
    
    # 1. Create Canvas
    canvas = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), NAVY)
    draw = ImageDraw.Draw(canvas)
    
    # 2. Add Headline
    try:
        font = ImageFont.truetype(FONT_PATH, HEADLINE_SIZE)
    except:
        font = ImageFont.load_default()
        
    text_bbox = draw.textbbox((0, 0), headline, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_x = (CANVAS_WIDTH - text_width) // 2
    draw.text((text_x, MARGIN_TOP), headline, fill=CREAM, font=font)
    
    # 3. Load and Process Screenshot
    ss_path = os.path.join("screenshots", screenshot_filename)
    ss_img = Image.open(ss_path).convert("RGBA")
    
    # Scaling
    scale_factor = TARGET_WIDTH / ss_img.width
    new_height = int(ss_img.height * scale_factor)
    ss_img = ss_img.resize((TARGET_WIDTH, new_height), Image.Resampling.LANCZOS)
    
    # Rounded Corners
    ss_img = add_rounded_corners(ss_img, CORNER_RADIUS)
    
    # Position
    ss_x = (CANVAS_WIDTH - TARGET_WIDTH) // 2
    ss_y = MARGIN_TOP + HEADLINE_SIZE + 200  # Space below headline
    
    # 4. Add Shadow (Simplified for performance and reliability)
    # We'll just draw a dark rectangle behind first
    shadow_rect = [ss_x + 10, ss_y + 10, ss_x + TARGET_WIDTH + 10, ss_y + new_height + 10]
    draw.rounded_rectangle(shadow_rect, CORNER_RADIUS, fill=(0, 0, 0, 150))
    
    # 5. Paste Screenshot
    canvas.paste(ss_img, (ss_x, ss_y), ss_img)
    
    # 6. Save
    output_filename = f"marketing_{screenshot_filename}"
    if screenshot_filename == "07_cycle_calendar.png":
        output_filename = "marketing_07_cycle.png"
    output_path = os.path.join("screenshots", "appstore", output_filename)
    canvas.save(output_path)
    print(f"Saved to {output_path}")

if __name__ == "__main__":
    if not os.path.exists("screenshots/appstore"):
        os.makedirs("screenshots/appstore")
    for filename, headline in SCREENSHOTS.items():
        generate_image(filename, headline)
