import numpy as np
from PIL import Image
from typing import Callable, final

type tfloat = tuple[float, float, float]
type func = Callable[[float, float, float], tfloat]


@final
class LUTGenerator:
    def __init__(self, size: int, color_fn: func):
        if size < 2:
            raise ValueError("Size must be at least 2")

        self.size = size
        self.color_fn = color_fn

    def generate(self) -> Image.Image:
        N = self.size
        arr = np.zeros((N, N * N, 3), dtype=np.uint8)

        arr[0, 0] = (N, 0, 0)

        for b in range(N):
            b_norm = b / (N - 1)
            for g in range(N):
                g_norm = g / (N - 1)
                for r in range(N):
                    r_norm = r / (N - 1)

                    x = r + b * N
                    y = g

                    if x == 0 and y == 0:
                        continue

                    out = self.color_fn(r_norm, g_norm, b_norm)

                    if isinstance(out[0], float):
                        cr = int(np.clip(out[0] * 255.0, 0, 255))
                        cg = int(np.clip(out[1] * 255.0, 0, 255))
                        cb = int(np.clip(out[2] * 255.0, 0, 255))
                    else:
                        cr, cg, cb = out

                    arr[y, x] = (cr, cg, cb)

        return Image.fromarray(arr, mode="RGB")

    def save(self, filepath: str) -> None:
        self.generate().save(filepath)
