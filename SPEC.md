# Deadwax — Build Specification

> Portfolio app 76, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Tap a sleeve to record a play.

| Field | Value |
| --- | --- |
| Product name | Deadwax |
| Bundle identifier | `com.deadwax.wall` |
| Domain | https://deadwax-wall.pro |
| Contact URL | https://deadwax-wall.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `dwx_` |
| User-Agent | `Deadwax/1.0 (iOS; +https://deadwax-wall.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Deadwax -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A vinyl collector searches or scans a pressing onto the sleeve wall and taps it to record a play so taste grades heard copies.

### 2.1 User flow

1. Tap a sleeve on the wall to record a play
2. Search the catalog or scan a catalog code to sleeve a new Mint pressing
3. Grade a Grooved sleeve in place from 1 to 5 and add a local note
4. Switch to Heard to walk Grooved pressings in play order
5. Switch to Taste to read folded grades by genre and label

### 2.2 Essential behaviour

- MusicBrainz release search and catalog-code lookup with Cover Art Archive fronts
- Sleeve wall as home, not a title list
- Mint versus Grooved fold with GrooveMark plays
- Grade 1-5 and local notes on Grooved sleeves
- Taste stats fold only Grooved grades
- Live AVCaptureMetadataOutput scan; permission CTA is Continue or Next
- Cached pressings when search fails; Simulator chips plus a manual code field
- Deep links and App Intents to Discover, a Pressing, Heard and Taste
- No calories, meal slots, or food catalog

---

## 3. Uniqueness assignment for Deadwax

| Axis | Assigned value |
| --- | --- |
| Architecture | **Groove ADT fold (Mint | Grooved); the wall is a fold over Pressings; Drop writes a GrooveMark and flips Mint to Grooved; grade folds only Grooved; plays is the GrooveMark count** |
| UI approach | **SwiftUI pure · take catalogcrate** |
| Naming convention | **Phonograph / groove lexicon** |
| File organization | **By pressing role (Wall, Pressing, Groove, GrooveMark, Grade)** |
| Dependency strategy | **None** |
| Design direction | **Berry soft bloom** |
| Typography | **SF Pro** |
| Navigation pattern | **Wall-segment chrome (the sleeve wall never leaves; Discover, Crate, Heard and Taste are segments of the same wall; drop and grade fuse on the sleeve)** |
| AI art style | **3D glass render glassmorphism · take catalogcrate** |
| Functional twist | **Drop-then-groove (a search or scan writes Mint; Drop writes a GrooveMark and flips Mint to Grooved; grade and taste fold only Grooved; an unplayed sleeve never enters taste)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — catalog_crate

**Core** — A vinyl collector searches or scans a pressing onto the sleeve wall and taps it to record a play so taste grades heard copies.

**Audience** — Vinyl collectors who want a played crate on this device, not a Discogs wantlist, a streaming library, or a price-per-play ledger.

**User flow**

1. Tap a sleeve on the wall to record a play
2. Search the catalog or scan a catalog code to sleeve a new Mint pressing
3. Grade a Grooved sleeve in place from 1 to 5 and add a local note
4. Switch to Heard to walk Grooved pressings in play order
5. Switch to Taste to read folded grades by genre and label

**Essential features**

- MusicBrainz release search and catalog-code lookup with Cover Art Archive fronts
- Sleeve wall as home, not a title list
- Mint versus Grooved fold with GrooveMark plays
- Grade 1-5 and local notes on Grooved sleeves
- Taste stats fold only Grooved grades
- Live AVCaptureMetadataOutput scan; permission CTA is Continue or Next
- Cached pressings when search fails; Simulator chips plus a manual code field
- Deep links and App Intents to Discover, a Pressing, Heard and Taste
- No calories, meal slots, or food catalog

**Twist** — Drop-then-groove. Home is the sleeve wall. Search or scan writes a Pressing as Mint. Tapping a sleeve writes a GrooveMark, increments plays, and flips Mint to Grooved. Grade from 1 to 5 fuses on a Grooved sleeve. Taste folds only Grooved grades. Retract peels the last GrooveMark and returns that Pressing to Mint when plays hits 0. Unplayed Mint sleeves stay on the wall and do not enter taste. Home verb: drop-the-needle, not save-a-title. Taste counts GrooveMarks and Grooved grades, not a wantlist.

**Why this is not a repeat** — This is not PagePocket with a new ISBN source: home is a vinyl sleeve wall whose first tap records a play, not add-to-crate. Search and scan only write Mint; Drop writes a GrooveMark and flips Mint to Grooved, so unplayed copies never enter taste. That is not Stallage hop-the-tag: no stalls, no assignedTo, and the catalog is MusicBrainz releases rather than a local asset id. It is not watchlist mark-watched: plays increment on every Drop and the first Drop is the fold. It is not cost-per-use: no purchase price and no A-F library grades. Domain stays vinyl. No food, slots, or Open Food Facts.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Discover is a crate/wall, not a generic search app.
- Invariant: One external catalog. Stay in one domain. Rate + local notes. Scan only if the domain has a code.
- Never: Add one rare verb: sleeve wall, quiz-from-crate, surprise-from-owned-stock, cook mode, or expiry rail — not all of them.
- Taste DNA is section 7.6. Do not invent a second look.
- Scan: AVFoundation + Vision; symbologies include `.qr`; digit runs 8–14 from QR/URL; UPC-A pad; Simulator chips + manual; stop session. Pre-permission CTA is Continue or Next (Guideline 5.1.1 — never Allow/Enable camera).
- Mini-ref `PagePocket`: steal Catalog search, ISBN scan, crate/rate/notes, cover wall, empty search. Never Alamofire wrapper, AppsFlyer, OneSignal, ContactUsWebView. Not book_quotes. New types and layout — do not reskin.

### 3.1 Architecture contract

A Pressing is stored as a Groove ADT of Mint or Grooved, and the wall is a fold over that collection. Search or scan writes a Pressing as Mint and never writes a GrooveMark. Drop writes one GrooveMark, flips Mint to Grooved, and plays is the GrooveMark count, never a stored integer. Grade from 1 to 5 and a local note fold only on Grooved. Retract peels the last GrooveMark and returns that Pressing to Mint when plays hits 0. One WallStore owns the fold. Views call dropNeedle, gradeSleeve, and peelLastMark and never mutate Groove. Day keys on GrooveMarks are Int in YYYYMMDD form from Calendar.current.startOfDay.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

100 percent SwiftUI with the catalogcrate take-token: new sleeve-wall composition, new types, new motion. Steal PagePocket catalog search, catalog-code scan, crate plus rate plus notes, cover wall density, and empty search. Do not copy Book, LibraryView, SearchView, WallView, OpenLibraryService, Alamofire, AppsFlyer, OneSignal, or ContactUsWebView. Home is the mechanic: mixed-size play tiles of sleeves filling remaining height and the iPad width, one cutout, a fat Drop CTA. Dead placeholder cells are forbidden. The only UIViewRepresentable is the AVCaptureMetadataOutput preview. Discover, Crate, Seen, and Profile are stock segment chrome around that wall. Native Button, Toggle, TextField. Drop, Scan, Grade, and Retract use a ButtonStyle with default, pressed, disabled, and loading. Destructive Retract uses the destructive variant. Confine any Path or Shape flourish to the Discover wall. Axis values never appear as titles. Empty and onboarding are full pages with frame maxHeight infinity and Continue or Next at the bottom full width. Background fills the safe area. Lists use contentMargins.bottom. One spring on a successful Drop, response about 0.4 and damping about 0.8. Everything else is ease-out. Reduce Motion fades with no spring. One haptic on Drop, Grade, or Retract. None on segment change.

### 3.3 Naming contract

Convention: Phonograph / groove lexicon.

Examples to follow: `Pressing`, `GrooveMark`, `dropNeedle(_:)`, `peelLastMark()`

### 3.4 Dependency contract

None. project.yml has no packages key. No SPM, no CocoaPods, no bundled font. SF Pro is the system face. Foundation, SwiftUI, URLSession, and AVFoundation only. AVFoundation is for the live sleeve-code capture session. URLSession talks to MusicBrainz and Cover Art Archive. Honor the cgi search pl assignment as paginated JSON search: query, json, page, page_size mapped onto GET https://musicbrainz.org/ws/2/release with fmt=json, query, limit, and offset. Catalog-code lookup uses query=catno or query=barcode. Cover fronts are GET https://coverartarchive.org/release/{mbid}/front-250. Never call world.openfoodfacts.org or /cgi/search.pl. Never Open Food Facts, calories, meal slots, or a food catalog. Set User-Agent Deadwax/1.0 (iOS; +https://deadwax-wall.pro) on every request. Dedicated JSONDecoder with useDefaultKeys. DTO then domain Pressing. Cache every resolved pressing locally so empty or failed search still sleeves from the local shelf. Settings credits MusicBrainz and Cover Art Archive as tappable source links.

### 3.5 Navigation contract

Wall-segment chrome. The sleeve wall never leaves. Discover, Crate, Heard, and Taste are segments of the same wall, not a tab plus a title list. Heard is the Seen segment. Taste is the Profile segment. Drop and grade fuse on the sleeve in place. Search and Scan are covers over Discover, dismissed back to the wall. Settings is a cover from the wall chrome, with contact URL https://deadwax-wall.pro/contact-us, re-run onboarding, and confirmed resetAllData. Deep links and App Intents open Discover, a Pressing, Heard, and Taste. URL scheme deadwax: deadwax://discover, deadwax://pressing/{id}, deadwax://heard, deadwax://taste. After onboarding, read ProcessInfo.processInfo.arguments once: ReviewScreen today opens Discover, log opens Seen, goals opens Profile. Three different screens. Skip onboarding on Simulator after the dwx.demo.v1 seed so the hook can fire. No Today tab. No Goals tab. No Game tab.

### 3.6 Screen composition contract

Deep link routed screens · wall. Physical screens: Discover, Crate, Seen, Profile, Scan, Settings. Discover is the sleeve wall, mixed-size play tiles, Drop enabled after seed, search cover, ReviewScreen today. Crate is Mint versus Grooved on the same wall, not a title list. Seen is Heard: Grooved pressings in GrooveMark play order, ReviewScreen log. Profile is Taste: folded Grooved grades by genre and label, ReviewScreen goals. Scan is a full screen cover over Discover for live capture. Drop, grade 1 to 5, local note, and Retract fuse on the sleeve, not a pushed Detail. Onboarding is a one-shot cover of three pages with Continue at the bottom full width. Camera denied is a full page plus Open Settings. Empty Discover is a full page with generated cutout art, headline The wall is empty., one line Sleeve the first pressing., and a full-width bottom Search or Scan CTA. Empty Seen and empty Profile are full pages of their own. Seeded Discover shows several sleeves, Mix of Mint and Grooved, Drop enabled, Taste already has Grooved grades. No Today, Search, or Goals screens. ReviewScreen today log and goals must open three different screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By pressing role (Wall, Pressing, Groove, GrooveMark, Grade)**

```
Deadwax/
  Wall/
  WallChrome.swift
  WallStore.swift
  DiscoverWall.swift
  CrateFold.swift
  HeardFold.swift
  TasteFold.swift
  SleeveCapture.swift
Pressing/
  Pressing.swift
  SleeveTile.swift
  CatalogClient.swift
Groove/
  Groove.swift
GrooveMark/
  GrooveMark.swift
Grade/
  Grade.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Discover
A first-class screen for **Discover**. Must render empty, populated and error states.

### 5.3 Crate
A first-class screen for **Crate**. Must render empty, populated and error states.

### 5.4 Seen
A first-class screen for **Seen**. Must render empty, populated and error states.

### 5.5 Profile
A first-class screen for **Profile**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


**Scan (camera families). Mechanics from the white book scanner — add `.qr`.**

Capture:
- AVFoundation session + Vision `VNDetectBarcodesRequest` (or `AVCaptureMetadataOutput` with the same set).
- Symbologies must include `.qr` plus `.ean13`, `.ean8`, `.upce` (Code 128/39/93 if the domain uses them). Linear-only misses QR packs and QR-encoded EANs.
- Permission: notDetermined → `requestAccess` (system alert is the first ask). A pre-screen is allowed only if the proceed button is **Continue** or **Next**.
- Guideline 5.1.1 reject: any CTA that directs the grant — `Allow camera`, `Enable camera`, `Grant camera`, `Allow camera access`, or a bare `Allow` / `Enable` / `Grant` on the button that calls `requestAccess`.
- Denied/restricted → copy + Open Settings (`UIApplication.openSettingsURLString`). Never a second Allow/Enable button.
- No capture device (Simulator): sample-code chips + mandatory manual field. Fully usable without a camera.
- Start the session on appear; `stopRunning` on disappear and on background.
- Cooldown 1.5–2.0 s after a decode. Skip frames (every 3rd is enough). Ignore the same payload while a lookup is in flight.
- Continuous autofocus / autoexposure when supported. `alwaysDiscardsLateVideoFrames`. Preview `resizeAspectFill`.

Payload (camera, typed, pasted URL):
- Keep digit runs of length 8–14. A QR/URL may be text — extract those runs; do not require the whole payload to be digits.
- 12-digit UPC-A → prefix `0`.
- Try every candidate before miss. EAN-8/13, UPC-A/E, QR carrying any of those.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Title** — named per this app's convention.
- **CrateItem** — named per this app's convention.
- **Rating** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Berry soft bloom**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F8F6F9` | Screen background |
| `surface` | `#FEFEFE` | Cards, rows, sheets |
| `ink` | `#2F1C36` | Primary text and icons |
| `accent` | `#952EB8` | Primary action, key figure, progress fill |
| `muted` | `#7C6882` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system only, the play-tiles type move: chunky display, short words, no serif, no long lines. Display is Drop and the play count on a Grooved sleeve, usually one or two lines, never more than four. Body is about 17pt for artist and title. Caption is Mint, Grooved, and grade. At most six steps behind one accessor: display, title, headline, body, caption, micro. Weights carry hierarchy. None larger than 34pt, never below 12pt, no Font.custom, no fixedSize. Plays, grades, and day keys go through NumberFormatter with tabular figures. Dynamic Type. At AX5 a sleeve still shows artist, title, and Drop, numbers win, names truncate. @ScaledMetric for any custom size. Day edges use Calendar.current.startOfDay then fold to Int YYYYMMDD.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **22pt** for cards, sheets and primary surfaces; **14pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **soft card** — primary actions live inside a rounded card using the radius below, not a flat row with no fill.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take catalogcrate**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take catalogcrate** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

### 7.6 Taste DNA

Aesthetic: **warm** (Warm soft: friendly radii, comfortable pad, one playful moment.)

Reference system: **duolingo** — steal rhythm and restraint, not their colours or logos.

Mood: **playful**.

Home rhythm (`play-tiles`, comfortable): Mixed-size play tiles, one cutout, a fat CTA. Dead cells forbidden.

Playful and tactile. Chunky primary. Progress is a shape plus a word, never a lone colour bar.

Type move: Chunky display, short words, no long serif lines.

Motion (`spring`): One spring on the commit (response ~0.4, damping ~0.8). Everything else is ease-out. Reduce Motion: fade, no spring.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable WallDocument with schemaVersion from 1, Pressings, GrooveMarks, grades, notes, and cached catalog rows, encoded to JSON Data in UserDefaults under dwx.wall.v1. Groove is Mint or Grooved. Plays is derived as the GrooveMark count and is never stored. Day keys are Int YYYYMMDD from Calendar.current.startOfDay, never Date as a dictionary key. In-memory WallStore is the source of truth. UserDefaults is the projection. Views never touch UserDefaults. Debounce writes. Flush when scenePhase becomes inactive or background, and after Drop, Grade, Retract, sleeve, or reset. Decoding failure falls back to dwx.wall.v1.backup, then an empty wall, never a crash. resetAllData() is reachable from Settings. Simulator seed only once behind dwx.demo.v1 writes several Pressings with Cover Art fronts from the local shelf, a mix of Mint and Grooved, several GrooveMarks so Heard has play order, Grooved grades so Taste is not empty, leaves Drop enabled, and marks onboarding complete. Never seed on a device. Cached pressings catch empty or failed MusicBrainz search.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Deadwax/1.0 (iOS; +https://deadwax-wall.pro)` on every request. Never reuse another app's string.
Use the **cgi search pl** search endpoint for this app.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.entertainment`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Deadwax reads a catalog code from a vinyl sleeve so that pressing can be placed on the wall.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.entertainment
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Drop-then-groove (a search or scan writes Mint; Drop writes a GrooveMark and flips Mint to Grooved; grade and taste fold only Grooved; an unplayed sleeve never enters taste)

Drop then groove is the home verb: tapping a sleeve records a play, it does not save a title. Search or scan only writes Mint. Drop writes a GrooveMark and flips Mint to Grooved. Grade and Taste fold only Grooved grades, so an unplayed sleeve never enters taste. Retract peels the last GrooveMark and returns that Pressing to Mint when plays hits 0. Taste counts GrooveMarks and Grooved grades by genre and label, not a wantlist and not a price per play.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **3D glass render glassmorphism · take catalogcrate**


This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

Base prompt, reused and extended for every asset:

```
3D glass render, glassmorphism, frosted translucent vinyl sleeves and a grooved disc, studio soft bloom, physical glass objects not UI chrome, no letters, no logos, no readable catalog text. New sleeve-wall composition, not a book-cover grid.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `dwx_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `dwx_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `dwx_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `dwx_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `dwx_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `dwx_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `dwx_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `dwx_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `dwx_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `dwx_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `dwx_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Drop-then-groove (a search or scan writes Mint; Drop writes a GrooveMark and flips Mint to Grooved; grade and taste fold only Grooved; an unplayed sleeve never enters taste)' feature screen. |
| 11 | `dwx_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `dwx_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`dwx_AppIcon`** — 1024x1024

```
A single 3D glass vinyl sleeve facing camera, frosted glassmorphism, grooved disc hint at the mouth, filling the canvas edge to edge, no text, no letters, no rounded corners, no drop shadow outside the canvas
```

**`dwx_Splash`** — 1290x2796

```
A tall quiet 3D glass sleeve wall receding, frosted glassmorphism, calm uncluttered centre band so a wordmark can sit, no letters
```

**`dwx_Onboarding1`** — 1024x1536

```
A collector standing before a glass sleeve wall, 3D glass render cutout of the person and one sleeve, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_Onboarding2`** — 1024x1536

```
A glass tonearm dropping the needle onto a grooved disc, mid-gesture, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_Onboarding3`** — 1024x1536

```
A small stack of grooved glass sleeves with grade notches on the spines, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_EmptyHome`** — 1024x1024

```
An empty glass crate with one open slot waiting for a sleeve, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_EmptyList`** — 1024x1024

```
An empty glass play-order rail with no discs seated, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_CardBackdrop`** — 1200x800

```
Abstract low-contrast 3D frosted glass sleeve spines and bloom, quiet enough for text on top, filling the canvas, no letters
```

**`dwx_ControlFace`** — 512x512

```
The face of a single glass tonearm cue as a physical control, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_TwistHero`** — 1024x1024

```
Mint glass sleeve beside a Grooved sleeve wearing one GrooveMark bead, 3D glass cutout, isolated, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_SuccessMark`** — 512x512

```
A small glass needle seated in a groove after a Drop, 3D glass cutout, confirmation not fireworks, no letters

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`dwx_HeaderDecor`** — 1200x600

```
A wide low 3D glass band of sleeve spines, frosted glassmorphism, low contrast, no readable text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated subject, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`dwx.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `DeadwaxTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Deadwax -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Groove ADT fold (Mint | Grooved); the wall is a fold over Pressings; Drop writes a GrooveMark and flips Mint to Grooved; grade folds only Grooved; plays is the GrooveMark count** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take catalogcrate**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Wall-segment chrome (the sleeve wall never leaves; Discover, Crate, Heard and Taste are segments of the same wall; drop and grade fuse on the sleeve)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Deadwax
xcodegen generate
xcodebuild -scheme Deadwax -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Deadwax -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
