# Changelog

All notable changes to Alphabetter are documented here.

---

## [1.1.0] — 2026-03-17 "Saint Patrick's Day Update ☘️"

### New Features

- **Customizable Search Profiles** — Create named subsets of IPA characters (like "playlists") to filter the Search tab. Add symbols to a profile by right-clicking any IPA button. Manage profiles in Settings.
- **All Diacritics Mapped** — Every diacritic in the chart now has a keyboard shortcut, including previously missing ones: advanced/retracted (⇧⌥Z), raised/lowered (⇧⌥K), ATR/RTR (⇧⌥A), laminal (⇧⌥D ×3), linguolabial (⇧⌥B), pharyngealized (⇧⌥P), mid-centralized (⇧⌥G)
- **Shift + Option Cycling** — Secondary shortcuts (`Shift + Right Option`) now cycle through multiple characters just like primary shortcuts, instead of only outputting a single fixed character
- **Tie Bar on Affricates** — `⌥T` (×3/4) now inserts canonical `t͡ʃ` and `t͡s` with tie bar; `⌥D` (×4) inserts `d͡ʒ`

### Improvements

- **Diacritics Tab Redesign** — Section headers now match the Tones tab style (UPPERCASED bold headers, `VStack`-based rows, pixel-perfect dividers). ʱ (breathy-voice aspirated) added to the chart
- **Tone & Word Accent Rows** — Hovering anywhere in a level-tone row now shows a tooltip and allows clicking to insert the diacritic. The tone bar letter (˥˦˧˨˩) retains its own separate hover/click/tooltip
- **Unicode-Aware Tooltips** — Characters not in the database now show their official Unicode scalar name (e.g. "Modifier letter small h with hook") instead of "Unknown"
- **Chart Label Colors** — Consonant and Vowel chart column/row headers now use the active theme accent color instead of hardcoded green/blue
- **Pinker Pink** — The pink accent color is now a true bubblegum magenta instead of the previous red-leaning pink
- **Dotted Circle Detection** — Preview circles (◌) are now shown for all appropriate diacritics using Unicode category detection, including modifier letters like ʰ ʱ ʲ ˠ ˤ ˞ that were previously missing the circle
- **Better Cell Height** — Diacritic cells have more vertical padding so descending marks like ̼ don't clip the cell border
- **Font Coverage** — All symbol cells now use SF Pro (`.default`) instead of `.serif`, fixing invisible characters like the linking arc ‿ in the Search tab and elsewhere
- **Hover Text Shadow** — Accent-colored hover text now has a subtle black drop shadow for legibility over white backgrounds
- **Persistent Tab** — The palette remembers your last-used tab between sessions. `⌥Space` opens directly to Diacritics, Consonants, Search — wherever you left off

### Bug Fixes

- Fixed "English (Default)" label in profile menu — now just shows "English"
- Fixed layout overflow in Settings (profiles section now scrolls properly)
- Fixed content being pushed into the header area

---

## [1.0.1] — 2026-01-16

- Bug fixes and Sparkle updating
