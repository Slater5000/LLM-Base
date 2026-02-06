# Sprite Generation Guide - 4 Legendaries

## OPTION A: Civitai Online (Easiest)

### Step 1: Create Account
1. Go to https://civitai.com
2. Click "Sign Up" (top right)
3. Verify email

### Step 2: Open Generator
1. Click blue **"Create"** button (top of page)
2. You're now in the generator

### Step 3: Select Base Model
1. Click the model dropdown (usually says "SDXL" or similar)
2. Search for **"NoobAI"** or **"Pony Diffusion V6 XL"**
3. Select it

### Step 4: Add the Pokemon LoRA
1. Click **"+ Add Additional Resource"**
2. Search for **"Pokemon Sprite XL PixelArt"**
3. Or paste: `378602` in the search
4. Set LoRA strength to **0.7-0.8**

### Step 5: Configure Settings
```
Width: 768
Height: 768  (or 1536 for front+back on same image)
Steps: 25-30
CFG Scale: 7
Sampler: DPM++ 2M Karras
```

### Step 6: Generate (see prompts below)

### Step 7: Download & Downscale
- Download the 768px image
- Use any image editor to resize to 96x96
- Save as PNG with transparency if needed

---

## OPTION B: Google Colab (Free but more setup)

### Step 1: Open the Notebook
https://colab.research.google.com/github/R3gm/SD_diffusers_interactive/blob/main/Stable_diffusion_interactive_notebook.ipynb

### Step 2: Sign into Google
- Use your Google account
- Accept the Colab terms if prompted

### Step 3: Connect to GPU
1. Click **Runtime** (top menu)
2. Click **Change runtime type**
3. Select **T4 GPU**
4. Click Save

### Step 4: Run Setup Cell
1. Click the first code cell (Button 1)
2. Click the Play button (or Ctrl+Enter)
3. Wait 2-5 minutes for install
4. Use "Fast_experimental_installation" if available

### Step 5: Load Base Model
1. Run Button 2
2. Enter model name: `kitty7779/ponyDiffusionV6XL`
3. Or search HuggingFace for "NoobAI" and use that path

### Step 6: Add the LoRA
1. Go to https://civitai.com/models/378602?modelVersionId=1415213
2. Right-click the blue **Download** button
3. Click **Copy link address**
4. Paste into the LoRA URL field in Colab
5. Re-run the GUI cell

### Step 7: Launch GUI (Button 3)
- Click run
- A simple interface will appear
- Enter prompts below, hit Generate

### Step 8: Connect Google Drive (Recommended)
- Run the Drive cell
- Authorize access
- Images save to your Drive so you don't lose them

---

## PROMPTS FOR 4 LEGENDARIES

Copy-paste these exactly:

---

### PRIMORDIUS (Earth Gorilla)
```
pokemon sprite, pixel art, skeletal gorilla made of dark meteorite stone, ancient glowing green runes carved into bones, earth type legendary, prehistoric fossil creature, brown and gray with green glow accents, front view, white background, game sprite
```

**Negative prompt:**
```
blurry, low quality, watermark, text, human, realistic, 3d render, photo
```

**Alt prompts to try:**
```
pokemon sprite, pixel art, primordial gorilla golem, bone and meteor rock hybrid, mysterious glyphs glowing, earth elemental titan, dark iron texture with moss, front facing sprite

pokemon sprite, pixel art, ancient stone ape skeleton, cosmic meteorite body, eldritch carvings, earth type monster, fossile creature with runes, game asset
```

---

### STORM (Fire/Lightning Cat)
```
pokemon sprite, pixel art, two-headed cat made of crackling lightning, electric fur, twin tails arcing with yellow energy, fire type legendary, volatile and powerful, golden yellow with blue electric accents, front view, white background, game sprite
```

**Negative prompt:**
```
blurry, low quality, watermark, text, human, realistic, 3d render, photo
```

**Alt prompts to try:**
```
pokemon sprite, pixel art, twin headed lightning feline, electric storm cat, two tails made of electricity, yellow and blue energy, legendary electric beast, front facing sprite

pokemon sprite, pixel art, double headed thunder cat, crackling energy body, plasma tails, fire electric hybrid, fierce legendary creature, game asset
```

---

### LUMINARA (Water Jellyfish)
```
pokemon sprite, pixel art, angelic jellyfish made of pure flowing water, translucent glowing body, ancient glyphs rippling through form, water type legendary, ethereal and serene, light blue and white, bioluminescent, front view, white background, game sprite
```

**Negative prompt:**
```
blurry, low quality, watermark, text, human, realistic, 3d render, photo
```

**Alt prompts to try:**
```
pokemon sprite, pixel art, celestial water jellyfish, divine aquatic creature, transparent body with glowing runes, water elemental angel, cyan and white glow, front facing sprite

pokemon sprite, pixel art, ethereal jellyfish of pure water, holy aquatic being, magical glyphs visible inside, legendary water type, bioluminescent tentacles, game asset
```

---

### ZEPHYRUS (Air Octopus)
```
pokemon sprite, pixel art, octopus made of swirling wind and air currents, eight tentacles are visible wind streams, air type legendary, ethereal and swift, light cyan and white, wispy translucent body, front view, white background, game sprite
```

**Negative prompt:**
```
blurry, low quality, watermark, text, human, realistic, 3d render, photo
```

**Alt prompts to try:**
```
pokemon sprite, pixel art, wind elemental octopus, tentacles made of visible air currents, sky spirit creature, air type legendary, pale blue and white wisps, front facing sprite

pokemon sprite, pixel art, ethereal wind octopus, gaseous floating cephalopod, eight arms of swirling breeze, legendary air type, translucent windy body, game asset
```

---

## SETTINGS REFERENCE

| Setting | Recommended Value |
|---------|-------------------|
| Resolution | 768x768 |
| Steps | 25-30 |
| CFG Scale | 7-8 |
| Sampler | DPM++ 2M Karras |
| LoRA Strength | 0.7-0.8 |
| Denoise | 1.0 (for txt2img) |

---

## AFTER GENERATING

### Downscale to Game Size
Your game uses ~96x96 sprites. Options:

**Online:**
- https://www.iloveimg.com/resize-image
- Set width to 96, keep aspect ratio

**Photoshop/GIMP:**
- Image > Scale Image > 96x96
- Use "Nearest Neighbor" interpolation (keeps pixels crisp)

**ImageMagick (command line):**
```bash
magick input.png -filter point -resize 96x96 output.png
```

**Python script:**
```python
from PIL import Image
img = Image.open("input.png")
img = img.resize((96, 96), Image.NEAREST)
img.save("output.png")
```

---

## TIPS

1. **Generate multiple** - Make 4-8 versions, pick the best
2. **Iterate** - If close but not perfect, use img2img with that as input
3. **Consistency** - Once you get one you like, use it as style reference for others
4. **Transparent background** - May need to manually remove white bg in image editor
5. **Touch up** - Small pixel edits in Aseprite/Pixilart are fine

---

## TROUBLESHOOTING

**"Out of memory" in Colab:**
- Reduce resolution to 512x512
- Reduce steps to 20

**LoRA not loading:**
- Make sure you copied the full download URL
- Try refreshing and re-adding

**Images look wrong:**
- Increase CFG scale (try 8-10)
- Add more specific terms to prompt
- Try different base model

**Colab disconnects:**
- Free tier has time limits
- Save to Google Drive frequently
- Try Kaggle as alternative
