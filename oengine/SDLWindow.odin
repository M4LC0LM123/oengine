package oengine

import "core:fmt"
import "core:time"
import strs "core:strings"
import rl "vendor:raylib"
import sdl "vendor:sdl2"
import "vendor:sdl2/ttf"

sdl_create_window :: proc(#any_int w, h: i32, title: string) -> ^sdl.Window {
    window := sdl.CreateWindow(
        strs.clone_to_cstring(title), 
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, w, h, 
        nil
    );
    if (window == nil) {
        dbg_log(str_add("Failed to create sdl window: ", string(sdl.GetError())), DebugType.ERROR);
        return nil;
    }

    return window;
}

sdl_create_renderer :: proc(window: ^sdl.Window) -> ^sdl.Renderer {
    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED);
    if (renderer == nil) {
        dbg_log(str_add("Failed to create sdl renderer: ", string(sdl.GetError())), DebugType.ERROR);
        return nil;
    }

    return renderer;
}

sdl_window :: proc(window: ^sdl.Window, renderer: ^sdl.Renderer, update: proc(), render: proc(^sdl.Renderer, ^bool)) {
    defer sdl.DestroyWindow(window);
    defer sdl.DestroyRenderer(renderer);

    start_tick := time.tick_now();
    running := true;

    for (running) {
        duration := time.tick_since(start_tick);
        t := f32(time.duration_seconds(duration));

        if (update != nil) do update();

        event: sdl.Event;
        for (sdl.PollEvent(&event)) {
            #partial switch event.type {
                case .KEYDOWN:
                    #partial switch event.key.keysym.sym {
                        case .ESCAPE:
                            running = false;
                }
                case .QUIT:
                    running = false;
            }
        }

        if (render != nil) do render(renderer, &running);
        else {
            sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255);
            sdl.RenderClear(renderer);
        }

        sdl.RenderPresent(renderer);
    }
}

sdl_color :: proc(color: Color) -> sdl.Color {
    return sdl.Color {color.r, color.g, color.b, color.a};
}

sdl_rect :: proc(renderer: ^sdl.Renderer, rec: rl.Rectangle, color: Color) {
    rect := new(sdl.Rect);
    rect.x = i32(rec.x); rect.y = i32(rec.y); rect.w = i32(rec.width); rect.h = i32(rec.height);
    sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    sdl.RenderFillRect(renderer, rect);
}

sdl_draw_text :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, text: string, #any_int x, y, w, h: i32, color: Color) {
    text_surface := ttf.RenderText_Solid(font, strs.clone_to_cstring(text), sdl_color(color));
    defer sdl.FreeSurface(text_surface);
    text_tex := sdl.CreateTextureFromSurface(renderer, text_surface);
    defer sdl.DestroyTexture(text_tex);

    render_quad := sdl.Rect {x, y, w, h};
    sdl.RenderCopy(renderer, text_tex, nil, &render_quad);
}

sdl_button :: proc(renderer: ^sdl.Renderer, text: string, font: ^ttf.Font, x, y, w, h: f32) -> bool {
    rec := rl.Rectangle {
        x = x,
        y = y,
        width = w,
        height = h,
    };

    mp := sdl_mouse_pos();
    pressed := rl.CheckCollisionPointRec(mp, rec) && sdl_mouse_released(sdl.BUTTON_LMASK);
    held := rl.CheckCollisionPointRec(mp, rec) && sdl_mouse_down(sdl.BUTTON_LMASK);

    sdl_rect(renderer, {rec.x - gui_bezel_size, rec.y - gui_bezel_size, rec.width + gui_bezel_size * 2, rec.height + gui_bezel_size * 2}, gui_darker_color);
    sdl_rect(renderer, {rec.x - gui_bezel_size, rec.y - gui_bezel_size, rec.width + gui_bezel_size, 
            rec.height + gui_bezel_size}, gui_lighter_color);

    if (!held) do sdl_rect(renderer, rec, gui_main_color);
    else do sdl_rect(renderer, rec, gui_accent_color);

    sdl_draw_text(renderer, font, text, i32(rec.x), i32(rec.y), i32(rec.width), i32(rec.height), WHITE);

    return pressed;

}

sdl_key_down :: proc(key: sdl.Scancode) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    return bool(kb_state[key]);
}

sdl_key_pressed :: proc(key: sdl.Scancode) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    @static prev_state: [sdl.NUM_SCANCODES]u8;
    curr_state := kb_state[key];

    if (curr_state == sdl.PRESSED && prev_state[key] == sdl.RELEASED) {
        prev_state[key] = curr_state;
        return true;
    }

    prev_state[key] = curr_state;
    return false;
}

sdl_mouse_down :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    return bool(m_state & button);
}

sdl_mouse_pressed :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & button;

    if (curr_state == 1 && prev_state[button] == 0) {
        prev_state[button] = curr_state;
        return true;
    }

    prev_state[button] = curr_state;
    return false;
}

sdl_mouse_released :: proc(#any_int button: u32) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & button;

    if (curr_state == 0 && prev_state[button] == 1) {
        prev_state[button] = curr_state;
        return true;
    }

    prev_state[button] = curr_state;
    return false;
}

sdl_mouse_pos :: proc() -> Vec2 {
    x, y: i32;
    sdl.GetMouseState(&x, &y);
    return Vec2 {f32(x), f32(y)};
}
