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

gui_default_font: rl.Font;

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

gui_toggle_window :: proc(title: string) {
    gui.windows[title].active = !gui.windows[title].active;
}

gui_set_window_unactive :: proc(title: string) {
    gui.windows[title].active = false;
}

gui_mouse_over :: proc() -> bool {
    for t, w in gui.windows {
        if (w._mouse_over) do return true;
    }

    return false;
}

gui_text :: proc(text: string, size: f32, x: f32 = 10, y: f32 = 10, standalone: bool = false) {
    active := gui_active();
    if (active != nil && !active.active && !standalone) do return;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    rl.DrawTextEx(
        gui_default_font, 
        strs.clone_to_cstring(text), 
        rl.Vector2 {rx + x, ry + y}, 
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
    text_pos: GuiTextPositioning = .CENTER, standalone: bool = false, decorated: bool = true) -> bool {
    active := gui_active();
    if (active != nil && !active.active && !standalone) do return false;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    rec := rl.Rectangle {
        x = rx + x,
        y = ry + y,
        width = w,
        height = h,
    };

    pressed := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_released(.LEFT);
    held := rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_down(.LEFT);

    if (decorated) {
        rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size * 2),
                i32(rec.height + gui_bezel_size * 2), gui_darker_color);
        rl.DrawRectangle(i32(rec.x - gui_bezel_size), i32(rec.y - gui_bezel_size), i32(rec.width + gui_bezel_size), 
                i32(rec.height + gui_bezel_size), gui_lighter_color);

        if (!held) do rl.DrawRectangleRec(rec, gui_main_color);
        else do rl.DrawRectangleRec(rec, gui_accent_color);
    } else {
        rl.DrawRectangleLinesEx(rec, 1, WHITE);
    }

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

gui_tick :: proc(tick: bool, x, y, w, h: f32, standalone: bool = false) -> bool {
    active := gui_active();
    if (!active.active && !standalone) do return false;

    rx: f32;
    ry: f32;

    if (!standalone) {
        rx = active.x;
        ry = active.y;
    }

    rp := Vec2 {x + rx, y + ry};

    gui_inverse_rec(rp.x, rp.y, w, h);

    res := tick

    rec := rl.Rectangle {rp.x, rp.y, w, h};
    if (rl.CheckCollisionPointRec(window.mouse_position, rec) && mouse_pressed(.LEFT)) {
        res = !res;
    }

    if (tick) do gui_icon(.EXIT, i32(rp.x), i32(rp.y), i32(w), i32(h));

    return res;
}
