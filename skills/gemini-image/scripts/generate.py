#!/usr/bin/env python3
"""
Gemini Image Generation Script

Generates images using Google's Gemini and Imagen models.
Requires: pip install google-genai pillow

Set GEMINI_API_KEY environment variable before running.
"""

import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Generate images using Google Gemini/Imagen API"
    )
    parser.add_argument(
        "--prompt", "-p",
        required=True,
        help="Text description of the image to generate"
    )
    parser.add_argument(
        "--output", "-o",
        default="./generated_image.png",
        help="Output file path (default: ./generated_image.png)"
    )
    parser.add_argument(
        "--model", "-m",
        default="gemini-2.5-flash-image",
        choices=[
            "gemini-2.5-flash-image",
            "gemini-3-pro-image-preview",
            "imagen-4.0-generate-001",
            "imagen-4.0-fast-generate-001",
            "imagen-4.0-ultra-generate-001",
        ],
        help="Model to use (default: gemini-2.5-flash-image)"
    )
    parser.add_argument(
        "--aspect-ratio", "-a",
        default="1:1",
        choices=["1:1", "16:9", "9:16", "4:3", "3:4", "3:2", "2:3", "4:5", "5:4", "21:9"],
        help="Aspect ratio (default: 1:1)"
    )
    parser.add_argument(
        "--size", "-s",
        default="1K",
        choices=["1K", "2K", "4K"],
        help="Image size (default: 1K, 4K only for pro model)"
    )
    parser.add_argument(
        "--count", "-c",
        type=int,
        default=1,
        choices=[1, 2, 3, 4],
        help="Number of images to generate (1-4, Imagen models only)"
    )

    args = parser.parse_args()

    # Check for API key
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set", file=sys.stderr)
        print("Set it with: export GEMINI_API_KEY='your-api-key'", file=sys.stderr)
        sys.exit(1)

    # Import after arg parsing for faster --help response
    try:
        from google import genai
        from google.genai import types
    except ImportError:
        print("Error: google-genai package not installed", file=sys.stderr)
        print("Install with: pip install google-genai", file=sys.stderr)
        sys.exit(1)

    try:
        from PIL import Image
    except ImportError:
        print("Error: pillow package not installed", file=sys.stderr)
        print("Install with: pip install pillow", file=sys.stderr)
        sys.exit(1)

    # Initialize client
    client = genai.Client(api_key=api_key)

    # Ensure output directory exists
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Generating image with {args.model}...")
    print(f"Prompt: {args.prompt}")

    try:
        if args.model.startswith("imagen"):
            # Use Imagen API
            config = types.GenerateImagesConfig(
                number_of_images=args.count,
                aspect_ratio=args.aspect_ratio,
            )
            # Only add image_size for non-fast models
            if args.model != "imagen-4.0-fast-generate-001" and args.size != "1K":
                config.image_size = args.size

            response = client.models.generate_images(
                model=args.model,
                prompt=args.prompt,
                config=config,
            )

            # Save generated images
            for i, generated_image in enumerate(response.generated_images):
                if args.count > 1:
                    # Multiple images: add index to filename
                    stem = output_path.stem
                    suffix = output_path.suffix
                    save_path = output_path.parent / f"{stem}_{i+1}{suffix}"
                else:
                    save_path = output_path

                # Save image
                image = generated_image.image
                if hasattr(image, 'save'):
                    image.save(str(save_path))
                else:
                    # Handle raw image data
                    from io import BytesIO
                    img = Image.open(BytesIO(image._pil_image.tobytes()))
                    img.save(str(save_path))

                print(f"Saved: {save_path}")

        else:
            # Use native Gemini image generation
            config = types.GenerateContentConfig(
                response_modalities=['TEXT', 'IMAGE'],
            )

            # Add image config for supported models
            if args.model == "gemini-3-pro-image-preview":
                config.image_config = types.ImageConfig(
                    aspect_ratio=args.aspect_ratio,
                    image_size=args.size,
                )

            response = client.models.generate_content(
                model=args.model,
                contents=args.prompt,
                config=config,
            )

            # Process response parts
            image_saved = False
            for part in response.parts:
                if part.text is not None:
                    print(f"Model response: {part.text}")
                elif part.inline_data is not None:
                    image = part.as_image()
                    image.save(str(output_path))
                    print(f"Saved: {output_path}")
                    image_saved = True

            if not image_saved:
                print("Warning: No image was generated in the response", file=sys.stderr)
                if hasattr(response, 'text') and response.text:
                    print(f"Response text: {response.text}")
                sys.exit(1)

        print("Done!")

    except Exception as e:
        print(f"Error generating image: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
