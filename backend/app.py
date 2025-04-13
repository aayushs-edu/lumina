import os
import tempfile
import traceback
import base64
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from instagrapi import Client
from PIL import Image, ImageDraw, ImageFont
import openai
from dotenv import dotenv_values
import uuid
import time

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load environment variables from .env file
config = dotenv_values(".env")

# Load template images (assume they are in ./templates)
TEMPLATES = {
    "orange_title": "templates/orange_title.png",
    "purple_title": "templates/purple_title.png",
    "orange_slide": "templates/orange_slide.png",
    "purple_slide": "templates/purple_slide.png"
}

# Fonts
FONT_PATH = "fonts/Baloo2-Regular.ttf"
TITLE_FONT_SIZE = 40
TEXT_FONT_SIZE = 30
CAPTION_FONT_SIZE = 25
CTA_TEXT = "Read more on Lumina."

FONT_PATH = "fonts/Baloo2-Regular.ttf"
TITLE_FONT_SIZE = 40
TEXT_FONT_SIZE = 30
CAPTION_FONT_SIZE = 25
CTA_TEXT = "Read more on Lumina."
TEXT_COLOR = (0, 0, 0)
TEMP_PREVIEW_DIR = "static/preview_images"
os.makedirs(TEMP_PREVIEW_DIR, exist_ok=True)

TITLE_X = 150       # Horizontal position for title  
TITLE_Y = 250       # Vertical position for title  
CAPTION_X = 150     # Horizontal position for caption  
CAPTION_Y = 180     # Vertical position for caption  
COUNTRY_X = 540     # Horizontal position for country  
COUNTRY_Y = 680     # Vertical position for country

# OpenAI API key (set as environment variable in .env)
openai.api_key = config["OPENAI_API_KEY"]

@app.route('/generate-caption', methods=['POST'])
def generate_caption():
    try:
        data = request.get_json()
        title = data.get("title", "")
        story = data.get("story", "")
        country = data.get("country", "")
        themes = data.get("themes", [])

        if not story:
            return jsonify({"error": "Story content is required."}), 400

        prompt = f"""
Generate an Instagram caption for the following story.
Title: {title}
Country: {country}
Themes: {', '.join(themes)}
Story: {story}
"""

        print("DEBUG: Prompt sent to OpenAI:", prompt)

        # Corrected method call:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant writing Instagram captions."},
                {"role": "user", "content": prompt}
            ]
        )

        print("DEBUG: OpenAI response:", response)

        caption = response.choices[0].message.content

        return jsonify({"caption": caption})

    except Exception as e:
        print("ERROR in /generate-caption:", e)
        return jsonify({"error": str(e)}), 500

# --- Common helper functions (placed above the endpoints) ---

def generate_preview_files(title, caption, country, sentences, color_scheme, theme, temp_dir):
    """
    Generate preview image files and return a list of file paths.
    This function uses the same drawing methods as in /generate-preview.
    """
    images = []
    
    # Load fonts
    title_font = ImageFont.truetype(FONT_PATH, TITLE_FONT_SIZE)
    caption_font = ImageFont.truetype(FONT_PATH, CAPTION_FONT_SIZE)
    text_font = ImageFont.truetype(FONT_PATH, TEXT_FONT_SIZE)
    # For country, we use the same as title_font
    country_font = ImageFont.truetype(FONT_PATH, TITLE_FONT_SIZE)
    
    # Build template paths based on color_scheme and theme.
    template_title_key = f"{color_scheme}_title"
    template_slide_key = f"{color_scheme}_slide"
    template_title_path = TEMPLATES.get(template_title_key)
    template_slide_path = TEMPLATES.get(template_slide_key)
    if template_title_path is None or template_slide_path is None:
        raise FileNotFoundError("Appropriate template file not found.")
    if not os.path.exists(template_title_path) or not os.path.exists(template_slide_path):
        raise FileNotFoundError("Template file does not exist on disk.")
    
    # Create title slide
    title_template = Image.open(template_title_path).convert("RGBA")
    draw_title_slide(title_template, title, country, caption, title_font, country_font, caption_font, TEXT_COLOR, color_scheme)
    title_path = os.path.join(temp_dir, "title.jpg")
    title_template.convert("RGB").save(title_path, format="JPEG")
    images.append(title_path)
    
    # Create content slides for each sentence
    for i, sentence in enumerate(sentences):
        slide = Image.open(template_slide_path).convert("RGBA")
        draw_wrapped_text(slide, sentence, text_font, TEXT_COLOR, margin_percentage=30)
        slide_path = os.path.join(temp_dir, f"slide_{i}.jpg")
        slide.convert("RGB").save(slide_path, format="JPEG")
        images.append(slide_path)
    
    # Create CTA slide
    cta = Image.open(template_slide_path).convert("RGBA")
    draw_wrapped_text(cta, CTA_TEXT, text_font, TEXT_COLOR, margin_percentage=30)
    cta_path = os.path.join(temp_dir, "cta.jpg")
    cta.convert("RGB").save(cta_path, format="JPEG")
    images.append(cta_path)
    
    return images

# --- Modified /post-instagram endpoint ---

@app.route('/post-instagram', methods=['POST'])
def post_instagram():
    try:
        data = request.get_json()
        caption = data.get("caption", "")
        
        # Always use the fixed folder for the current preview images
        folder_id = "current_preview"
        folder_path = os.path.join(TEMP_PREVIEW_DIR, folder_id)
        if not os.path.exists(folder_path):
            return jsonify({"status": "error", "message": "No current preview images found."}), 404

        # Retrieve JPEG image filenames from the folder
        files = [f for f in os.listdir(folder_path) if f.endswith(".jpg")]

        # Custom sort: title.jpg first, then slide_*.jpg sorted by number, and cta.jpg last.
        def sort_key(filename):
            if filename == "title.jpg":
                return 0
            elif filename.startswith("slide_"):
                try:
                    num = int(filename.split("_")[1].split(".")[0])
                except Exception:
                    num = 999
                return num + 1
            elif filename == "cta.jpg":
                return 1000
            else:
                return 9999

        sorted_files = sorted(files, key=sort_key)
        image_paths = [os.path.join(folder_path, f) for f in sorted_files]

        if not image_paths:
            return jsonify({"status": "error", "message": "No images found in current preview folder."}), 400

        client = Client()
        client.login(config["INSTAGRAM_USERNAME"], config["INSTAGRAM_PASSWORD"])
        client.album_upload(image_paths, caption=caption)
        client.logout()

        return jsonify({"status": "success"})
    
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500



def draw_wrapped_text(img, text, font, text_color, margin_percentage=30, custom_margins=None, align="center"):
    """
    Draw text wrapped to fit within custom margins.
    This function now matches the alpha.py implementation.
    """
    draw = ImageDraw.Draw(img)
    img_width, img_height = img.size

    if custom_margins:
        left_margin = custom_margins['left']
        right_margin = custom_margins['right']
        max_text_width = img_width - (left_margin + right_margin)
    else:
        margin = int(img_width * margin_percentage / 100)
        max_text_width = img_width - (2 * margin)
        left_margin = margin

    # Split text into words and form lines that fit max_text_width.
    words = text.split()
    lines = []
    current_line = []
    for word in words:
        test_line = " ".join(current_line + [word])
        bbox = font.getbbox(test_line)
        line_width = bbox[2] - bbox[0] if bbox else 0
        if line_width <= max_text_width:
            current_line.append(word)
        else:
            if current_line:
                lines.append(" ".join(current_line))
            current_line = [word]
    if current_line:
        lines.append(" ".join(current_line))

    # Calculate vertical centering using the same formula as alpha.py.
    line_height = (font.getbbox("Aj")[3] - font.getbbox("Aj")[1]) + 8  # 8px spacing (as in alpha.py)
    total_text_height = len(lines) * line_height
    if custom_margins:
        available_height = img_height - (custom_margins['top'] + custom_margins['bottom'])
        start_y = custom_margins['top'] + (available_height - total_text_height) // 2
    else:
        start_y = (img_height - total_text_height) // 2

    # Draw each line with the proper alignment
    for i, line in enumerate(lines):
        bbox = font.getbbox(line)
        line_width = bbox[2] - bbox[0]
        if custom_margins:
            if align == "center":
                available_width = img_width - (custom_margins['left'] + custom_margins['right'])
                x = custom_margins['left'] + (available_width - line_width) // 2
            elif align == "left":
                x = custom_margins['left']
        else:
            if align == "center":
                x = (img_width - line_width) // 2
            elif align == "left":
                x = 0
        y = start_y + (i * line_height)
        draw.text((x, y), line, font=font, fill=text_color)

def draw_title_slide(img, title_text, country_text, caption_text, title_font, country_font, caption_font, text_color, color_scheme="orange"):
    """
    Draw the title slide; positions are matched exactly to alpha.py.
    The title and country text are drawn with a bold effect.
    """
    draw = ImageDraw.Draw(img)

    # Draw bold title text using a stroke to simulate boldness.
    draw.text(
        (TITLE_X, TITLE_Y),
        f'"{title_text}"',
        font=title_font,
        fill=text_color,
        stroke_width=1.5,
        stroke_fill=text_color
    )

    # For the caption, use custom margins exactly as in alpha.py.
    caption_margins = {
        'left': CAPTION_X,
        'right': 100,    # as in alpha.py
        'top': CAPTION_Y,
        'bottom': 150    # as in alpha.py (vertical centering adjustment)
    }
    # Draw wrapped caption text with left alignment.
    draw_wrapped_text(img, caption_text, caption_font, (128, 128, 128), custom_margins=caption_margins, align="left")

    # Choose country text color based on color_scheme.
    if color_scheme.lower() == "orange":
        country_color = (255, 165, 0)  # orange
    elif color_scheme.lower() == "purple":
        country_color = (128, 0, 128)    # purple
    else:
        country_color = text_color

    # Draw bold country text using a stroke to simulate boldness.
    draw.text(
        (COUNTRY_X, COUNTRY_Y),
        country_text,
        font=country_font,
        fill=country_color,
        stroke_width=2,
        stroke_fill=country_color
    )

@app.route('/generate-preview', methods=['POST'])
def generate_preview():
    try:
        data = request.get_json()
        title = data.get("title", "Untitled")
        caption = data.get("caption", "")
        country = data.get("country", "")
        sentences = data.get("sentences", [])
        color_scheme = data.get("color_scheme", "orange")
        theme = data.get("theme", "")

        # Build keys using the color_scheme for the templates
        template_title_key = f"{color_scheme}_title"
        template_slide_key = f"{color_scheme}_slide"
        template_title_path = TEMPLATES.get(template_title_key)
        template_slide_path = TEMPLATES.get(template_slide_key)

        if template_title_path is None:
            raise FileNotFoundError(f"Template key not found: {template_title_key}")
        if template_slide_path is None:
            raise FileNotFoundError(f"Template key not found: {template_slide_key}")

        if not os.path.exists(template_title_path):
            raise FileNotFoundError(f"Template file not found: {template_title_path}")
        if not os.path.exists(template_slide_path):
            raise FileNotFoundError(f"Template file not found: {template_slide_path}")

        try:
            title_font = ImageFont.truetype(FONT_PATH, TITLE_FONT_SIZE)
            caption_font = ImageFont.truetype(FONT_PATH, CAPTION_FONT_SIZE)
            text_font = ImageFont.truetype(FONT_PATH, TEXT_FONT_SIZE)
            country_font = ImageFont.truetype(FONT_PATH, TITLE_FONT_SIZE)
        except Exception as font_e:
            raise Exception(f"Failed to load font at {FONT_PATH}: {font_e}")

        # Use a fixed folder name for the latest preview images
        folder_id = "current_preview"
        output_folder = os.path.join(TEMP_PREVIEW_DIR, folder_id)
        # Remove the folder if it already exists to override previous previews
        if os.path.exists(output_folder):
            import shutil
            shutil.rmtree(output_folder)
        os.makedirs(output_folder, exist_ok=True)

        images = []
        
        # Create title slide
        title_template = Image.open(template_title_path).convert("RGBA")
        draw_title_slide(title_template, title, country, caption, title_font, country_font, caption_font, TEXT_COLOR, color_scheme)
        title_path = os.path.join(output_folder, "title.jpg")
        title_template.convert("RGB").save(title_path, format="JPEG")
        images.append("title.jpg")
        
        # Create content slides for each sentence
        for i, sentence in enumerate(sentences):
            slide = Image.open(template_slide_path).convert("RGBA")
            draw_wrapped_text(slide, sentence, text_font, TEXT_COLOR, margin_percentage=30)
            slide_filename = f"slide_{i}.jpg"
            slide_path = os.path.join(output_folder, slide_filename)
            slide.convert("RGB").save(slide_path, format="JPEG")
            images.append(slide_filename)
        
        # Create CTA slide
        cta = Image.open(template_slide_path).convert("RGBA")
        draw_wrapped_text(cta, CTA_TEXT, text_font, TEXT_COLOR, margin_percentage=30)
        cta_path = os.path.join(output_folder, "cta.jpg")
        cta.convert("RGB").save(cta_path, format="JPEG")
        images.append("cta.jpg")
        
        # Read saved images and convert to base64 for preview
        preview_base64 = []
        for img_file in images:
            file_path = os.path.join(output_folder, img_file)
            with open(file_path, "rb") as f:
                encoded = base64.b64encode(f.read()).decode("utf-8")
                preview_base64.append(encoded)
        
        return jsonify({
            "status": "success",
            "folder_id": folder_id,
            "generated_images": images,
            "preview_base64": preview_base64,
            "message": f"Generated {len(images)} images and stored in folder '{folder_id}'"
        })
    
    except Exception as e:
        error_traceback = traceback.format_exc()
        print("ERROR in /generate-preview:", e)
        print("Traceback:", error_traceback)
        return jsonify({"error": str(e), "traceback": error_traceback}), 500

# Keep the original route for backward compatibility
@app.route('/static/preview_images/<filename>')
def serve_image(filename):
    path = os.path.join(TEMP_PREVIEW_DIR, filename)
    print(f"📂 Trying to serve image: {path}")
    if not os.path.exists(path):
        print(f"❌ Image NOT FOUND: {path}")
        return f"<h1>404 Not Found</h1><p>{filename} does not exist.</p>", 404

    # Add explicit headers to ensure browser interprets it as an image
    response = send_from_directory(TEMP_PREVIEW_DIR, filename)
    response.headers['Content-Type'] = 'image/jpeg'
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

if __name__ == '__main__':
    app.run(debug=True)