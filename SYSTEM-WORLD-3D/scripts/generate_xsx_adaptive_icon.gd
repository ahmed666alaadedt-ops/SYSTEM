
@tool
extends EditorScript

const SOURCE := "res://assets/1000220666-1.png"
const OUTPUT_DIR := "res://assets/adaptive/"
const SIZE := 432

func _run() -> void:
    var original := Image.load_from_file(SOURCE)
    if original == null or original.is_empty():
        push_error("XSX source image not found")
        return

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT_DIR)
    )

    # Foreground: preserve the complete original card
    var foreground := Image.create(
        SIZE, SIZE, false, Image.FORMAT_RGBA8
    )
    foreground.fill(Color(0, 0, 0, 0))

    original.resize(360, 360, Image.INTERPOLATE_LANCZOS)
    foreground.blit_rect(
        original,
        Rect2i(0, 0, 360, 360),
        Vector2i(36, 36)
    )

    var foreground_path := OUTPUT_DIR + "xsx_foreground.png"
    var foreground_error := foreground.save_png(foreground_path)

    # Background: dark premium surface with a subtle gold center
    var background := Image.create(
        SIZE, SIZE, false, Image.FORMAT_RGBA8
    )

    for y in range(SIZE):
        for x in range(SIZE):
            var dx := float(x - SIZE / 2) / SIZE
            var dy := float(y - SIZE / 2) / SIZE
            var distance := sqrt(dx * dx + dy * dy)
            var glow := clampf(1.0 - distance * 2.0, 0.0, 1.0)

            var dark := Color(0.012, 0.018, 0.03)
            var gold := Color(0.12, 0.075, 0.025)
            background.set_pixel(
                x, y, dark.lerp(gold, glow * 0.65)
            )

    var background_path := OUTPUT_DIR + "xsx_background.png"
    var background_error := background.save_png(background_path)

    if foreground_error == OK and background_error == OK:
        print("XSX adaptive icon files generated successfully.")
    else:
        push_error("Could not save one or more XSX icon files.")
