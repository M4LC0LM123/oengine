package oengine

import sdl "vendor:sdl2"
import "core:fmt"

Key :: sdl.Keycode

// keyboard
key_pressed :: proc(keycode: Key) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    @static prev_state: [sdl.NUM_SCANCODES]u8;
    key := sdl.GetScancodeFromKey(keycode);
    curr_state := kb_state[key];

    if (curr_state == sdl.PRESSED && prev_state[key] == sdl.RELEASED) {
        prev_state[key] = curr_state;
        return true;
    }

    prev_state[key] = curr_state;
    return false;
}

key_down :: proc(key: Key) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    scancode := sdl.GetScancodeFromKey(key);
    return bool(kb_state[scancode]);
}

key_released :: proc(keycode: Key) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    @static prev_state: [sdl.NUM_SCANCODES]u8;
    key := sdl.GetScancodeFromKey(keycode);
    curr_state := kb_state[key];

    if (curr_state == sdl.RELEASED && prev_state[key] == sdl.PRESSED) {
        prev_state[key] = curr_state;
        return true;
    }

    prev_state[key] = curr_state;
    return false;
}

key_up :: proc(key: Key) -> bool {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    scancode := sdl.GetScancodeFromKey(key);
    return !bool(kb_state[scancode]);
}

keycode_pressed :: proc() -> Key {
    @static kb_state: [^]u8;
    kb_state = sdl.GetKeyboardState(nil);

    @static prev_state: [sdl.NUM_SCANCODES]u8;

    for i in 0..<sdl.NUM_SCANCODES {
        if (kb_state[i] == sdl.PRESSED && prev_state[i] == sdl.RELEASED) {
            prev_state[i] = kb_state[i];
            return sdl.GetKeyFromScancode(sdl.Scancode(i));
        }

        prev_state[i] = kb_state[i];
    }

    return Key.UNKNOWN;
}

char_pressed :: proc() -> char {
    return char(keycode_pressed());
}

exit_key :: proc(key: Key) {
    window._exit_key = key;
}

Mouse :: enum u32 {
	LEFT    = 1 << 0,                      // Mouse button left
	RIGHT   = 1 << 2,                      // Mouse button right
	MIDDLE  = 1 << 1,                      // Mouse button middle (pressed wheel)
}

// mouse
mouse_pressed :: proc(button: Mouse) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & u32(button);

    if (curr_state > 0 && prev_state[u32(button)] == 0) {
        prev_state[u32(button)] = curr_state;
        return true;
    }

    prev_state[u32(button)] = curr_state;
    return false;
}

mouse_down :: proc(button: Mouse) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    return bool(m_state & u32(button));
}

mouse_released :: proc(button: Mouse) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    @static prev_state: [sdl.BUTTON_X2MASK + 1]u32;
    curr_state := m_state & u32(button);

    if (curr_state == 0 && prev_state[u32(button)] > 0) {
        prev_state[u32(button)] = curr_state;
        return true;
    }

    prev_state[u32(button)] = curr_state;
    return false;
}

mouse_up :: proc(button: Mouse) -> bool {
    @static m_state: u32;
    m_state = sdl.GetMouseState(nil, nil);

    return !bool(m_state & u32(button));
}

mouse_pos :: proc() -> Vec2 {
    x, y: i32;
    sdl.GetMouseState(&x, &y);
    return Vec2 {f32(x), f32(y)};
}

mouse_global_pos :: proc() -> Vec2 {
    x, y: i32;
    sdl.GetGlobalMouseState(&x, &y);
    return Vec2 {f32(x), f32(y)};
}

set_mouse_pos :: proc(v: Vec2) {
    sdl.WarpMouseInWindow(window._handle, i32(v.x), i32(v.y));
}

show_cursor :: proc() -> i32{
    return sdl.ShowCursor(sdl.ENABLE);
}

hide_cursor :: proc() -> i32 {
    return sdl.ShowCursor(sdl.DISABLE);
}
