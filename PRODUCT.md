# Product

## Register

product

## Users

Two audiences served equally:

- **Archive enthusiasts** — researchers, archivists, collectors, and fans who already know the Internet Archive catalog. They arrive with intent: a specific film, a Grateful Dead Live Music Archive recording, a year, a creator. They want fast retrieval and trust the platform's depth.
- **Casual cord-cutters** — living-room viewers looking for free, legal, public-domain movies and music. Many won't know what "Internet Archive" is when they install the app. They lean back with the Siri Remote, scroll curated rows, and need to be invited in.

Context: 10-foot UI, focus-driven Siri Remote navigation, typically a shared TV in a living room. Sessions are evening / weekend leisure. Most sessions begin in **browse & discover** mode — even the enthusiast often arrives without a specific title in mind.

## Product Purpose

A native tvOS front door to the Internet Archive's media collections — movies, music, concerts, audiobooks, public-domain film — designed for living-room consumption.

It exists because archive.org's web UI is dense, link-heavy, and unsuited to a TV remote, while the underlying catalog is one of the most valuable cultural resources on the internet. The app's job is to make that catalog feel browsable, watchable, and welcoming from the couch.

Success looks like: a casual viewer who'd never have visited archive.org finds something worth watching within 90 seconds of opening the app, and an enthusiast can resume a 4-hour concert or jump to a specific 1940s short film with two clicks.

## Brand Personality

**Open, civic, public-good.** This is the free public library of the internet, not a streaming service. Plainspoken, accessible, anti-corporate, mission-forward.

Voice and tone:

- Plain language. No "exclusive content," no "premium," no "for you." Items are surfaced because they exist and are worth knowing about, not because an algorithm scored them.
- Generous, not gated. The app never hides content behind sign-in for browsing; account features (favorites, follows) are additive, not prerequisite.
- Respectful of source material. A 1928 silent short and a 2019 concert recording get the same dignity in the layout — no genre hierarchies that read as taste-making.
- Quietly distinctive. The interface looks at home next to first-party tvOS apps, but with a recognizable Internet Archive identity. Native enough to disappear when the user is watching; distinct enough to remember when the user is browsing.

## Anti-references

Hardest no: **generic SaaS / dashboard aesthetic.** This is a media experience, not a productivity tool.

- No card-grid-with-icon templates. No hero-metric blocks. No identical card grids that read as "admin panel."
- No SaaS-cream backgrounds, no navy-and-electric-blue, no dashboard-blue accents.
- No "stats about your viewing" — this app is not trying to gamify or quantify the user's relationship with the catalog.

Adjacent things to avoid by reflex (worth naming so they don't sneak in):

- Netflix/Disney+ shapes: aggressive auto-playing hero carousels, monetization-shaped UI, algorithm-driven "because you watched" rows.
- Generic free-streaming look (Tubi/Pluto): ad-shaped layouts, busy thumbnails with text overlays, neon accents.
- archive.org's own web UI: dense, link-heavy, "old web" — works on desktop, fails on a 10-foot screen.

## Design Principles

1. **Public library, not a streaming service.** Every choice is filtered through "would this feel right at a library?" — curation over algorithm, breadth over hype, trust over urgency. No FOMO, no autoplay traps.

2. **Equal welcome to the seeker and the scroller.** The same screen must serve the user who knows exactly what they want (fast search, direct paths, clear identifiers) and the user who's just exploring (scannable rows, generous imagery, clear context). Neither audience is a second-class citizen.

3. **Lean back first, lean in on demand.** Defaults bias toward calm browsing on the couch — large focus targets, slow rhythm, minimal cognitive load. Detail and depth surface when the user asks for them (item detail, search, account), never before.

4. **Native enough to disappear, distinct enough to remember.** Honor tvOS conventions (focus engine, TabView, system fonts, platform motion) so the app feels at home. Differentiate through editorial decisions — what gets surfaced, how rows are programmed, how a 1925 film is framed — not through chrome that fights the platform.

5. **Motion serves clarity, never decoration.** Every animation answers a question ("where did this come from?" "what changed?" "what's loading?"). No decorative parallax, no flourishes that don't carry information. This principle is also an accessibility commitment.

## Accessibility & Inclusion

Target: WCAG AA, with reduced motion as a first-class concern.

- VoiceOver labels and hints on all interactive elements (the existing code already does this — keep it up across new work).
- Honor `UIAccessibility.isReduceMotionEnabled`. Default motion is already restrained per Principle 5; under reduced motion, transitions should drop to instant or near-instant.
- Focus state must be unmistakable. The tvOS focus engine handles most of this, but custom focus styling must not weaken the platform-default contrast of focused vs. unfocused elements.
- Contrast meets AA at minimum for all text-on-background pairs, including text overlaid on imagery (progress bars, captions on thumbnails).
- Dynamic type respected wherever the platform supports it on tvOS.
- Living-room context implies users may be 8+ feet from the screen — favor larger type and clearer focus over information density when there's a tradeoff.
