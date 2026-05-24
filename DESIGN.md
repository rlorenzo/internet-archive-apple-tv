---
name: Internet Archive for tvOS
description: A tvOS front door to the Internet Archive's media collections, designed for living-room consumption.
colors:
  library-charcoal: "#222222"
  text-primary: "#FFFFFF"
  text-secondary: "#FFFFFF99"
  text-tertiary: "#FFFFFF4D"
  surface-overlay-dim: "#00000099"
  placeholder-fill: "#80808080"
  focus-glow: "#FFFFFF"
  focus-shadow: "#000000"
  ia-favorite-red: "#FF453A"
  ia-action-blue: "#0A84FF"
typography:
  display:
    fontFamily: "SF Pro Display, -apple-system, system-ui, sans-serif"
    fontSize: "76pt"
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: "normal"
  headline:
    fontFamily: "SF Pro Display, -apple-system, system-ui, sans-serif"
    fontSize: "57pt"
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: "normal"
  title:
    fontFamily: "SF Pro Display, -apple-system, system-ui, sans-serif"
    fontSize: "38pt"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "31pt"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "25pt"
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: "normal"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "20px"
  xl: "40px"
  xxl: "80px"
components:
  card:
    backgroundColor: "{colors.library-charcoal}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
  card-focused:
    backgroundColor: "{colors.library-charcoal}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
  button-primary:
    backgroundColor: "{colors.library-charcoal}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "16px 32px"
  section-header:
    textColor: "{colors.text-secondary}"
    typography: "{typography.headline}"
  progress-track:
    backgroundColor: "{colors.surface-overlay-dim}"
    height: "8px"
  progress-fill:
    backgroundColor: "{colors.focus-glow}"
    height: "8px"
---

# Design System: Internet Archive for tvOS

## 1. Overview

**Creative North Star: "The Reading Room After Dark"**

A public library kept open at night. The room is dimly lit, the shelves are quiet, and the catalog is open to anyone who walks in. Whatever sits in front of the user, a 1928 silent short, a Grateful Dead bootleg, a public-domain documentary, is presented with the same gentle illumination. Nothing is roped off, nothing is hustled, and nothing is asking for attention until the user reaches toward it.

This system is platform-honest. It runs on tvOS, navigated by a Siri Remote at a couch-distance of 8 to 12 feet, and it leans into that context rather than fighting it. The chrome (TabView, NavigationStack, system fonts, native focus engine) is borrowed from Apple. The personality is concentrated in three places: the editorial choices about what gets surfaced, the focus treatment that lights up content as the remote moves across it, and a single anchor color (Library Charcoal) that holds the canvas. Nowhere else.

The aesthetic this system rejects: the SaaS dashboard, the Netflix carousel, the Tubi grid, and the dense link-heavy archive.org desktop UI. None of them belong in a living room. None of them treat their content with the dignity the catalog deserves.

**Key Characteristics:**

- Library Charcoal canvas anchored at sRGB(0.133, 0.133, 0.133), untinted.
- Platform-native type from the Apple Dynamic Type scale; one family across the surface.
- Focus is the entire elevation system. Surfaces are flat at rest; the remote's path is the choreography.
- Rounded vocabulary in four steps (4 / 8 / 12 / 16) with `md (12px)` as the default card radius.
- Spacing rhythm anchored on 40pt as the dominant outer step, with 80pt for the page horizontal gutter at 10-foot viewing distance.
- 16:9 for video, 1:1 for music. The aspect ratio carries the media type before any label does.

## 2. Colors: The Library Charcoal Palette

A single anchor color sitting on a near-neutral charcoal canvas. Everything else is system-adaptive, semantic, or restricted to two status accents. There is no decorative color in this system.

### Primary

- **Library Charcoal** (`#222222`, sRGB 0.133 / 0.133 / 0.133): the launch screen anchor and the conceptual canvas of the entire app. Untinted by intention. On a TV at viewing distance, a tint toward warm or cool would read as miscalibrated rather than designed.

### Neutral

- **Text Primary** (`#FFFFFF` via `.primary`): card titles, focused element labels, progress fill. Platform-adaptive at rest; resolves to pure white in dark mode by Apple's token system.
- **Text Secondary** (`#FFFFFF99` via `.secondary`): section headers, subtitles, time-remaining strings, See-All affordances. The most common text color in the system, by a wide margin.
- **Text Tertiary** (`#FFFFFF4D` via `.tertiary`): the quietest text layer, used for de-emphasized chrome.
- **Surface Overlay Dim** (`#00000099`): the dark scrim behind the progress bar on a thumbnail. The only on-image overlay tint that exists.
- **Placeholder Fill** (`#80808080`): the gray-on-charcoal block that fills a thumbnail container before the image loads or when the image fails. Always paired with a centered glyph from SF Symbols.

### Status

- **IA Favorite Red** (`#FF453A`, the platform `.red`): the filled heart on favorited items. Never used as a primary action color. Never used for "warning" or "destructive".
- **IA Action Blue** (`#0A84FF`, the platform `.blue`): linking affordances and the in-progress accent on a select few status indicators. Used in single-digit percent of the surface.

### Named Rules

**The One Canvas Rule.** Every surface in this app sits on Library Charcoal or a tvOS-system material derived from it. There is no second background color. Headers, modals, sheets, players: all of them resolve to the same canvas. The user should never feel they have left the same room.

**The Status-Only Color Rule.** Color (red, blue, the rare green or orange in error states) is reserved for state and status. Never for hierarchy, never for decoration, never as a "brand accent" on a button. If a color appears, it carries information.

**The Untinted Charcoal Rule.** Do not tint the canvas warm or cool. On a TV at 10 feet, subtle hue shifts read as a calibration error, not a creative choice. If a future ramp is needed (hover surface, elevated surface), step lightness only, hold hue at neutral.

## 3. Typography

**Display Font:** SF Pro Display (system).
**Body Font:** SF Pro Text (system).
**Label/Mono Font:** none distinct; system handles all roles.

**Character:** This is Apple's tvOS type, used the way Apple intends. The pairing has no signature; that's the point. Hierarchy comes from Dynamic Type semantic steps, never from custom faces. The voice in PRODUCT.md ("plainspoken, accessible, anti-corporate") is carried by typography that disappears into the surface.

### Hierarchy

All sizes are tvOS Dynamic Type defaults; Apple's scale already steps at 1.25 to 1.5 ratios between adjacent roles, satisfying the shared design law. Sizes shown are nominal; respect Dynamic Type at runtime.

- **Display** (regular, ~76pt, line-height 1.05): reserved for the largest stat or hero text. Used sparingly on Account and detail surfaces, never on browse screens.
- **Headline** (semibold, ~57pt, line-height 1.1): the SectionHeader weight (`.title2 + .semibold`). The most prominent recurring type element in the app, used to label every row of content.
- **Title** (semibold, ~38pt, line-height 1.15): subheaders, item titles on detail surfaces, navigation labels.
- **Body** (medium, ~31pt, line-height 1.3): the card title weight (`.callout + .medium`). Carries every media item label across grids and rows. Cap line length at 2 lines via `lineLimit(2)`.
- **Label** (regular, ~25pt, line-height 1.3): subtitles, time-remaining strings, captions overlaid on thumbnails.

### Named Rules

**The One Family Rule.** SF Pro is the only typeface in the app. No custom face, no display pairing, no monospace except in technical surfaces (debug logs, identifiers in Account). Editorial weight comes from `fontWeight`, not from a second family.

**The Semantic-Step Rule.** Always reach for `.title`, `.title2`, `.title3`, `.callout`, `.body`, `.caption` before reaching for `.system(size:)`. The semantic styles respect Dynamic Type; explicit sizes do not. `.system(size:)` is permitted only for SF Symbol glyph sizing (40, 50, 60, 80) and for large numeric displays.

## 4. Elevation

This system uses no shadows at rest. Surfaces are flat against Library Charcoal. The entire elevation vocabulary is concentrated in the focus state: when the remote moves to a card, the card itself becomes the elevated surface. Nothing else lifts. Tonal layering (slightly brighter charcoal for elevated panels) is permitted as a secondary cue but is not required.

### Focus Elevation Vocabulary

The focus state is composed of five simultaneous changes, all on the focused element only, applied via `TVCardButtonStyle`:

- **Scale** to 1.08.
- **Brightness** +0.1 on the focused content.
- **White outer glow:** `shadow(color: .white.opacity(0.6), radius: 25)`.
- **Drop shadow:** `shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 15)`.
- **Z-index** elevated to 1 so the focused card overlaps siblings.

Easing: `.easeInOut(duration: 0.2)` on focus; `.easeInOut(duration: 0.1)` on press. The press state additionally scales to 0.95 so the remote click reads as a tactile depress.

### Named Rules

**The Focus-Is-Depth Rule.** Focus is the only state that lifts. Cards do not have ambient shadows. Buttons do not have ambient shadows. Modals do not have ambient shadows. If something needs to feel "elevated", it needs to be focused first.

**The Single-Lifted-Element Rule.** At any moment, exactly one element in the focus tree is elevated. The white glow plus drop shadow combination is unique to that element. Multiplying lifted elements (focused card AND focused background AND focused sidebar) reads as broken focus state.

## 5. Components

Each component is described in SwiftUI terms because this is a native tvOS app. Snippets and signatures live in `.impeccable/design.json`.

### Cards

The core unit of the browse experience. Used in both `MediaItemCard` (default) and `ContinueWatchingCard` (with progress overlay).

- **Shape:** Rounded corners at 12pt (`rounded.md`). Progress overlays and small chips use 4pt (`rounded.xs`) inside a card. Larger detail surfaces use 16pt (`rounded.lg`).
- **Background:** Library Charcoal at rest; placeholder fill (`#80808080`) under loading or failed thumbnails with a centered SF Symbol glyph (`film` for video, `music.note` for music) at 40pt.
- **Internal layout:** `VStack(alignment: .leading, spacing: 12)` separating thumbnail from text block; `VStack(alignment: .leading, spacing: 4)` between title and subtitle.
- **Aspect ratio carries media type.** Video cards are 16:9; music cards are 1:1. The aspect ratio is the first signal of what a thing is, before any label loads.
- **Sizing per media type.** Video cards in grid: adaptive 300 to 400pt wide. Music cards: 200 to 280pt wide. Continue-watching row uses fixed widths: 350pt for video, 200pt for audio.
- **Focus:** see Elevation. The card itself receives the entire focus treatment; the inner content does not lift independently.

### Buttons

Two distinct button surfaces in this app: action buttons (Play, Resume, Sign In) and ghost affordances (See All, navigation arrows).

- **Primary action button:** tvOS native button shape on Library Charcoal, padding `16px 32px`, body typography, rounded 12pt. The `TVCardButtonStyle` is used wherever the button is itself a card. Standard SwiftUI `Button` is used elsewhere; the tvOS focus engine handles its appearance.
- **Ghost button (`.plain`):** See-All affordances on section headers. Inline `HStack(spacing: 4)` of label + `chevron.right` glyph, both in `text-secondary`. No background, no border. Identified by position and label, not chrome.

### Section Header

A signature component in this app. Sets the rhythm of every browse screen.

- **Type:** Headline role (`.title2 + .semibold`), color `text-secondary`. Intentionally one weight quieter than full primary so the headers recede when the user is scanning rows.
- **Layout:** `HStack` with `Spacer()`. When `showSeeAll` is true, a ghost button sits at the trailing edge.
- **Vertical rhythm:** Section headers are followed by a `LazyHStack(spacing: 40)` or `LazyVGrid(spacing: 40)` of content. The 40pt spacing between cards is the dominant rhythm of the app.

### Progress Bar (Continue Watching)

The single instance of an on-image overlay in the system. Notable because it's the only place where pure white sits directly on imagery.

- **Track:** `Rectangle().fill(Color.black.opacity(0.6))` at 8pt tall, full width of the thumbnail.
- **Fill:** `Rectangle().fill(Color.white)` at 8pt tall, width = `geometry.size.width * progress`.
- **Position:** anchored to bottom of thumbnail, clipped to the card's 12pt rounded corners.

### Tabs (root navigation)

Five tabs at the root, all native tvOS `TabView` style.

- **Icons:** SF Symbols at default tab sizing (`film`, `music.note`, `magnifyingglass`, `heart.fill`, `person.crop.circle`).
- **Labels:** single noun per tab, no truncation; nothing is more than one word.
- **State:** the tvOS focus engine owns selected/unselected appearance. Do not override.
- **Conditional tabs:** Favorites and Account are gated on `AppConfiguration.shared.isConfigured` and disappear cleanly when API credentials are absent.

### Loading and Empty States

- **Loading:** `SkeletonLoadingView` renders Library Charcoal blocks at the same dimensions as the cards that will replace them. No spinners over content. No animated shimmer at present, by design (Principle 5: motion serves clarity, not decoration).
- **Empty:** centered glyph (SF Symbol) at 80pt in `text-tertiary`, followed by a one-line `Title` and a one-line `Body` explanation. No call-to-action button unless the empty state is recoverable by user action (e.g., a search returning no results invites a query revision).

## 6. Do's and Don'ts

### Do:

- **Do** anchor every surface on Library Charcoal (`#222222`, sRGB 0.133/0.133/0.133). One canvas, app-wide.
- **Do** use the Dynamic Type semantic styles (`.title`, `.title2`, `.title3`, `.callout`, `.body`, `.caption`) before reaching for `.system(size:)`. Explicit sizes are for SF Symbol glyphs only.
- **Do** treat the focus state as the entire elevation system: scale 1.08, brightness +0.1, white outer glow at radius 25 / opacity 0.6, drop shadow at radius 20 / y: 15 / opacity 0.5.
- **Do** use `TVCardButtonStyle` (or its `.tvCardStyle()` modifier) on every card. Do not roll a new focus treatment per surface.
- **Do** keep 40pt as the dominant spacing between cards in rows and grids, and 80pt as the outer horizontal page gutter.
- **Do** carry media type through aspect ratio: 16:9 for video, 1:1 for music. A user should know what a thing is before reading its label.
- **Do** honor `UIAccessibility.isReduceMotionEnabled`: when reduced motion is on, drop the focus animation duration to near-zero. The scale, brightness, and shadow can stay as instantaneous state changes.
- **Do** keep red and blue reserved for status and link semantics. If color appears, it carries information.

### Don't:

- **Don't** introduce a second background color. No light surfaces, no tinted modals, no warm-cream containers. PRODUCT.md names "SaaS-cream backgrounds" as an explicit anti-reference; respect it.
- **Don't** build hero-metric blocks (big number + small label + supporting stats + accent). This is the SaaS template PRODUCT.md most directly rejects.
- **Don't** ship identical card grids that read as icon + heading + paragraph templates. Cards must carry imagery (16:9 or 1:1), not be containers for icons.
- **Don't** add Netflix-style auto-playing hero carousels. Browsing is lean-back; no element should start moving without the user's consent.
- **Don't** add ambient shadows to cards, buttons, or modals. Elevation is reserved for the focused element. Multiple lifted surfaces read as broken focus.
- **Don't** introduce a second typeface. SF Pro carries every role; emphasis comes from `fontWeight`, not from a display pairing.
- **Don't** use a colored side-stripe border (`border-leading > 1pt`) as a card accent. Banned across the impeccable system. If a card needs categorical distinction, use a small chip in the top-leading corner instead.
- **Don't** use glassmorphism (blurred backgrounds, frosted cards) as a default surface. The tvOS-provided system materials are the exception; do not introduce additional blurs.
- **Don't** add decorative motion. Every animation must answer a question (where did this come from? what changed? what's loading?). Parallax for parallax's sake is banned.
- **Don't** invent affordances for standard tasks. No custom scrollbars, no non-standard modals, no reinvented focus rings. The tvOS focus engine is the affordance.
- **Don't** use em dashes in UX copy. Periods, commas, colons, parentheses; never an em dash or `--`.
