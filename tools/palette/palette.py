from typing import final

import numpy as np
from PIL import Image

type tfloat = tuple[float, float, float]
type tint = tuple[int, int, int]
type color = tfloat | tint | str
type grid = list[list[color]]


@final
class PaletteGenerator:
    def __init__(self, colors: grid, cell_size: int = 1):
        if cell_size < 1:
            raise ValueError("cell_size must be at least 1")
        if not colors or not colors[0]:
            raise ValueError("colors must be a non-empty 2D grid")

        cols = len(colors[0])
        for row in colors:
            if len(row) != cols:
                raise ValueError("all rows must have the same length")

        self.colors = colors
        self.cell_size = cell_size
        self.rows = len(colors)
        self.cols = cols

    def to_rgb(self, c: color) -> tint:
        if isinstance(c, str):
            s = c.lstrip("#")
            if len(s) == 3:
                s = "".join(ch * 2 for ch in s)
            if len(s) != 6:
                raise ValueError(f"invalid hex color: {c!r}")
            return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))

        if len(c) != 3:
            raise ValueError(f"color tuple must have 3 components: {c!r}")

        if isinstance(c[0], float):
            return (
                int(np.clip(c[0] * 255.0, 0, 255)),
                int(np.clip(c[1] * 255.0, 0, 255)),
                int(np.clip(c[2] * 255.0, 0, 255)),
            )

        return (
            int(np.clip(c[0], 0, 255)),
            int(np.clip(c[1], 0, 255)),
            int(np.clip(c[2], 0, 255)),
        )

    def generate(self) -> Image.Image:
        cs = self.cell_size
        arr = np.zeros((self.rows * cs, self.cols * cs, 3), dtype=np.uint8)

        for y, row in enumerate(self.colors):
            for x, c in enumerate(row):
                rgb = self.to_rgb(c)
                arr[y * cs : (y + 1) * cs, x * cs : (x + 1) * cs] = rgb

        return Image.fromarray(arr, mode="RGB")

    def save(self, filepath: str) -> None:
        self.generate().save(filepath)
