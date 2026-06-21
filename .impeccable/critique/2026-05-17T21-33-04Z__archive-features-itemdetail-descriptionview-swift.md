---
target: DescriptionView full-text flow
total_score: 21
p0_count: 0
p1_count: 2
p2_count: 2
p3_count: 1
timestamp: 2026-05-17T21-33-04Z
slug: archive-features-itemdetail-descriptionview-swift
---
# Critique — Full-Text Description Flow

Target: Internet Archive/Features/ItemDetail/DescriptionView.swift (consumed by ItemDetailView.swift:207 and CollectionBrowserView.swift:145)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Read More appears only when truncated; no indication of full description length before opening. |
| 2 | Match System / Real World | 3 | Pattern is familiar (Apple TV+ uses fullscreen readers). |
| 3 | User Control and Freedom | 2 | Modal traps user; no middle ground between 5 lines and full essay. |
| 4 | Consistency and Standards | 3 | Standard fullScreenCover + onExitCommand; minor: other see-more affordances expand inline. |
| 5 | Error Prevention | 3 | TruncationDetectingText measures actual height; hides Read More when text fits. |
| 6 | Recognition Rather Than Recall | 2 | Reader loses item title, creator, year, Play button. |
| 7 | Flexibility and Efficiency | 2 | One path, no shortcuts, no preview-a-bit-more option. |
| 8 | Aesthetic and Minimalist Design | 3 | Clean reader; 250pt horizontal padding may be too narrow at 10 feet. |
| 9 | Error Recovery | n/a | No errors. |
| 10 | Help and Documentation | n/a | Self-explanatory. |
| Total | | 21/32 | Acceptable — modal-as-first-thought dominant. |

## Anti-Patterns Verdict

One soft hit: shared design law "Modal as first thought." Mitigated by tvOS convention (Apple TV+ does fullscreen readers). Real problem: same modal for 50-word and 1500-word descriptions. Not AI-slop, but over-committed.

## Priority Issues

P1 — One-size-fits-all expansion. Same fullscreen modal opens for 50-word and 1500-word descriptions. For the common 50-300 word case, inline expansion would win on every UX axis. Fix: default inline expansion; reserve fullscreen for ≥1500 characters with a secondary "Open in reader" affordance.

P1 — Reader loses item context. Title, creator, year, Play button disappear when modal opens. Users are *deciding* whether to play; severing description from metadata violates Recognition Rather Than Recall. Fix: sheet-style overlay preserving the title row, OR add an item header inside the reader.

P2 — No middle ground between collapsed and full. Binary 5-lines-or-everything. Fix: resolved by P1's inline default.

P2 — Reader column narrow at 10 feet. 250pt horizontal padding on tvOS leaves a 1420pt column that reads as timid. Drop to ~180pt.

P3 — "Read More" copy and icon mismatch. arrow.up.right.square implies "open external"; for inline expansion use chevron.down. Title case "Read More" heavier than surrounding plainspoken voice; "Show more" matches IA tone.

## Persona Red Flags

Casey (Casual Cord-Cutter): trying to decide "should I watch this?" Modal severs description from title/Play button; mild annoyance every detail view. Common 80-120 word case gets heavyweight modal treatment.

Avery (Archive Enthusiast): reading 1400-word Grateful Dead concert essay. Fullscreen reader serves them well. Minor: focus returns to top of metadata column, not Resume button.

Sam (Low-Vision Viewer): Dynamic Type now respected post-typeset. In fullscreen reader at Larger Text settings, 250pt padding makes column ribbon-thin. Reduced-motion compliance for the modal transition itself is partial (depends on SwiftUI framework behavior).

## What's Working

- TruncationDetectingText geometry measurement (smart, correct, scales with Dynamic Type).
- tvOS Back gesture (.onExitCommand) handled correctly.
- VoiceOver coverage solid.
- HTMLToAttributedString stripping at source.
