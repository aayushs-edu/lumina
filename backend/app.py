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
import pandas as pd
import re
import numpy as np
from sklearn.cluster import KMeans
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from sklearn.metrics import silhouette_samples, silhouette_score
import re
import openai

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

feature_cols = [
    'GII_Rank', 'Military_Expenditure',
    'Proportion of women subjected to physical and/or sexual violence in the last 12 months (% of ever partnered women ages 15-49)',
    'Mean age at first marriage, female',
    'Women making their own informed decisions regarding sexual relations, contraceptive use and reproductive health care  (% of women age 15-49)',
    'There is legislation on sexual harassment in employment (1=yes; 0=no)',
    'Women and men have equal ownership rights to immovable property (1=yes; 0=no)',
    'CEDAW', 'Arms_Trade_Treaty'
]

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

@app.route('/generate-policy', methods=['POST'])
def generate_policy():
    data = request.get_json()
    country = data.get("country", "")
    focus_areas = data.get("focus_areas", [])
    stored_naps_path = "data/stored_naps.csv"

    df = pd.read_csv("data/data.csv")

    ###### Check if the response already exists
    if os.path.exists(stored_naps_path):
        stored_naps = pd.read_csv(stored_naps_path)
        existing_row = stored_naps[stored_naps['Country'] == country]
        if not existing_row.empty:
            print(f"▶ Returning cached NAP for: {country}")
            output = existing_row.iloc[0]['Output']
            chunks = extract_chunks(output)
            return jsonify({"output": chunks})

    print(f"\n▶ Generating NAP for: {country}")

    output = generate_nap_for_country(df, country, focus_areas, alternate=False)

    ###### Save the response to the CSV
    new_row = {"Country": country, "Output": output}
    if os.path.exists(stored_naps_path):
        stored_naps = pd.read_csv(stored_naps_path)
        stored_naps = pd.concat([stored_naps, pd.DataFrame([new_row])], ignore_index=True)
    else:
        stored_naps = pd.DataFrame([new_row])

    stored_naps.to_csv(stored_naps_path, index=False)
    print(f"▶ Saved NAP for {country} to {stored_naps_path}")

    # Extract chunks from the output
    chunks = extract_chunks(output)

    return jsonify({"output": chunks})

@app.route('/enhance-policy', methods=['POST'])
def enhance_policy():
    data = request.get_json()
    country = data.get("country", "")
    focus_areas = data.get("focus_areas", [])
    stored_naps_path = "data/stored_naps.csv"

    df = pd.read_csv("data/data.csv")

    df['Legislation_Parsed'] = df['legislation'].apply(parse_legislation)


    ###### Check if the response already exists
    if os.path.exists(stored_naps_path):
        stored_naps = pd.read_csv(stored_naps_path)
        existing_row = stored_naps[stored_naps['Country'] == country]
        if not existing_row.empty:
            print(f"▶ Returning cached NAP for: {country}")
            output = existing_row.iloc[0]['Output']
            chunks = extract_chunks(output)
            return jsonify({"output": chunks})

    print(f"\n▶ Generating NAP for: {country}")

    output = generate_nap_for_country(df, country, focus_areas, alternate=True)

    ###### Save the response to the CSV
    new_row = {"Country": country, "Output": output}
    if os.path.exists(stored_naps_path):
        stored_naps = pd.read_csv(stored_naps_path)
        stored_naps = pd.concat([stored_naps, pd.DataFrame([new_row])], ignore_index=True)
    else:
        stored_naps = pd.DataFrame([new_row])

    stored_naps.to_csv(stored_naps_path, index=False)
    print(f"▶ Saved NAP for {country} to {stored_naps_path}")

    # Extract chunks from the output
    chunks = extract_chunks(output)

    return jsonify({"output": chunks})

def generate_nap_for_country(df, country, focus_areas, alternate):
    print(f"\n▶ Generating NAP for: {country}")

    row = df[df['Country'] == country].iloc[0]
    similar = df[(df['Cluster'] == row['Cluster']) & (df['Country'] != country)].head(3)
    comparison = compare_country_to_peers(df, country, feature_cols)
    prompt = build_formatted_prompt(country, row, df, similar, comparison, alternate, focus_areas)
    nap_output = generate_nap_gpt(prompt)

    print(f"\n✅ Generated NAP for {country}:\n{nap_output}")

    return nap_output


def extract_chunks(output):
    """
    Extract chunks from the raw output based on headers surrounded by double asterisks (**).
    Each chunk includes its header and corresponding content.
    """
    chunks = []
    lines = output.split("\n")
    current_chunk = {"header": None, "content": ""}

    for line in lines:
        if line.startswith("**") and line.endswith("**"):
            # Save the previous chunk if it exists
            if current_chunk["header"]:
                chunks.append({
                    "header": current_chunk["header"],
                    "content": current_chunk["content"].strip()
                })
            # Start a new chunk
            current_chunk = {"header": line.strip("**").strip(), "content": ""}
        else:
            # Append content to the current chunk
            current_chunk["content"] += line + "\n"

    # Add the last chunk if it exists
    if current_chunk["header"]:
        chunks.append({
            "header": current_chunk["header"],
            "content": current_chunk["content"].strip()
        })

    return chunks

### Helper methods
def compare_country_to_peers(df, country, feature_cols):
    base = df[df['Country'] == country].iloc[0]
    cluster_peers = df[(df['Cluster'] == base['Cluster']) & (df['Country'] != country)]
    region_peers = df[(df['Region'] == base['Region']) & (df['Country'] != country)]
    metrics = {}
    for col in feature_cols:
        # Convert the column to numeric, coercing errors to NaN
        cluster_peers[col] = pd.to_numeric(cluster_peers[col], errors='coerce')
        region_peers[col] = pd.to_numeric(region_peers[col], errors='coerce')
        
        val = base[col]
        cluster_avg = cluster_peers[col].mean()
        region_avg = region_peers[col].mean()
        metrics[col] = {
            'value': val,
            'cluster_avg': cluster_avg,
            'region_avg': region_avg
        }
    return metrics

def parse_legislation(text):
    laws = []
    if pd.isna(text):
        return laws
    for entry in re.split(r"\n|;", text):
        parts = entry.split(":", 1)
        if len(parts) == 2:
            name = parts[0].strip()
            desc = parts[1].strip()
            laws.append({'name': name, 'description': desc})
    return laws

def build_formatted_prompt(country, row, df, similar_df, comparison_metrics, alternate, focus_areas):
    NAP_full = df.loc[df["Country"] == country, "NAP_Text_Clean"].iloc[0]
    laws = row['Legislation_Parsed']
    law_text = "\n".join([f"- {law['name']}: {law['description']}" for law in laws])

    similar_context = ""
    for _, r in similar_df.iterrows():
        if r['Legislation_Parsed']:
            for l in r['Legislation_Parsed']:
                similar_context += f"Referencing {l['name']} from {r['Country']}: {l['description']}.\n"

    comparison_text = ""
    for metric, vals in comparison_metrics.items():
        comparison_text += f"{metric}: {vals['value']} (Cluster avg: {vals['cluster_avg']:.2f}, Region avg: {vals['region_avg']:.2f})\n"
    
    # Check if NAP_Summary is present
    if alternate:
        # Use alternate prompt if NAP_Summary exists
        # ***PASTE ALTERNATE PROMPT HERE***
        full_prompt = f"""
        
        **You are a policy assistant tasked with refining and strengthening a country's existing National Action Plan (NAP) for gender equality. You will be given the following information:**

        1. Country
        2. Existing legislation implemented by that country for women's rights
        3. Legislation from other countries to be used in analysis
        4. Which cluster each country belongs to. Cluster 0 should be disregarded as having any significance when drawing connections/conclusions in your response, only consider clustering if it is not cluster 0.
        5. Important data that should be used as points for comparison against other countries, especially countries in the same cluster or geographical region:
          - Proportion of women subjected to physical and/or sexual violence in the last 12 months (% ever-partnered, 15-49)
          - Sexual-harassment-in-employment legislation (1=yes; 0=no)
          - Equal immovable-property-ownership rights (1=yes; 0=no)
          - Women making their own informed decisions regarding sexual relations, contraceptive use and reproductive health care (% of women age 15-49)
          - Mean age at first marriage (female)
          - NAP_full (The existing NAP of the country)
          - CEDAW ratification status
          - Gender Inequality Index rank
          - Arms Trade Treaty signature status
          - Military Expenditure (if value has an 'M', the number is in millions of dollars. if value has a 'B', the figure is in billions of dollars.)

        6. The existing NAP of the current country at hand, with the following sections:
        - Actors
        - Timeframe
        - Objectives
        - Actions/Activities
        - Indicators
        - M&E (Monitoring and Evaluation)
        - Budget
        - Disarmament

        7. Focus areas for the refined NAP to address and specifically hone in on.

        Country:
        {country}

        Legislation:
        {law_text}

        Peer Legislation Examples:
        {similar_context}

        Data Comparison to Regional and Cluster Peers:
        {comparison_text}

        **Current NAP Summary:**
        {NAP_full}

        **Focus Areas:**
        {focus_areas}

        **1. Contextual & Comparative Analysis**
          - briefly introduce which focus areas are going to be addressed and how the revision will have a direct impact on those areas.
          - Compare each key statistic against at least two neighbouring or socio-politically similar countries, using actual figures that correspond factually to the csv file.
            - 'Peer' countries should be determined if one or more of the following are similar, based on your own knowledge and the data provided in the csv file:
              - regional proximity, economy, government structure, political climate, social/gender norms
          - Draw 2-3 insights on how legislative gaps constrain women's rights, economic participation, or safety.

        **2. Legislative & Policy Gap Assessment**

          - Take silent note of any “0” flags in the legislation columns, and use this fact that weave rhetoric about the absence of legislation.
          - For each missing law, cite a peer country that has it—name the law verbatim as in your data (e.g. Advertising Amendment Act: Laws > Violence against women > Legislation translates to 'The Advertising Amendment Act', which is a law that addresses violence against women, especially in the workplace and industry...'') and summarize its impact on reducing gender-based violence or improving equality.
          - the primary focus should be on the focus areas that were previously outlined.
          - Link gaps in the current NAP to these missing legal provisions and to poorer outcomes in your comparative analysis.

        **3. Improvement Plan for the Existing NAP**

          - Highlight 2-3 Missing or Weak Issues in the current summary (e.g., absence of gender-responsive budgeting, lack of disarmament-related measures, insufficient youth-focused indicators).
          - Propose Concrete Amendments or New Measures to each (e.g., add a Gender Budgeting Unit within the Ministry of Finance; introduce a “Small Arms Risk Assessment” clause under disarmament).
          - Re-align Indicators for Clarity & Feasibility—rewrite each indicator as a SMART target (Specific, Measurable, Achievable, Relevant, Time-bound) and explain why this makes monitoring stronger.
          - again, focus on the focus areas outlined at the beginning.

        **4. Peer-Practice Recommendations**

          - For every major amendment, reference a “best practice” peer country with similar socioeconomic and political context.
          - Explain how that measure improved their relevant statistic

        **5. GII Ranking & Resource Realignment**

          - The Gender inequality index country-ranking is also provided, and is based on several factors:
          - maternal mortality, which may indicate a poor prioritization of women's healthcare
          - adolescent birth rate, which indicates early childbirth (age 15-19)
          - female seats in parliament
          - percent of females who have secondary education
          - female labor force participation
          - the lower the number, the better the country is for women. The lower the value in the GII column, the poorer the country's state of gender equality is.

          - Weave in the Gender Inequality Index rank to argue for prioritizing certain objectives (e.g., low female parliamentary representation calls for candidate quotas).
          - Identify any budgetary trade-offs—only if warranted—such as reallocating a small fraction of military expenditure to gender-sensitive projects, but focus on necessary new funding sources (e.g., international grants, public-private partnerships).

        **6. Revised NAP Outline**

          The revision should have a clear focus on the specific focus areas previously listed. It should be fairly obvious which focus areas are being addressed.

          **first structure a streamlined skeleton of the full NAP based on the existing summary, but with your amendments integrated under each section:**

          - Updated Objectives (3-5, incorporating new measures)
          - Time-bound Actions & Responsible Actors
          - SMART Indicators & M&E Plan (with brief rationale sentences)
          - Tentative Budget & Funding Sources (realistic figures, or an amount aligned with comparable countries)
          - Disarmament/Gender Security Measures
          - NEVER use variables or placeholders. Saying something vague like $X for a budget is unnacceptable. Either use concrete figures or don't use them at all.

          - New Legislative Proposals (name, scope, enforcement mechanism)

          **REMEMBER, THE FOCUS OF THE NAP SHOULD BE MANIFESTLY ADDRESSING THE ISSUES THAT FALL UNDER THE TOPICS OUTLINED IN THE FOCUS AREAS AT THE BEGINNING OF THIS INSTRUCTION.**

          **Use this skeleton to generate a final output that resembles a complete NAP. Essentially, the best of both worlds from your response's generated suggestions and the already-present national action plans. IT IS OK TO NOT HAVE CHANGES FOR CERTAIN ASPECTS: you can keep things the same as outlined in the summary if there doesn't need to be immediate change**


          YOUR RESPONSE SHOULD BE POLISHED AND PROFESSIONAL, AND SHOULD NOT APPEAR SIMPLY AS A 'RESPONSE' BUT AS A PROFESSIONAL POLICY MEMO THAT DOES NOT REFERENCE INSTRUCTION OR THOUGHTS DURING THE RESPONSE.

        **7. Final Commentary on Changes**

          - At the end, briefly list all which issues were added or strengthened, how indicators were re-defined, and why these changes will make the NAP more effective, concrete, and practicable.

        **8. Referenced Countries & Cited Legislation**

          **At the very bottom, include which laws and which countries were cited throughout the response. separate it (whitespace) from the rest of the response:**

          - Referenced Countries: [Peer A, Peer B, Peer C]
          - Cited Legislation: [Peer A: Law Title, Peer B: Law Title, …]

        """
    else:
        # Use original prompt if NAP_Summary is missing
        full_prompt = f"""
        **You are a policy assistant that drafts a country's National Action Plan (NAP) for gender equality. You will be given the following information:**

        1. Country
        2. Existing legislation implemented by that country for women's rights
        3. Legislation from other countries to be used in analysis
        4. Which cluster each country belongs to. Cluster 0 should be disregarded as having any significance when drawing connections/conclusions in your response, only consider clustering if it is not cluster 0.
        5. Important data that should be used as points for comparison against other countries, especially countries in the same cluster or geographical region:
          - Proportion of women subjected to physical and/or sexual violence in the last 12 months (% ever-partnered, 15-49)
          - Sexual-harassment-in-employment legislation (1=yes; 0=no)
          - Equal immovable-property-ownership rights (1=yes; 0=no)
          - Women making their own informed decisions regarding sexual relations, contraceptive use and reproductive health care (% of women age 15-49)
          - Mean age at first marriage (female)
          - NAP_full (The existing NAP of the country)
          - CEDAW ratification status
          - Gender Inequality Index rank
          - Arms Trade Treaty signature status
          - Military Expenditure (if value has an 'M', the number is in millions of dollars. if value has a 'B', the figure is in billions of dollars.)
        6. Focus areas that your NAP will address

        **Country:**
        {country}

        **Legislation:**
        {law_text}

        **Peer Legislation Examples:**
        {similar_context}

        **Data Comparison to Regional and Cluster Peers:**
        {comparison_text}

        **Focus Areas:**
        {focus_areas}

        ---

        **1. Contextual Analysis**

          - Compare each statistic against at least two neighboring or socio-politically similar countries (e.g., proximity, economy, democratic structure, defence profile).
          - Draw out 2-3 key insights (e.g. “Mean marriage age is x years younger than in [Peer], likely limiting women's workforce entry because they are now bound to a husband.”).

        **2. Legislative Gap Assessment**

          - Identify any “0” flags in the legislation columns.
          - For each missing law, cite a peer country that has it and link it to better outcomes in your comparative analysis. Cite specific laws from the legislation column.
          - Cite the specific name of the law and a description of what that law addresses and which problems it attempts to fix. Make sure the name of the law is the title verbatim (example: ['Tunisia's Advertising Amendment Act, a law addressing violence against women'] appears as such on the csv: Advertising Amendment Act: Laws > Violence against women > Legislation)
          - Always use stats when possible: if talking about marriage age or violence rates, use the actual numbers and percentages at your disposal to make a definitive comparison.

        **3. Writing the NAP**

          - **Draft a complete NAP** with a clear focus on the specific focus areas previously listed. It should be fairly obvious which focus areas are being addressed. Your NAP should be structured as follows:
            - Clear Objectives (3-5)
            - Time-bound Actions & Actors
            - Indicators & M&E plan
            - Tentative Budget & Funding sources
            - Disarmament/defence-related gender measures
            - Required new legislation (with model text references)
            - Highlighting 2-3 missing issues (based on your gap analysis)
            - Proposing concrete amendments or new measures
            - Re-aligning indicators for clarity and feasibility
            - Discuss poor budgetary and funding decisions that could potentially hinder women's progress (military expenditure is unecessarily high, resources can be diverted to a new department, etc.) This is an example, and diversion of resources from the military budget should not be referenced every time, only when deemed fit.

        **4. Peer-Practice Recommendations**

          - For each major recommendation, reference a “best practice” peer.
          - Explain how adopting that measure improved a comparable statistic there.

        **5. GII Ranking Analysis**

          - The Gender inequality index country-ranking is also provided, and is based on several factors:
          - maternal mortality, which may indicate a poor prioritization of women's healthcare
          - adolescent birth rate, which indicates early childbirth (age 15-19)
          - female seats in parliament
          - percent of females who have secondary education
          - female labor force participation
          - the lower the number, the better the country is for women. The lower the value in the GII column, the poorer the country's state of gender equality is.
          - Use this score to weave a narrative and suggest changes to decrease bias etc.

        **6. Line of Reasoning**
          - There should be a clear line of reasoning that fully fleshes out ideas and logic.
          - *Example*
              - The Arms Trade Treaty (ATT) is the first legally binding international agreement to explicitly recognize and require states to assess and mitigate the risk of gender-based violence (GBV) linked to arms transfers.
              - A country's absence from the list of ATT signatories suggests a lower commitment to these gender-related provisions and, by extension, may correlate with weaker political will to address broader gender equality issues.
              - By not signing the ATT, a government effectively opts out of legally bound gender-sensitive arms assessments. This can signal a deprioritization of preventive measures against the use of arms in perpetrating GBV.
              - *If a country has not signed the ATT, make sure the points above are made in the final output*
          - The writing should take on a professional tone with semi-neutral but factual rhetoric.
          - ALWAYS be concrete, avoid vague statements. Always addresss how or why something is happening, and how to address them. Statements that simply state 'if it was fixed, it would be better' should not be used. Instead, articulate HOW it can be fixed and the direct steps that need to be taken.
          - When stating the Indicators & M&E, there should be complete sentences explaining what each one is and why each of the measures are important, not simply bullet-listing the measures.
          - when discussing age of marriage etc, REFERENCE THE ACTUAL AGE. Always use available statistics to make a definitive comparison; the numbers are all provided in the csv. You must reference percentages, ages, rates, numbers, amounts, etc. STATS MUST BE USED.
          - NEVER use variables or placeholders. Saying something vague like $X for a budget is unnacceptable. Either use concrete figures or don't use them at all.
      7. **Final Output**
        - Write as a polished policy memo, with sections:
          1. Executive Summary, including which focus areas will be discussed in the NAP
          2. Context & Comparative Analysis
          3. Legislative Gaps & Peer Practices
          4. NAP (New or Revised)
          5. Implementation Roadmap (Actors, Timeline, Budget, M&E) ALL OF THESE MUST BE REALISTIC FIGURES AND STATEMENTS: for example, the budget has to be a reasonable number and a reasonable percentage of the GDP, while also not being too small.
            - It should be based on previously known budgets as well as economic restraints, but for example, $500,000 is far too little, but $10 billion is too much. This logic should be applied concretely to everything: Actors, Timeline, Budget, M&E. Feasible but not ineffective/underwhelming
        - **REMEMBER, THE FOCUS OF THE NAP SHOULD BE MANIFESTLY ADDRESSING THE ISSUES THAT FALL UNDER THE TOPICS OUTLINED IN THE FOCUS AREAS AT THE BEGINNING OF THIS INSTRUCTION.**
        - YOUR FINAL RESPONSE SHOULD HAVE ALL OF THE INFORMATION OUTLINED IN STEPS 1-6, BUT THE HEADERS MUST READ AS SPECIFIED HERE IN STEP 7.


          **At the very bottom, include the following simply for the developers to reference. separate it from the rest of the response:**

          - Referenced Countries: [Peer A, Peer B, Peer C]
          - Cited Legislation: [Peer A: Law Title, Peer B: Law Title, …]

        """

    return full_prompt

def generate_nap_gpt(prompt, max_tokens=1024):
    response = openai.chat.completions.create(
        model="gpt-3.5-turbo-0125",
        messages=[
            {"role": "system", "content": "You are a helpful policy drafting assistant."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=max_tokens,
        temperature=0.7
    )
    # Access the content using .content instead of ['content']
    return response.choices[0].message.content

if __name__ == '__main__':
    app.run(debug=True)