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

# Matching round tracker masks and borders, generated from exact geometry.
outer = Image.new("L", (size * supersample, size * supersample))
inner = outer.copy()
ImageDraw.Draw(outer).ellipse((2*supersample, 2*supersample, 254*supersample, 254*supersample), fill=255)
ImageDraw.Draw(inner).ellipse((6*supersample, 6*supersample, 250*supersample, 250*supersample), fill=255)
for name, alpha in (("CircleMask", outer), ("CircleBorder", ImageChops.subtract(outer, inner))):
    texture = Image.new("RGBA", (size, size), (255,255,255,0))
    texture.putalpha(alpha.resize((size,size), Image.Resampling.LANCZOS))
    texture.save(media / (name + ".tga"), compression=None)

# Octagons leave diamond gaps when arranged in a square grid.
outer = polygon([(75,2),(181,2),(254,75),(254,181),(181,254),(75,254),(2,181),(2,75)])
inner = polygon([(77,6),(179,6),(250,77),(250,179),(179,250),(77,250),(6,179),(6,77)])
for name, alpha in (("Octagon", outer), ("OctagonBorder", ImageChops.subtract(outer, inner))):
    texture = Image.new("RGBA", (size,size), (255,255,255,0))
    texture.putalpha(alpha.resize((size,size), Image.Resampling.LANCZOS))
    texture.save(media / (name + ".tga"), compression=None)

# Soft, wider strokes are baked into alpha textures; no extra runtime masks.
from PIL import ImageFilter
for asset in ("TriangleUp", "TriangleDown", "Octagon"):
    mask = Image.open(media / (asset + ".tga")).getchannel("A")
    for suffix, erosion, blur in (("Soft",21,2.5),("Bold",25,0)):
        alpha = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(erosion)))
        if blur: alpha = alpha.filter(ImageFilter.GaussianBlur(blur))
        texture = Image.new("RGBA",(128,128),(255,255,255,0))
        texture.putalpha(alpha.resize((128,128),Image.Resampling.LANCZOS))
        texture.save(media / (asset + "Border" + suffix + ".tga"), compression=None)
mask = Image.new("L",(256,256))
ImageDraw.Draw(mask).rounded_rectangle((2,2,254,254),radius=12,fill=255)
for suffix,erosion,blur in (("Thin",9,0),("Soft",21,2.5),("Bold",25,0)):
    alpha = ImageChops.subtract(mask,mask.filter(ImageFilter.MinFilter(erosion)))
    if blur: alpha=alpha.filter(ImageFilter.GaussianBlur(blur))
    texture=Image.new("RGBA",(128,128),(255,255,255,0))
    texture.putalpha(alpha.resize((128,128),Image.Resampling.LANCZOS))
    texture.save(media / ("SquareBorder" + suffix + ".tga"),compression=None)
