# Alphabetter for macOS
ˈæɫ.fəˌbɛ.ɾɚ ɪz æn æp fɔɹ using the International Phonetic Alphabet. The IPA is accessible via key cycling and a palette. And yes, I actually typed that first bit using my app, and you can too!

<img src="Screenshots/screenshot3.png" width="300" alt="Alphabetter app icon">


## Installation

1. Download the latest `Alphabetter.zip` from the **Releases** page.
2. Double‑click the zip to extract `Alphabetter.app`.
3. Drag `Alphabetter.app` into your **Applications** folder.

### First launch

Because this is a small, non–App Store app, macOS will probably show an “unidentified developer” warning the first time.

1. In Finder, go to **Applications**.
2. Right‑click `Alphabetter.app` and choose **Open**.
3. In the dialog that appears, click **Open** again.

After this, you can open Alphabetter normally (Dock, Spotlight, Launchpad, etc.).

### Enabling Accessibility

Alphabetter needs Accessibility permission to read keystrokes and type IPA characters.

1. On first launch, macOS will show a dialog asking to grant access.
2. Click **Open System Settings**.
3. Go to **Privacy & Security → Accessibility**.
4. Find **Alphabetter** in the list and turn it **On**.  
   - If it’s not there yet, click **+**, choose `Alphabetter.app` from Applications, and add it, then enable it.

> **Important:** After changing Accessibility permissions, quit and relaunch Alphabetter to make sure it picks up the new access. If you don't do this, you'll probably be able to use the palette. If you the full keyboard experience (which is a time-saver), then be sure to grant access and relaunch.

### Updating

If/when I release a new version:

1. Quit Alphabetter if it’s running.
2. Download the new `Alphabetter.zip` from Releases.
3. Replace the old `Alphabetter.app` in Applications with the new one.

## Using Alphabetter
Alphabetter lives in your menu bar and stays out of your way until you need it. The app relies on the Right Option key to trigger IPA input.

### 1. Cycle Trigger (Right Option)

To type IPA symbols, simply hold the Right Option key on your keyboard.

Hold Right Option + Press a Letter: types the most common IPA variant for that letter.

Keep Holding Right Option + Press Again: cycles through other variants.

Example:

- Hold Right Option + press n → ŋ (engma)
- Press n again (while holding Option) → ɲ (palatal nasal)
- Press n again → ɳ (retroflex nasal)
You can also type common diacritics using Right Option + Shift + a key. For example, to type an aspirated pʰ, you would type p then Right Option + Shift + h.

### 2. Special Shortcuts

For speed, some common symbols have dedicated overrides or special cycling rules:

| Shortcut (Hold Rt Option) | Result | Notes |
| :--- | :--- | :--- |
| **Opt + F** | **͡** | Tie bar / Ligature (helpful for affricates) |
| **Opt + Q** | **ˈ** / **ˌ** | Cycles between Primary and Secondary stress |
| **Opt + Semicolon (;)** | **ː** | Length mark |
| **Opt + Period (.)** | **◌̆** | Breve (for short vowels) |

### 3. The Visual Palette

<img src="Screenshots/screenshot4.png" width="500" alt="Alphabetter app icon">

If you can't remember a shortcut or need to search by name, open the palette.

- **Shortcut**: Hold Right Option + Spacebar (this is customizable in the app settings).

- **Tooltips**: Hover over symbols to see their descriptions, shortcuts (if available), and unicode ID.

<img src="Screenshots/screenshot1.png" width="400" alt="Alphabetter tooltips">

- **Search**: Type to filter by feature or name. You can also filter out the noise and just show results for English symbols by clicking `ENG` next to the search bar.

- **Insert**: Click any symbol to type it into your active document.

- **Recents**: The top bar tracks your most recently used symbols for quick access.

- **Tables**: There are also tabs containing tables of IPA symbols in more familiar layouts. Clicking on the symbols in these tables will insert them in your document just like from the search palette.

<img src="Screenshots/screenshot2.png" width="700" alt="Alphabetter table">


### 4. Menu Bar Cheat Sheet

Click the Alphabetter icon (the little IPA bottle 🍾) in your macOS menu bar to see a quick cheat sheet for tones and other common diacritics without opening the full window.

<img src="Screenshots/screenshot5.png" width="500" alt="Alphabetter menu bar cheat sheet">


## Copyright © 2025 Mikhael Hayes. All rights reserved
You may download and use this app for personal and educational purposes. Redistribution of modified versions is not permitted.
