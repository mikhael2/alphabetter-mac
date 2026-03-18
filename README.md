# Alphabetter for macOS
ˈæɫ.fəˌbɛ.ɾɚ ɪz æn æp fɔɹ using the International Phonetic Alphabet. The IPA is accessible via key cycling and a palette. And yes, I actually typed that first bit using my app, and you can too!

![Version](https://img.shields.io/badge/version-1.1.0-blue) ![Platform](https://img.shields.io/badge/platform-macOS%2014.6%2B-lightgrey)

<img src="Screenshots/screenshot3.png" width="300" alt="Alphabetter app icon">


## Installation

> **Important:** This app is only supported for macOS 14.2 (Sonoma) and higher (including macOS 26.2 Tahoe). Please update your computer before proceeding with the installation.

1. Download the latest `Alphabetter.zip` from <a href="https://github.com/mikhael2/alphabetter-mac/releases" target="_blank">Releases</a>.
2. If the file appears as `Alphabetter.app`, just open Finder and drag it into your Applications folder. If it downloads as `Alphabetter.zip`, double-click it, then drag the `.app` file into your Applications folder.

### First launch

Because this is a small, non–App Store app, macOS will probably show an “unidentified developer” warning the first time.

1. In Finder, go to **Applications**.
2. Right‑click `Alphabetter.app` and choose **Open**.
3. A warning will pop saying "Alphabetter.app Not Opened: Move to Trash or Done". Click **Done**.
4. Go to your System Settings → Privacy & Security → Security.
5. Next to the dialog "'Alphabetter.app' was blocked to protect your Mac", click **Open Anyway**.
7. In the new dialog that appears, click **Open Anyway**

<img src="Screenshots/screenshot6.png" width="500" alt="System settings permissions">

After this, you can open Alphabetter normally (Dock, Spotlight, Launchpad, etc.).

### Enabling Accessibility

Alphabetter needs Accessibility permission to read keystrokes and type IPA characters.

1. After clicking **Open Anyway**, a dialog box will appear saying "'Alphabetter.app' would like to control this computer using accessibility features."
2. Click **Open System Settings**.
3. Find **Alphabetter.app** in the list and toggle it **On**.  
   - If it’s not there yet, click **+**, choose `Alphabetter.app` from Applications, and add it, then enable it.
4. After granting permission, quit Alphabetter (via the new bottle icon in your menu bar) and relaunch to make sure it picks up the new access. If you don't do this, the keyboard shortcuts won't work. 

> **Privacy:** None of your data is collected, stored, or transmitted. The Accessibility permission is strictly required because macOS treats the "interception" of global keystrokes (to detect the Right Option key) and the automated "typing" of IPA symbols as sensitive system-level actions. This app operates entirely locally on your machine.

### Updating

Alphabetter updates automatically. To check for a new version manually:

1. Click the menu bar icon (the little IPA bottle 🍾).
2. Select **Settings** → **Check for Updates**.
3. Click **Install and Relaunch**.

*(If automatic updates ever fail, you can manually download the latest version from the [Releases page](https://github.com/mikhael2/alphabetter-mac/releases) and replace the app in your Applications folder.)*

## Using Alphabetter
Alphabetter lives in your menu bar and stays out of your way until you need it. The app relies on the Right Option key to trigger IPA input.

### 1. Cycle Trigger (Right Option)

To type IPA symbols, simply hold the Right Option key on your keyboard.

- Hold Right Option + Press a Letter: Types the most common IPA variant for that letter.
- Keep Holding Right Option + Press Again: Cycles through other variants.

Example:

- Hold `Right Option` + press `n` → `ŋ` (engma)
- Press `n` again (while holding `Option`) → `ɲ` (palatal nasal)
- Press `n` again → `ɳ` (retroflex nasal)

You can also type common diacritics using `Right Option` + `Shift` + a key. For example, to type an aspirated `pʰ`, you would type `p` then `Right Option` + `Shift` + `h`.

### 2. Keyboard Shortcuts

Alphabetter includes the following types of keybind cycles:

#### Primary (`Right Option` + Key) — cycles through IPA variants

| Shortcut | Cycles through |
| :--- | :--- |
| **⌥ N** | ŋ → ɲ → ɳ → ɴ |
| **⌥ S** | ʃ → ʂ |
| **⌥ T** | θ → ʈ → t͡ʃ → t͡s |
| **⌥ D** | ð → ɖ → ɗ → d͡ʒ |
| **⌥ F** | ͡ (tie bar) → ͜ → ‿ (linking) |
| **⌥ Q** | ˈ (primary stress) → ˌ (secondary) |
| **⌥ ;** | ː (long) → ˑ (half-long) |
| **⌥ ,** | ̜ (less rounded) → ̹ (more rounded) |
| **⌥ .** | ̆ (extra-short) → ̈ (centralized) |
| **⌥ 2** | ʔ → ʕ → ʡ → ʢ |
| **⌥ 3** | ɛ → ɜ → ɝ → ẽ → ɞ |

*… and many more. Hover over any symbol in the Diacritics or Charts tabs to see its exact shortcut.*

#### Secondary (`Shift + Right Option` + Key) — diacritics

Secondary shortcuts **also cycle** — press the same combination again to advance:

| Shortcut | Cycles through | Meaning |
| :--- | :--- | :--- |
| **⇧⌥ H** | ʰ → ʱ | Aspirated → Breathy-asp. |
| **⇧⌥ F** | ː → ˘ → ˑ | Long → Extra-short → Half-long |
| **⇧⌥ L** | ̚ → ˡ | No aud. release → Lateral release |
| **⇧⌥ D** | ̪ → ̺ → ̻ | Dental → Apical → Laminal |
| **⇧⌥ S** | ̃ → ̴ → ̰ | Nasalized → Velarized → Creaky |
| **⇧⌥ Z** | ̟ → ̠ | Advanced → Retracted |
| **⇧⌥ K** | ̝ → ̞ | Raised → Lowered |
| **⇧⌥ A** | ̘ → ̙ | Adv. Tongue Root → Ret. Tongue Root |
| **⇧⌥ O** | ̥ → ˚ | Voiceless |
| **⇧⌥ J / W / Y / P** | ʲ / ʷ / ˠ / ˤ | Palatalized / Labialized / Velarized / Pharyngealized |
| **⇧⌥ B** | ̼ | Linguolabial |
| **⇧⌥ G** | ̽ | Mid-centralized |
| **⇧⌥ 1–0** | ̏ ̀ ̄ ́ ̋ ̌ ̂ … | Tone diacritics |

*Full reference visible by hovering any button in the **Diacritics** tab.*

### 3. The Visual Palette

<img src="Screenshots/screenshot4.png" width="500" alt="Alphabetter app icon">

If you can't remember a shortcut or need to search by name, open the palette.

- **Shortcut**: Hold `Right Option` + `Spacebar` (this is customizable in the app settings).

- **Tooltips**: Hover over symbols to see their descriptions, shortcuts (if available), and unicode ID.

<img src="Screenshots/screenshot1.png" width="400" alt="Alphabetter tooltips">

- **Search**: Type to filter by name or phonological features. Use the **profile picker** next to the search bar to filter results to a custom character set (e.g. just English sounds). Create and edit profiles in Settings.

- **Insert**: Click any symbol to type it into your active document.

- **Recents**: The top bar tracks your most recently used symbols for quick access.

- **Tabs**: Consonants, Vowels, and Diacritics tabs contain interactive IPA charts. The window remembers your last-used tab between sessions.


<img src="Screenshots/screenshot2.png" width="700" alt="Alphabetter table">

You can leave the palette any time by hitting the `Escape` key.

### 4. Menu Bar "Quick Insert"

Click the Alphabetter menu bar icon (the little IPA bottle 🍾) in your macOS menu bar to see a dropdown for quickly inserting tones and other common diacritics without opening the full window.

<img src="Screenshots/screenshot5.png" width="500" alt="Alphabetter menu bar quick insert">

### 5. Settings

Access via the menu bar icon or `Cmd` + `,` while the palette is open.

- **Global Shortcut**: Change the key used to toggle the visual palette (default: `Right Option + Space`).
- **Custom Profiles**: Create named subsets of IPA characters. Right-click any symbol anywhere to add it to a profile. Switch profiles in the Search tab.
- **Appearance**: Choose accent color and light/dark/system theme.
- **Check for Updates**: Checks GitHub for new app versions (or updates install automatically in the background).
- **Hide Dock Icon**: Run Alphabetter exclusively in the menu bar.

## 🗺️ Roadmap

- [x] Key cycling logic
- [x] GUI: Palette view and clickable IPA charts
- [x] Themes (accent color + dark/light mode)
- [x] Customizable filters/profiles
- [ ] Practice: Rapid identification
- [ ] Practice: Transcription challenges
- [ ] Audio integration
- [ ] Sagittal sections

## License & Copyright

**App Logic & Code:**
Copyright © 2025 Mikhael Hayes. All rights reserved.
The source code and software design of this application are proprietary. You may use this app for personal and educational purposes, but redistribution of the app's source code or modified versions of the software logic is not permitted without the author's consent.

**IPA Data & Charts:**
This app includes reproductions of the International Phonetic Alphabet (IPA). The IPA chart and data remain under the Creative Commons Attribution-Sharealike 3.0 Unported License (CC-BY-SA).


"IPA Chart, http://www.internationalphoneticassociation.org/content/ipa-chart, available under a Creative Commons Attribution-Sharealike 3.0 Unported License. Copyright © 2015 International Phonetic Association."
