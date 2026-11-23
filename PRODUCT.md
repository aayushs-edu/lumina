# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Readers (primary on the home page):** people who come to read real, first-person accounts of everyday inequality and to see where it happens. After the hero, the home page's job is to pull them into stories and the atlas.
- **Storytellers:** people who have lived an inequality and post their own story anonymously. Sharing is the second action on the home page, earned by what readers see first.
- **Policy-minded visitors:** people using LuminaLens to compare countries' National Action Plans and generate policy drafts.

## Product Purpose

Lumina ("illuminating hidden inequalities") is an anonymous forum for stories about everyday inequality. Stories are tagged by country and theme, surfaced daily through a rotating spotlight theme, mapped on the Inequality Atlas against UN Gender Inequality Index data, and fed into LuminaLens, a policy simulator built on countries' National Action Plans.

## Positioning

Anonymous first-person stories placed next to the structural data that explains them: each story sits beside its country's Gender Inequality Index and NAP context, and the stories feed the policy generator.

## Operating Context

- Flutter web app (CanvasKit), Firebase/Firestore for stories, deployed to Netlify.
- Stories carry title, text, country, themes, keywords and likes; posting is anonymous.
- Themes: Workplace, Domestic, Education, Cultural, Public Space, Identity, Healthcare, Other. The home spotlight rotates daily through the first seven.
- Atlas data: GII index, rank, maternal mortality, adolescent birth rate, parliament seats, education and labour force by sex, story counts per country (bundled in `lib/models/gender_inequality_data.dart`).
- LuminaLens data: 198 countries' NAP records (`lib/naps_data.dart`); policy generation calls a Render-hosted backend.

## Capabilities and Constraints

- Home page: Aurora hero, Today's spotlight, top stories for the spotlight theme, Inequality Atlas (hover tooltip, click for country details), invitation to share, about Lumina.
- Routes: Explore (filterable story feed), Post a Story, LuminaLens.
- Home page copy is kept as written; layout and components may change.

## Brand Commitments

- Name written lowercase: "lumina". Tagline: "illuminating hidden inequalities". Hero eyebrow: "Anonymous stories of everyday inequality".
- Typeface: Baloo 2. Primary orange #FF6600 with amber and coral (the hero's Aurora palette).
- Hero: the animated Aurora background and its layout are approved and stay.
- No rounded corners on the home page: cards, buttons, tags and the navbar are square-cornered.
- Leaf illustrations exist as assets (`assets/*leaf*.png`).

## Evidence on Hand

- Real user stories in Firestore (titles, text, country, likes).
- Real GII statistics per country and NAP records.
- No testimonials, press, partner logos or usage numbers exist; none may be invented.

## Product Principles

1. Stories first: a visitor should be reading a real story within one scroll of the hero.
2. Anonymity is safety: nothing on the page should ask for or imply identity.
3. Context, not decoration: data appears to explain stories, never as ornament.
4. Quiet dignity: the subject is people's lived harm; the page stays warm and serious, never cute or salesy.
