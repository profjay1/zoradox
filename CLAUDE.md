# ZORADOX — Landing Page

ZORADOX is an IT company that designs and builds websites and web applications for
startups, medium-sized businesses and large enterprises. This repo holds the company's
public landing page. Its job: look professional, load instantly, and turn visitors
into consultation requests.

## Current phase: 1 — Static landing page

- **Stack: HTML5, modern CSS, vanilla JavaScript. Nothing else.**
- No frameworks, no build step, no npm packages, no CSS frameworks (no Tailwind, no Bootstrap).
- Files are served as-is by Nginx on a VPS.
- Do not introduce any tool that requires compiling or bundling. If something seems to
  need one, stop and ask first.

## Roadmap (keep code ready for this)

1. **Now:** static landing page (this repo, `site/`).
2. **Next:** Spring Boot API in `backend/` — contact form will POST JSON to `/api/contact`
   (leads saved to PostgreSQL, email notification). Nginx proxies `/api` to Spring.
3. **Later:** migrate `site/` to Angular 22+ with prerendering when the site needs many
   pages (blog, case studies). Each `<section>` becomes an Angular component, and the CSS
   custom properties become the design system.
4. **Eventually:** admin area, CMS-style content, full engineering website.

Write everything so step 3 is a copy-and-split job, not a rewrite.

## Project structure

```
zoradox/
├── site/
│   ├── index.html
│   ├── 404.html
│   ├── thank-you.html        # no-JS form redirect target (noindex, not in sitemap)
│   ├── privacy.html
│   ├── robots.txt
│   ├── sitemap.xml
│   ├── css/
│   │   └── styles.css        # tokens → base → layout → one block per section
│   ├── js/
│   │   ├── main.js           # entry point, type="module"
│   │   └── modules/          # nav.js, reveal.js, contact-form.js ...
│   └── assets/
│       ├── fonts/            # self-hosted woff2
│       ├── img/              # WebP/AVIF + fallbacks, explicit width/height
│       └── icons/            # inline-able SVGs, favicon set
├── design/                   # source assets + tooling, not deployed
│   ├── subset-fonts.sh       # fonts-src/ → site/assets/fonts/
│   ├── generate-images.sh    # favicon.svg + og-image.html → favicon set, logo, OG image
│   └── og-image.html         # 1200×630 OG template (uses site tokens and fonts)
├── backend/                  # Phase 2 (empty for now)
├── infra/                    # nginx.conf, deploy script
└── CLAUDE.md
```

## Brand & design direction: "Blueprint"

A precise, engineering aesthetic: built by engineers, for businesses.

- Dark base with a subtle blueprint grid pattern (CSS background, not an image).
- Monospace section labels, e.g. `// 01 — SERVICES`.
- One electric accent color, used sparingly for CTAs, highlights and focus rings.
- Generous whitespace, sharp alignment, thin 1px borders, restrained motion.

### Design tokens (define on `:root`, never hard-code values in sections)

```css
--color-bg:        #0A0E1A;
--color-surface:   #111827;
--color-border:    #1F2937;
--color-text:      #E5E7EB;
--color-muted:     #9CA3AF;
--color-accent:    #22D3EE;   /* electric cyan */
--color-accent-2:  #6366F1;   /* indigo, for gradients only */

--font-sans: "Inter", "Inter Fallback", system-ui, -apple-system, "Segoe UI", sans-serif;
--font-mono: "JetBrains Mono", ui-monospace, "SFMono-Regular", monospace;
```

Also define tokens for: spacing scale, radius, max content width, fluid type scale
using `clamp()`, transition durations. Fonts are self-hosted woff2 with
`font-display: swap`; preload only the main text weight.

## Business details (confirmed)

- Public email: `contact@zoradox.com`
- Location wording: "Based in Canada, working with clients worldwide."
  No street address, city, province or phone number anywhere (copy, footer, JSON-LD).
- Free intro call booking link: `https://cal.com/zoradox/intro-call`
  (plain link, opens in a new tab with `rel="noopener"`; no Cal.com embed script).
- Web3Forms access key (public, safe in client code):
  `f189591f-554b-4ec9-977c-fb60d2ab607e`
- Services that process visitor data: Web3Forms (form), Cal.com (booking),
  Zoho Mail (email).
- Social links: none yet. Don't add a social links area, `sameAs` or
  `twitter:site` until they exist; they'll be added later.

## Page sections (in order)

Each is a `<section class="[name]" id="[name]">` with its own CSS block:

1. `header` — logo/wordmark, nav anchors, "Book a free call" button, mobile menu
2. `hero` — headline, subline naming the three audiences, two CTAs
3. `audiences` — Startups / Medium businesses / Enterprises (three cards)
4. `services` — websites, web apps, e-commerce, UI/UX, APIs & integrations, maintenance
5. `process` — Discover → Design → Build → Launch → Support (timeline)
6. `stack` — technologies we work with
7. `work` — case studies / concept projects
8. `pricing` — ways to work with us (fixed scope, dedicated team, ongoing support)
9. `faq` — use native `<details>`/`<summary>`, no JS needed
10. `contact` — final CTA, contact form, booking link
11. `footer` — wordmark, tagline, nav links, email, location line, privacy link,
    copyright (no socials yet)

## Conventions

### HTML
- Semantic elements: `header`, `nav`, `main`, `section`, `article`, `footer`.
- One `<h1>` (in the hero); logical heading order after that.
- Every image: `alt`, `width`, `height`, `loading="lazy"` (except above-the-fold),
  `decoding="async"`. Use `<picture>` for WebP/AVIF.

### CSS
- Single `styles.css`, organized in this order: tokens → reset/base → layout utilities
  → one clearly commented block per section (`/* ===== HERO ===== */`).
- Class naming: BEM-style scoped to the section (`.hero__title`, `.services__card`).
  This maps directly to future Angular components.
- Mobile-first; use Grid/Flexbox; fluid sizing with `clamp()`.
- Respect `prefers-reduced-motion`: disable non-essential animation.
- Visible `:focus-visible` styles on every interactive element.

### JavaScript
- ES modules, loaded with `<script type="module" src="js/main.js">`.
- One small module per feature; `main.js` only imports and initializes.
- Progressive enhancement: the page must be fully readable and the form usable
  without JS (the form falls back to a normal POST).
- No libraries. Use `IntersectionObserver` for scroll reveals, `fetch` for the form.

### Contact form
- Phase 1: submits to Web3Forms with the access key under "Business details".
  The email subject and from name are set in the Web3Forms dashboard, not as fields.
- Keep the submit logic in `js/modules/contact-form.js` behind one function
  (`submitLead(data)`) so Phase 2 only swaps the endpoint to `/api/contact`.
- Fields: `name` (subject uses `{field:name}`), `email` (Web3Forms uses it as
  reply-to), `company` (optional), project type (required select), message.
  No budget field. Honeypot: Web3Forms' `botcheck` checkbox.
- Without JS: normal POST, with Web3Forms' hidden `redirect` field pointing to
  `https://zoradox.com/thank-you.html`.
- Local previews (localhost / file) mock the request; never send real test
  submissions. `?mock=error` tests the error state, `?live` sends for real.
- Clear success and error states, announced to screen readers (`aria-live`).

## Quality targets

- Lighthouse 95+ in Performance, Accessibility, Best Practices and SEO on mobile.
- Total page weight under ~500 KB on first load (excluding lazy images).
- No layout shift: reserve space for images and fonts.
- WCAG AA color contrast.

## SEO checklist

- Unique `<title>` and meta description.
- Open Graph and Twitter card tags with a 1200×630 OG image.
- `schema.org` `Organization` (and `ProfessionalService`) JSON-LD.
- Canonical URL, `robots.txt`, `sitemap.xml`, favicon set, `theme-color`.

## Content rules

- **Never invent testimonials, client names, client logos, statistics or awards.**
- Concept or sample projects must be clearly labeled as such.
- When real content is missing, use obvious placeholders like `[CLIENT PROJECT NAME]`
  and list them at the end of your reply so they can be filled in.
- Tone: confident, clear, technical but not jargon-heavy. Short sentences.
- Use typographic apostrophes and quotes (’ “ ”) in all visible copy; straight ones
  (' ") in code and attributes.
- Never mention code ownership.
- Pricing section: no prices or price-related numbers. Show the ways of working,
  each with a "Get a quote" button.
- Don't promise fixed prices in general. The Fixed scope model in the pricing section
  may say scope and price are agreed before work starts, for that model only.
- The first intro call (30 minutes) is free. Never describe deeper consulting,
  discovery or audits as free.
- Confirmed promises, may be used anywhere:
  - Documentation and handover.
  - Development in small, tested increments.
  - Post-launch support, in general wording only. No free period or duration.
  - Regular progress demos during development, with no fixed schedule
    (e.g. "regular check-ins where you see your project take shape").

## How to work with me

- I am actively learning. Briefly explain non-obvious decisions (why a CSS technique,
  why an attribute, why a JS pattern) in chat, not as long comments in the code.
- Build one section at a time and stop for review before moving on.
- Prefer the simplest solution that meets the quality targets.
- After each change, tell me how to preview it (open `site/index.html` or run
  `python3 -m http.server` inside `site/`).
- I use Firefox on Fedora Linux; give browser instructions (DevTools, shortcuts,
  settings) for Firefox.

## Deployment (for reference)

- Hostinger VPS, Ubuntu, Nginx serving `site/` as the web root, SSL via Certbot.
- Gzip/Brotli on; long cache headers for `css/`, `js/`, `assets/`; short for HTML.
- Deploy by syncing `site/` to the server (`rsync`), later via GitHub Actions.
