---
name: gemini-image
description: Generate images using Google Gemini/Imagen API. Use when the user asks to create, generate, or make an image, picture, photo, illustration, artwork, or visual content.
allowed-tools: Bash(python:*), Read, Write
---

# Gemini Image Generation

Generate images using Google's Gemini and Imagen models.

## Prerequisites

The user must have:
1. A Google API key with Gemini access set as `GEMINI_API_KEY` environment variable
2. Python packages: `pip install google-genai pillow`

## Available Models

| Model | Best For | Notes |
|-------|----------|-------|
| `gemini-2.5-flash-image` | Fast, high-volume generation | Speed optimized |
| `gemini-3-pro-image-preview` | Professional assets, complex prompts | Best quality, supports 4K |
| `imagen-4.0-generate-001` | Standard image generation | Good balance |
| `imagen-4.0-fast-generate-001` | Quick iterations | Fastest |
| `imagen-4.0-ultra-generate-001` | Highest quality | Supports 2K |

## Generating Images

Use the script at `~/.claude/skills/gemini-image/scripts/generate.py`:

```bash
python ~/.claude/skills/gemini-image/scripts/generate.py \
  --prompt "A serene mountain landscape at sunset" \
  --output ~/Pictures/mountain.png \
  --model gemini-2.5-flash-image
```

### Script Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--prompt` | Yes | - | Text description of the image |
| `--output` | No | `./generated_image.png` | Output file path |
| `--model` | No | `gemini-2.5-flash-image` | Model to use |
| `--aspect-ratio` | No | `1:1` | Aspect ratio (e.g., `16:9`, `9:16`, `4:3`) |
| `--size` | No | `1K` | Image size (`1K`, `2K`, or `4K` for pro model) |
| `--count` | No | `1` | Number of images (1-4, Imagen models only) |

### Aspect Ratio Options

- `1:1` - Square (default)
- `16:9` - Widescreen landscape
- `9:16` - Portrait/mobile
- `4:3` - Standard landscape
- `3:4` - Standard portrait
- `3:2`, `2:3` - Photo aspect ratios

## Usage Workflow

1. Ask the user what they want to generate
2. Craft a detailed prompt (more detail = better results)
3. Choose appropriate model and settings
4. Run the generation script
5. Show the user where the image was saved
6. Offer to regenerate with different settings if needed

## Prompt Tips

- Be specific and descriptive
- Include style keywords: "photorealistic", "watercolor", "digital art", "3D render"
- Mention lighting: "golden hour", "studio lighting", "dramatic shadows"
- Specify perspective: "aerial view", "close-up", "wide angle"
- Add mood: "serene", "energetic", "mysterious"

## Example Prompts

**Product shot:**
```
Professional product photography of a sleek smartphone on a marble surface,
soft studio lighting, clean white background, 8K detail
```

**Artwork:**
```
Digital painting of a cyberpunk city at night, neon lights reflecting on
wet streets, flying cars, towering skyscrapers, cinematic composition
```

**Portrait:**
```
Professional headshot of a business executive, neutral background,
soft lighting, confident expression, high resolution
```

## Troubleshooting

- **API key error**: Ensure `GEMINI_API_KEY` is set in your environment
- **Package not found**: Run `pip install google-genai pillow`
- **Rate limit**: Wait a few seconds and retry, or use a different model
- **Content blocked**: Rephrase the prompt to avoid restricted content
