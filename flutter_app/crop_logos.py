import sys
from PIL import Image

image_path = '/Users/dustinober/Downloads/Gemini_Generated_Image_gm1iimgm1iimgm1i.png'
img = Image.open(image_path)
width, height = img.size

# The image is 2752x1536. We have two logos. Left logo is roughly in the left half, right logo in the right half.
# Let's crop them as two squares. We have 2752/2 = 1376 per half.
# 1376 x 1536. Let's make it a 1376 x 1376 square centered vertically.
y_offset = (height - 1376) // 2
left_box = (0, y_offset, 1376, y_offset + 1376)
right_box = (1376, y_offset, 2752, y_offset + 1376)

left_img = img.crop(left_box)
right_img = img.crop(right_box)

# We want them to have transparent backgrounds, but since they are JPEG/PNG with a solid color background, let's just save them for now.
# Or if it's already on a light cream background, that's fine for an app icon, though usually app icons fill the square (iOS) or have an adaptive background (Android).

left_img.save('/Users/dustinober/Projects/Sundee-Fundee/flutter_app/assets/images/main_logo.png')
right_img.save('/Users/dustinober/Projects/Sundee-Fundee/flutter_app/assets/images/period_logo.png')
print("Successfully cropped images.")
