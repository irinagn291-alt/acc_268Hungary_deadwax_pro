# Deadwax

Deadwax is a played vinyl crate on this device. Collectors search or scan a pressing onto a sleeve wall, tap Drop to record a play, then grade Grooved copies so Taste can fold what they actually heard.

It is for people who want a crate of played records, not a Discogs wantlist, a streaming library, or a price-per-play ledger.

## Architecture

A `Pressing` is stored as a Groove ADT of Mint or Grooved. The wall is a fold over that collection. One `WallStore` owns the fold. Views call `dropNeedle`, `gradeSleeve`, and `peelLastMark` and never mutate `Groove`.

This pattern fits the product because an unplayed sleeve must stay Mint and off Taste. Plays are the `GrooveMark` count, never a stored integer. Drop is the fold. Retract peels the last mark and returns the sleeve to Mint at zero plays.

Presentation sits in wall-segment chrome: Discover, Crate, Heard, and Taste are segments of the same wall. Search and Scan are covers. Drop and grade fuse on the sleeve.

## Drop-then-groove

Search or Scan writes Mint and never a GrooveMark. Drop writes one GrooveMark, increments plays, and flips Mint to Grooved. Grade 1 to 5 and a local note fold only on Grooved. Taste counts GrooveMarks and Grooved grades by genre and label. An unplayed sleeve never enters taste.

That is why someone would pick this app: home records a play, it does not save a title.

## Design

Berry soft bloom on SF Pro. Mixed-size play tiles, one cutout, a fat Drop control. Art direction is 3D glass render glassmorphism: frosted vinyl sleeves and a grooved disc, not a book-cover grid.

Section 13 assets are generated later. Empty imagesets are named from that list. Prompts:

**dwx_AppIcon** — A single 3D glass vinyl sleeve facing camera, frosted glassmorphism, grooved disc hint at the mouth, filling the canvas edge to edge, no text, no letters, no rounded corners, no drop shadow outside the canvas

**dwx_Splash** — A tall quiet 3D glass sleeve wall receding, frosted glassmorphism, calm uncluttered centre band so a wordmark can sit, no letters

**dwx_Onboarding1** — A collector standing before a glass sleeve wall, 3D glass render cutout of the person and one sleeve, isolated, no text

**dwx_Onboarding2** — A glass tonearm dropping the needle onto a grooved disc, mid-gesture, 3D glass cutout, isolated, no text

**dwx_Onboarding3** — A small stack of grooved glass sleeves with grade notches on the spines, 3D glass cutout, isolated, no text

**dwx_EmptyHome** — An empty glass crate with one open slot waiting for a sleeve, 3D glass cutout, isolated, no text

**dwx_EmptyList** — An empty glass play-order rail with no discs seated, 3D glass cutout, isolated, no text

**dwx_CardBackdrop** — Abstract low-contrast 3D frosted glass sleeve spines and bloom, quiet enough for text on top, filling the canvas, no letters

**dwx_ControlFace** — The face of a single glass tonearm cue as a physical control, 3D glass cutout, isolated, no text

**dwx_TwistHero** — Mint glass sleeve beside a Grooved sleeve wearing one GrooveMark bead, 3D glass cutout, isolated, no text

**dwx_SuccessMark** — A small glass needle seated in a groove after a Drop, 3D glass cutout, confirmation not fireworks, no letters

**dwx_HeaderDecor** — A wide low 3D glass band of sleeve spines, frosted glassmorphism, low contrast, no readable text

Base prompt reused across assets: 3D glass render, glassmorphism, frosted translucent vinyl sleeves and a grooved disc, studio soft bloom, physical glass objects not UI chrome, no letters, no logos, no readable catalog text. New sleeve-wall composition, not a book-cover grid.

## Not a repeat

This is not a book crate with MusicBrainz swapped in. Home is a sleeve wall whose first Drop records a play. Search and Scan only write Mint. Unplayed copies never enter taste. No stalls, no assignedTo, no purchase price, no A-F library grades. Domain stays vinyl.

## Build

```bash
cd Deadwax
xcodegen generate
xcodebuild -scheme Deadwax -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build-for-testing
```

Deep links: `deadwax://discover`, `deadwax://pressing/{id}`, `deadwax://heard`, `deadwax://taste`.

Review launches: `-ReviewScreen today|log|goals` after onboarding. Simulator seed is `dwx.demo.v1`.
