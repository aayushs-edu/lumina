---
name: lumina
description: illuminating hidden inequalities
colors:
  orange: "#FF6600"
  orange-hover: "#FF7A24"
  orange-text: "#B84A00"
  aurora-coral: "#FF4B3E"
  aurora-amber: "#FFA23A"
  ink: "#2A1A16"
  ink-hover: "#45302A"
  soft: "#5B4740"
  paper: "#FFFCFA"
  white: "#FFFFFF"
  rule: "#EADBD2"
  cream: "#FFF1E6"
  cream-soft: "#D9C3B6"
  hotspot-extreme: "#800080"
  hotspot-high: "#FF0000"
  hotspot-medium: "#FFA500"
  hotspot-low: "#FAE105"
  hotspot-none: "#EEEEEE"
typography:
  display:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "96px (64px below 900px wide)"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-2.5px (-1.5px narrow)"
  headline:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "40-48px (34-36px narrow)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.8px"
  title:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.2
  body:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "18px (20px in the closing band, wide)"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1.2
  button:
    fontFamily: "Baloo 2, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.1
rounded:
  none: "0px"
spacing:
  gutter-narrow: "20px"
  gutter-mid: "40px"
  gutter-wide: "64px"
  entry: "24px"
  section-narrow: "64px"
  section-wide: "112px"
  close-wide: "120px"
components:
  button-ink:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.cream}"
    typography: "{typography.button}"
    rounded: "{rounded.none}"
    padding: "16px 26px"
  button-ink-hover:
    backgroundColor: "{colors.ink-hover}"
    textColor: "{colors.cream}"
  button-orange:
    backgroundColor: "{colors.orange}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.none}"
    padding: "16px 26px"
  button-orange-hover:
    backgroundColor: "{colors.orange-hover}"
    textColor: "{colors.ink}"
  nav-links-bar:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "4px 8px"
  story-entry:
    textColor: "{colors.ink}"
    typography: "{typography.title}"
    padding: "24px 0"
  theme-tag:
    backgroundColor: "{colors.cream}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "3px 8px"
  atlas-tooltip:
    backgroundColor: "{colors.white}"
    textColor: "{colors.soft}"
    rounded: "{rounded.none}"
    padding: "12px 14px"
    width: "240px"
---

# Design System: lumina

## Overview

**Creative North Star: "The Reading Room After the Aurora"**

The home page opens on the animated Aurora: soft pools of peach, coral, amber and rose light on a cream-to-white ground, with the lowercase wordmark set huge. Below it, that warm light settles into flat fields of colour. Brand orange is a solid block, warm white is the reading ground, and deep ink closes the page with cream text. Nothing below the hero glows, floats or slides on its own. The page is a reading room, not a dashboard: stories are excerpts divided by hairlines, the atlas sits in a single square frame, and emphasis comes from weight and size in one typeface.

The density is calm and editorial. Sections use generous vertical padding (112-120px wide, 64-72px narrow) and one horizontal gutter that steps with width. Every corner is square: buttons, tags, the nav links bar, the atlas frame, the tooltip and the country dialog. Depth is tonal. Only layers that genuinely float above the page (the atlas tooltip, the hero's primary call to action) cast a shadow, and that shadow has a real downward offset.

The subject is people's lived harm, so the system stays warm and serious. Colour carries warmth; it is never used to decorate data or to make the page feel playful.

**Key Characteristics:**
- Flat colour fields below the hero: orange block, warm-white reading ground, ink closing band.
- Baloo 2 is the only typeface; hierarchy comes from weight (400-800) and size.
- Square corners everywhere (0px).
- 1px warm hairlines (rule) separate content instead of cards.
- The Aurora hero is the only animated, gradient-lit surface.

## Colors

One warm family: a saturated orange, a red-brown ink with its softer reading tone, and warm whites and creams, with the Aurora's coral and amber kept for the hero.

### Primary
- **Lumina Orange** (orange): the brand colour as a field and fill. It is the spotlight block behind "Today's Spotlight", the background of the closing "Share Your Story" button, the "lumina" word inside closing headings (on ink), the nav wordmark, the hero primary button, and the atlas loading spinner. Hover lightens it to Lit Orange (orange-hover).
- **Burnt Orange Text** (orange-text): the orange that reads on warm white. Use it for story hover titles, the hover arrow, and country names in story metadata. Lumina Orange is not used for small text on light grounds.

### Secondary
- **Aurora Coral** (aurora-coral) and **Aurora Amber** (aurora-amber): the colours the hero wordmark's shimmer passes through, along with orange. The rest of the Aurora's light (peach #FFB38A, salmon #FF8A65, gold #FFC857, rose #FF9DB0, apricot #FFD6A5, and ribbon tones #FF7A59, #FFB347, #FF8FA3, #FFC46B, #FF6F61) lives only inside the hero background painter and is not used anywhere else.

### Neutral
- **Ember Ink** (ink): headings and primary text on light grounds, the "View Stories" button fill, the closing band's background, and focus outlines. Hover lightens it to ink-hover.
- **Warm Umber** (soft): body copy for excerpts, the atlas subtitle and legend labels, like counts, and tooltip text.
- **Warm Paper** (paper): the reading ground for the stories column and the atlas section, and the inside of the atlas frame. The scrolled-under navbar is this colour at 95% opacity (#F2FFFCFA).
- **Pure White** (white): floating or raised surfaces that sit above the ground: the nav links bar, the atlas tooltip, the country dialog and its metric boxes. The hero's light also fades to white at its lower edge.
- **Hairline Rose** (rule): every 1px border and divider: lines between story entries, the frames around the atlas, nav bar and tooltip, legend swatch outlines, loading bars.
- **Cream** (cream): text and button labels on ink, the square theme tag fill, and the top of the hero's background gradient. Closing-band dividers are cream at 14% opacity.
- **Dusk Cream** (cream-soft): body copy and the footer line on the ink band.

### Data
- **Hotspot scale** (hotspot-extreme, hotspot-high, hotspot-medium, hotspot-low, hotspot-none): Gender Inequality Index levels on the atlas map, legend swatches, the dialog's level chip and the tooltip swatch. Use these only to encode data, never as UI or brand colour. They are recorded as shipped (see Do's and Don'ts).

### Named Rules
**The Flat Field Rule.** Below the hero, colour arrives as solid blocks (orange, paper, ink). No gradients, no glows, no tinted overlays.

**The Readable Orange Rule.** Lumina Orange is a field or fill, or it sits on ink. On paper or white, orange text uses Burnt Orange Text.

**The Raised Is White Rule.** The ground is Warm Paper; anything floating above it (nav bar, tooltip, dialog) is Pure White with a Hairline Rose border.

## Typography

**Display Font:** Baloo 2 (Google Fonts, via google_fonts)
**Body Font:** Baloo 2
**Label Font:** Baloo 2

**Character:** One rounded, friendly-but-sturdy face does everything. Warmth comes from the letterforms, so the layout can stay strict.

### Hierarchy
- **Display** (800, 96px wide / 64px narrow, line-height 1.0, -2.5px / -1.5px): only the spotlight theme word, in ink on the orange field. It scales down to fit one line.
- **Headline** (700, 40-48px, line-height 1.05-1.1, -0.8 to -1px): section headings ("Today's Spotlight", "Top Stories" at 40px; "Inequality Atlas" at 48/36px; closing headings at 44/34px in cream).
- **Title** (700, 26px, line-height 1.2): story titles, wrapped in curly quotes, at most 2 lines.
- **Body** (400, 18px, line-height 1.55): story excerpts in Warm Umber, at most 3 lines, 680px max width. Closing-band copy is 20px (18px narrow) at line-height 1.6, max 620px wide.
- **Label** (600-700, 13-15px): story metadata (country 15/700 in Burnt Orange Text, likes 15/600), legend (heading 14/700, items 15/500), nav links (15/600, 14 compact), tooltip text (13).
- **Button** (700, 18px, line-height 1.1): square button labels. The hero's buttons use 17px.
- **Hero wordmark** (700, viewport-scaled, line-height 1.0, letter-spacing -2% of size): "lumina" in the hero only, filled by the orange/amber/coral shimmer. The tagline below it is 24/20px at weight 500.

### Named Rules
**The One Face Rule.** Baloo 2 is the only typeface. Emphasis comes from weight and size, never from a second family.

**The Solid Ink Heading Rule.** Headings are solid colour: ink on light grounds, cream on ink, with "lumina" picked out in orange. The hero wordmark's shimmer belongs to that wordmark alone.

## Layout

Full-bleed bands stacked vertically: Aurora hero, the spotlight/stories split, the atlas, and the ink closing band. Content inside bands is capped at 1200px and centred.

- **Gutter:** 20px below 600px wide, 40px from 600px, 64px from 1100px.
- **Wide split (900px and up):** the orange spotlight field takes 40% of the width (clamped to 360-600px) and runs the full height of the stories column. Stories have 64px left padding and 72px top and bottom. Below 900px, the field stacks above the stories (48/56px vertical padding).
- **Atlas:** 112px vertical padding wide, 64px narrow. Header and legend share a row, aligned to the bottom, when wide; they stack when narrow. The map frame has 32px inner padding wide, 8px narrow.
- **Closing band:** 120px top padding wide (72px narrow). Columns split 6:5 with a 96px gap and stack below 900px with 56px between them. A 1px cream hairline and the footer line sit at the bottom.
- **Navbar:** an 80px toolbar laid over the hero. The links bar is centred and the wordmark sits left; below 640px the links bar moves to the right.
- **Rhythm:** 24px vertical padding per story entry, 8px from title to excerpt, 12px from excerpt to metadata, 20px from heading to body, 32-40px from body to action.

## Elevation & Depth

The system is flat. Depth comes from tone (paper ground, white floating layers, the ink band) and from 1px hairlines. Shadows appear only on layers that genuinely float, and they always have a downward offset.

### Shadow Vocabulary
- **Floating layer** (`0 6px 18px rgba(42,26,22,0.12)`): the atlas hover tooltip.
- **Hero call to action** (`0 8px 18px rgba(255,90,42,0.32)`, hover `0 8px 26px rgba(255,90,42,0.5)` with a 2px lift): the hero's primary button only, part of the approved hero.

### Named Rules
**The Flat-By-Default Rule.** Sections, story entries, buttons below the hero, tags and frames have no shadow. A shadow means the element floats above the page.

## Shapes

Every corner is square (0px): buttons, tags, the nav links bar, the atlas frame, legend swatches, the tooltip, and the country dialog (whose rounded default is explicitly overridden). Borders are 1px Hairline Rose. Focus states are drawn as 2px square outlines or underlines. The one organic shape is the waving orange leaf illustration, cropped by the right edge of the closing band on wide screens.

**The Square Corner Rule.** No border radius anywhere on the home page. Any new component starts at 0px.

## Components

### Buttons
Solid, square, and direct, with an arrow that moves.
- **Shape:** square (0px), 16px by 26px padding, 18px/700 label, followed by a 20px arrow-forward icon after a 12px gap.
- **Ink button** (button-ink): on the orange field ("View Stories").
- **Orange button** (button-orange): on the ink band ("Share Your Story").
- **Hover / Focus:** the background lightens over 160ms ease-out, and the arrow slides right by 25% of its width over 180ms ease-out-cubic. Keyboard focus draws a 2px border in the label colour.
- **Hero buttons (hero only):** the primary is orange with ink text, 14px by 26px padding, a 17px label and a lifting orange shadow. The ghost is ink at 5% opacity (12% on hover) with an ink border at 22% opacity (40% on hover).

### Chips
- **Theme tag (square variant):** cream fill, 1px Hairline Rose border, ink 13px/600 text, 3px by 8px padding. Used in the country dialog's "Most Prevalent Themes".
- **Hotspot level chip:** white with a 1px rule border, 12px by 6px padding, a square swatch and the level name at 14px bold in ink.

### Cards / Containers
There are no cards on the home page. Content is separated by hairlines.
- **Story entry:** a 1px Hairline Rose top border and 24px vertical padding. Hover or focus turns the title Burnt Orange Text and fades in an arrow that slides in from the left (180ms). Keyboard focus adds a 2px ink outline. The loading state uses rule-coloured bars in the same rhythm.
- **Atlas frame:** a Warm Paper fill, a 1px rule border, square, clipped hard.
- **Metric box (dialog):** white, 1px rule border, 16px padding, 140px wide. Label is 14px/500 in Warm Umber; value is 24px bold in ink.

### Navigation
- **Wordmark:** "lumina" at 22px/800 (20px compact), always orange.
- **Links bar:** a square white bar with a 1px rule border. Links are 15px/600 in ink. Hover and active turn orange, and the active link gets a 2px orange underline. Keyboard focus draws a 2px ink underline.
- **Scroll state:** transparent over the hero. Once content scrolls under it, the bar becomes Warm Paper at 95% opacity with no elevation.

### Atlas Tooltip and Country Dialog
- **Tooltip:** follows the pointer 10px down and right. Square white surface with a rule border and the floating-layer shadow, max 240px wide. The country name is 17px/700 in ink; detail text is 13px in Warm Umber, with a 9px hotspot swatch.
- **Dialog:** square, white, 500px wide, 24px padding. The country name is 28px bold in ink; the close icon is Warm Umber. A rule divider separates the metrics from the inequality detail panels, which are Warm Paper with a rule border.

### Aurora Hero (signature)
An approved, animated field of soft light: drifting colour pools and silk ribbons over a cream-to-white gradient, with fine grain. It leans toward the pointer and fades to white at its lower edge. Above it sit the shimmering wordmark, the tagline, the primary and ghost buttons, and a bobbing scroll cue (#7A4A3A). It renders off-screen at 0.33 scale and pauses when out of view. The hero is fixed; extend the page around it, not inside it.

## Do's and Don'ts

### Do:
- **Do** set colour as flat fields: orange (#FF6600) blocks, Warm Paper (#FFFCFA) reading grounds, Ember Ink (#2A1A16) bands with cream (#FFF1E6) text.
- **Do** use Burnt Orange Text (#B84A00) for any orange text on paper or white.
- **Do** separate content with 1px Hairline Rose (#EADBD2) rules instead of cards.
- **Do** keep every corner at 0px, including dialogs, tooltips and tags.
- **Do** give every interactive element a hover state and a 2px square keyboard focus treatment, as the square buttons, story entries and nav links have.
- **Do** step the gutter 20 / 40 / 64px at 600 / 1100px, and cap content at 1200px.

### Don't:
- **Don't** add a border radius anywhere on the home page.
- **Don't** use gradient or glowing text outside the hero wordmark.
- **Don't** use a typeface other than Baloo 2.
- **Don't** put shadows on resting surfaces. A shadow is only for a floating layer and always has a downward offset.
- **Don't** use the hotspot data colours for UI, brand or decoration.
- **Don't** reuse the Aurora's light, ribbons or shimmer outside the hero.
