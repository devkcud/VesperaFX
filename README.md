# ✨ VesperaFX - Modular Post-Processing Shader Suite

_Includes: Dithering, palette mapping, pixelation, sharpening, and color
correction._\
_Modular. Yankable. Yours to break._

**VesperaFX** is a modular, stylized post-processing shader for **Godot 4.4.1**,
featuring dithering, palette-based color mapping, pixelation, sharpening, and
flexible color adjustments.\
Designed for retro visuals, game feel tweaking, and full control over your
post-FX pipeline.

![Shader Demo](demo/demo.gif)

## 🎨 Features

- ✅ Dithering (multiple modes)
  - 🔄 Runtime-selectable dithering mode (via uniform toggle)
- ✅ Palette-based color mapping via luminance or brute-force RGB _(LUT support
  planned)_
- ✅ Pixelation with custom grid size
- ✅ Sharpening (multiple kernels)
- ✅ Color adjustments: hue, saturation, contrast, gamma
- 🧱 Modular '.gshaderinc' files. Use only what you need.

## 📦 Implementation

1. Clone or copy the shader files into your project. You'll find each effect in
   the `include/` directory.
2. Create a new `.gdshader` file in your project.
3. Include the modules you want (or everything) using:

```glsl
#include "res://path/to/include/dither.gdshaderinc"
#include "res://path/to/include/palette.gdshaderinc"
```

4. Copy relevant logic from
   [`void fragment()` in `main.gdshader`](main.gdshader) or build your
   own.

## 🧪 Usage Notes

- RGB palette matching uses brute-force comparison per pixel. This is slow.
  Consider optimizing or using a LUT (planned feature).
- Pixelation + Sharpening may cause artifacts. There's a flag
  (`#define ALLOW_PIXELATION_SHARPEN_COMBO`) to allow it, but it's not
  recommended unless you really want it.
- Effect order defaults to: Dither -> Palette Map. You can flip it by:
  `#define REVERSE_DITHER_PALETTE_MAPPING`.
- You may also include `utils.gdshaderinc` for constants and shared helpers.

## ⚙️ Files

| File                     | Purpose                            |
| ------------------------ | ---------------------------------- |
| `dither.gdshaderinc`     | Multiple dithering modes           |
| `palette.gdshaderinc`    | Palette mapping (RGB & luminance)  |
| `pixelation.gdshaderinc` | Pixel grid reduction               |
| `sharpening.gdshaderinc` | Sharpen filters (multiple kernels) |
| `rendering.gdshaderinc`  | Hue/saturation/contrast/gamma      |
| `utils.gdshaderinc`      | Shared utility functions           |

> You can yank one or all. Everything is compartmentalized.

## 📜 License

This shader is released under the [Mozilla Public License 2.0](LICENSE.txt).

Credit is optional, but always appreciated.\
Author: André Albanese Junior (@patomcio / @devkcud)

## 🧯 Support

This isn't a framework, it is a toolbox. If you want help with porting it to
Unity or making a feature for it, let me know.
