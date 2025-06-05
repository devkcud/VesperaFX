from tools.lut import tfloat, LUTGenerator


def identity(r: float, g: float, b: float) -> tfloat:
    return (r, g, b)


# ---------- Examples ---------- #

# def sepia(r: float, g: float, b: float) -> tfloat:
#     tr = r * 0.393 + g * 0.769 + b * 0.189
#     tg = r * 0.349 + g * 0.686 + b * 0.168
#     tb = r * 0.272 + g * 0.534 + b * 0.131
#     return (min(1.0, tr), min(1.0, tg), min(1.0, tb))

# def grayscale(r: float, g: float, b: float) -> tfloat:
#     gray = 0.299 * r + 0.587 * g + 0.114 * b
#     return (gray, gray, gray)

# def psychedelic(r: float, g: float, b: float) -> tfloat:
#     t = math.sin((r + g + b) * math.pi * 4)
#     return (abs(math.sin((r + t) * math.pi)), abs(math.sin(
#         (g + t) * math.pi)), abs(math.sin((b + t) * math.pi)))

# ------------------------------ #

lut = LUTGenerator(size=16, color_fn=identity)
lut.save('lut_16.png')
