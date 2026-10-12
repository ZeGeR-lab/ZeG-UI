"""Generate original, exact triangle alpha textures; requires Pillow."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

media = Path(__file__).resolve().parents[1] / "Media"
media.mkdir(exist_ok=True)
size, supersample = 256, 4

def polygon(points):
    image = Image.new("L", (size * supersample, size * supersample))
    ImageDraw.Draw(image).polygon([(x * supersample, y * supersample) for x, y in points], fill=255)
    return image

outer = polygon([(128, 2), (254, 254), (2, 254)])
inner = polygon([(128, 13), (245, 249), (11, 249)])
for suffix, alpha in (("", outer), ("Border", ImageChops.subtract(outer, inner))):
    alpha = alpha.resize((size, size), Image.Resampling.LANCZOS)
    for direction in ("Up", "Down"):
        oriented = alpha if direction == "Up" else alpha.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        texture = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        texture.putalpha(oriented)
        # Uncompressed 32-bit TGA, power-of-two dimensions, explicit alpha.
        texture.save(media / f"Triangle{direction}{suffix}.tga", compression=None)
