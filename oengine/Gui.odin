package oengine

import rl "vendor:raylib"
import strs "core:strings"

gui_main_color := rl.Color {99, 141, 160, 255};
gui_accent_color := rl.Color {63, 105, 135, 255};
gui_darker_color := rl.Color {41, 59, 68, 255};
gui_lighter_color := rl.Color {119, 169, 191, 255};
gui_slider_color := rl.WHITE;

gui_font_size: f32 = 16;
gui_bezel_size: f32 = 2.5;
gui_text_spacing: f32 = 2;
gui_top_bar_height: f32 = 30;
gui_exit_scale: f32 = 25;

gui_default_font: rl.Font = rl.GetFontDefault();

gui_cursor := "|";
@private gui_cursor_timer: f32;

gui: struct {
    windows: map[string]^GuiWindow,
    text_boxes: map[string]^GuiTextBox,
    _active: string,
    _active_window_id: u32,
}

gui_window_exists :: proc(title: string) -> bool {
    return gui.windows[title] != nil;
}

gui_text_box_exists :: proc(tag: string) -> bool {
    return gui.text_boxes[tag] != nil;
}

gui_active :: proc() -> ^GuiWindow {
    return gui.windows[gui._active];
}

gui_window :: proc(title: string) -> ^GuiWindow {
    return gui.windows[title];
}

gui_set_window_active :: proc(title: string) {
    gui.windows[title].active = true;
}

gui_mouse_over :: proc() -> bool {
    for t, w in gui.windows {
        if (w._mouse_over) do return true;
    }

    return false;
}

gui_text :: proc(text: string, size: f32, x: f32 = 10, y: f32 = 10) {
    active := gui_active();
    if (!active.active) do return;

    rl.DrawTextEx(
        gui_default_font, 
        strs.clone_to_cstring(text), 
        rl.Vector2 {active.x + x, active.y + y}, 
        size, gui_text_spacing, rl.WHITE
    );
}

GuiTextPositioning :: enum i32 {
    CENTER,
    LEFT,
    RIGHT,
}

text_pos_renders := [?]proc(string, rl.Rectangle) {
    text_center_pos,
    text_left_pos,
    text_right_pos,
};

text_center_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := strs.clone_to_cstring(text);
    text_scale := (rec.width - gui_bezel_size * 2) / f32(rl.MeasureText(ctext, i32(gui_font_size)));

    if (text_scale * gui_font_size > rec.height - gui_bezel_size * 2) {
        text_scale = (rec.height - gui_bezel_size * 2) / gui_font_size;
    }

    text_x := rec.x + (rec.width - f32(rl.MeasureText(ctext, i32(gui_font_size * text_scale)))) / 2;
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        rl.Vector2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

text_left_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := strs.clone_to_cstring(text);
    text_scale := (rec.height - gui_bezel_size * 2) / gui_font_size;

    if (text_scale * gui_font_size > rec.width - gui_bezel_size * 2.0) {
        text_scale = (rec.width - gui_bezel_size * 2.0) / gui_font_size;
    }

    text_x := rec.x + gui_bezel_size;
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        rl.Vector2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

text_right_pos :: proc(text: string, rec: rl.Rectangle) {
    ctext := strs.clone_to_cstring(text);
    text_scale := (rec.height - gui_bezel_size * 2) / gui_font_size;

    if (text_scale * gui_font_size > rec.width - gui_bezel_size * 2.0) {
        text_scale = (rec.width - gui_bezel_size * 2.0) / gui_font_size;
    }

    text_x := rec.x + rec.width - gui_bezel_size * 2 - f32(rl.MeasureText(ctext, i32(gui_font_size * text_scale)));
    text_y := rec.y + (rec.height - gui_font_size * text_scale) / 2;

    rl.DrawTextEx(
        gui_default_font, 
        ctext, 
        rl.Vector2 {text_x, text_y}, 
        gui_font_size * text_scale, gui_text_spacing, rl.WHITE
    );
}

gui_button :: proc(text: string, x: f32 = 10, y: f32 = 10, w: f32 = 50, h: f32 = 25, 
    text_pos: GuiTextPositioning = .CENTER) -> bool {
    active := gui_active();
    if (!active.active) do return false;

    rec := rl.Rectangle {
        x = active.x + x,
        y = active.y + y,
        width = w,
        height = h,
    };

    pressed := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_released(.LEFT);
    held := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_down(.LEFT);

    rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size * 2),
            i32(rec.height + gui_bezel_size * 2), gui_darker_color);
    rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size), 
            i32(rec.height + gui_bezel_size), gui_lighter_color);

    if (!held) do rl.DrawRectangleRec(rec, gui_main_color);
    else do rl.DrawRectangleRec(rec, gui_accent_color);

    text_pos_renders[text_pos](text, rec);

    return pressed;
}

gui_plain_rec :: proc(x, y, width, height: f32) {
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size * 2),
        i32(height + gui_bezel_size * 2), gui_darker_color);
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size), i32(height + gui_bezel_size),
        gui_lighter_color);
    rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), gui_main_color);
}

gui_inverse_rec :: proc(x, y, width, height: f32) {
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size * 2),
        i32(height + gui_bezel_size * 2), gui_lighter_color);
    rl.DrawRectangle(i32(x - gui_bezel_size), i32(y - gui_bezel_size), i32(width + gui_bezel_size), i32(height + gui_bezel_size),
        gui_darker_color);
    rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), gui_main_color);
}

gui_interactive_rec :: proc(icon: GuiIcon, x, y, w, h: f32, press_mode: bool, w_move: bool) -> bool {
    rec := rl.Rectangle {x, y, w, h};

    if (w_move) {
        active := gui_active();
        rec.x = x + active.x;
        rec.y = y + active.y;
    }

    pressed := rl.CheckCollisionPointRec(window.mouse_position, rec) && press_mode;

    gui_icon(icon, i32(rec.x), i32(rec.y), i32(rec.width), i32(rec.height));

    return pressed;
}

GuiIcon :: enum {
    EMPTY,
    EXIT,
    FILE,
    RESIZE,
}

GuiIconRenders := [?]proc(x, y, w, h: i32) {
    proc(x, y, w, h: i32) {}, // empty
    exit_icon,
    file_icon,
    resize_icon,
}

@(private = "file")
exit_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y, x + w, y + h, rl.WHITE);
    rl.DrawLine(x, y + h, x + w, y, rl.WHITE);
}

@(private = "file")
file_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y + h, x + w, y + h, rl.WHITE);
    rl.DrawLine(x + w, y + h, x + w, y, rl.WHITE);
    rl.DrawLine(x, y, x + w, y, rl.WHITE);
    rl.DrawLine(x, y, x, y + h, rl.WHITE);
}

@(private = "file")
resize_icon :: proc(x, y, w, h: i32) {
    rl.DrawLine(x, y + h, x + w, y, rl.WHITE);
    rl.DrawLine(x + w/2, y + h, x + w, y + h/2, rl.WHITE);
}

gui_icon :: proc(icon: GuiIcon, x, y, w, h: i32) {
    GuiIconRenders[i32(icon)](x, y, w, h);
}