package oengine

import "core:fmt"
import rl "vendor:raylib"

GuiEmbeddedWindow :: struct {
    x, y: f32,
    width, height: i32,
    mouse_position: Vec2,
    target: rl.RenderTexture, 
}

gew_init :: proc(w, h: i32) -> GuiEmbeddedWindow {
    return GuiEmbeddedWindow {
        x = 0, y = 0,
        width = w, height = h,
        mouse_position = vec2_zero(),
        target = rl.LoadRenderTexture(w, h),
    };
}

gew_begin :: proc(using self: GuiEmbeddedWindow) {
    rl.BeginTextureMode(self.target);
}

gew_end :: proc() {
    rl.EndTextureMode();
}

gew_finish :: proc(using self: ^GuiEmbeddedWindow, s_x, s_y: f32, new_buffer: bool = false) {
    active := gui_active();
    if (!active.active) do return;

    if (new_buffer) do rl.BeginDrawing();
    
    x = s_x;
    y = s_y;
    rx := x + active.x;
    ry := y + active.y;
    rw := active.width - s_x * 2;
    rh := active.height - s_y * 2;

    mouse_position.x = window.mouse_position.x - rx;
    mouse_position.y = window.mouse_position.y - ry;

    rl.DrawTexturePro(
        target.texture, 
        {0, 0, f32(target.texture.width), f32(-target.texture.height)},
        {rx, ry, f32(rw), f32(rh)}, {}, 0, WHITE
    );

    if (new_buffer) do rl.EndDrawing();
}

gew_set_width :: proc(using self: ^GuiEmbeddedWindow, w: i32) {
    width = w;
    gew_reload(self);
}

gew_set_height :: proc(using self: ^GuiEmbeddedWindow, h: i32) {
    height = h;
    gew_reload(self);
}

gew_reload :: proc(using self: ^GuiEmbeddedWindow) {
    target = rl.LoadRenderTexture(width, height);
}
