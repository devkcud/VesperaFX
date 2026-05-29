from palette import PaletteGenerator, color

colors: list[list[color]] = [
    ["#ff0000", "#00ff00", "#0000ff", "#ffff00"],
    [(1.0, 0.5, 0.0), (0.5, 0.0, 1.0), (0.0, 1.0, 0.5), (1.0, 1.0, 1.0)],
    [(20, 20, 20), (80, 80, 80), (160, 160, 160), (240, 240, 240)],
]

palette = PaletteGenerator(colors=colors, cell_size=32)
palette.save("palette.png")
