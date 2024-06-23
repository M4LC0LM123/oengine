package oengine

import "core:os"
import "core:fmt"
import rl "vendor:raylib"
import str "core:strings"

window: struct {
    _width, _height: i32,
    _render_width, _render_height: i32,

    _title: string,

    _config_flags: rl.ConfigFlags,
    _trace_log_type: TraceLogType,
    _trace_log_level: rl.TraceLogLevel,

    _exit_key: Key,

    _target_fps: i32,

    mouse_position: Vec2,

    debug_stats: bool,

    target: rl.RenderTexture,
    instance_name: string,
}

w_create :: proc(name: string = "Game") {
    using window;

    _width = 800;
    _height = 600;
    _render_width = 800;
    _render_height = 600;

    _title = "oengine window";

    _config_flags = {rl.ConfigFlag.WINDOW_RESIZABLE};
    w_set_trace_log_type(.USE_OENGINE);
    dbg_log(str_add("Detected os: ", OSTypeStr[int(sys_os())]));
    dbg_logf("Set config flags: ");
    dbg_log(window._config_flags, .EMPTY);

    _exit_key = Key.KEY_NULL;

    _target_fps = 60;

    mouse_position = vec2_zero();

    debug_stats = false;

    rl.SetConfigFlags(_config_flags);
    rl.SetTraceLogLevel(_trace_log_level);
    rl.InitWindow(_width, _height, str.clone_to_cstring(_title));
    if (rl.IsWindowReady()) do dbg_log("Initalized window");
    else do dbg_log("Failed to initialize window", .ERROR);
    exit_key(_exit_key);
    dbg_log(str_add("Set exit key to: ", _exit_key));
    rl.SetTargetFPS(_target_fps);
    rl.InitAudioDevice();
    if (rl.IsAudioDeviceReady()) do dbg_log("Initalized audio device");
    else do dbg_log("Failed to initialize audio device", .ERROR);

    target = rl.LoadRenderTexture(_render_width, _render_height);

    if (target.texture.width <= 0 || target.texture.height <= 0) {
        dbg_log("Failed to load render target, width or height is <= 0", .ERROR);
        return;
    }

    if (rl.IsRenderTextureReady(target)) {
        dbg_log("Loaded render target");
    }

    gui_default_font = rl.GetFontDefault();
    gui_font_size = f32(gui_default_font.baseSize);
    w_set_instance_name(name);
}

w_set_instance_name :: proc(name: string) {
    window.instance_name = name;
    dbg_log(str_add("Set instance name to: ", window.instance_name));
}

w_trace_log_type :: proc() -> TraceLogType {
    return window._trace_log_type;
}

w_set_trace_log_type :: proc(type: TraceLogType) {
    window._trace_log_type = type;

    if (window._trace_log_type == .USE_OENGINE) {
        dbg_log(str_add({"Set trace log type to: ", TRACE_NAMES[int(type)]}));
        w_set_trace_log_level(rl.TraceLogLevel.NONE);
        return;
    }

    w_set_trace_log_level(rl.TraceLogLevel.ALL);

    dbg_log(str_add({"Set trace log type to: ", DEBUG_TYPE_NAMES[int(type)]}));
}

w_render_width :: proc() -> i32 {
    return window._render_width;
}

w_set_render_width :: proc(w: i32) {
    window._render_width = w;
    w_reload_target();
    dbg_log(str_add("Set render width: ", window._render_width));
}

w_render_height :: proc() -> i32 {
    return window._render_height;
}

w_set_render_height :: proc(h: i32) {
    window._render_height = h;
    w_reload_target();
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_set_resolution :: proc(w, h: i32) {
    window._render_width = w;
    window._render_height = h;

    w_reload_target();
    dbg_log(str_add("Set render width: ", window._render_width));
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_width :: proc() -> i32 {
    return window._width;
}

w_set_width :: proc(w: i32) {
    window._width = w;
    w_reload_window();
    dbg_log(str_add("Set render width: ", window._render_width));
}

w_height :: proc() -> i32 {
    return window._height;
}

w_set_height :: proc(h: i32) {
    window._height = h;
    w_reload_window();
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_set_size :: proc(w, h: i32) {
    window._width = w;
    window._height = h;

    w_reload_window();
    dbg_log(str_add("Set render width: ", window._render_width));
    dbg_log(str_add("Set render height: ", window._render_height));
}

w_config_flags :: proc() -> rl.ConfigFlags {
    return window._config_flags;
}

w_set_config_flags :: proc(flags: rl.ConfigFlags) {
    window._config_flags = flags;
    rl.SetConfigFlags(window._config_flags);
    dbg_logf("Set config flags: ");
    dbg_log(window._config_flags, .EMPTY);
}

w_trace_log_level :: proc() -> rl.TraceLogLevel {
    return window._trace_log_level;
}

w_set_trace_log_level :: proc(level: rl.TraceLogLevel) {
    window._trace_log_level = level;
    rl.SetTraceLogLevel(window._trace_log_level);
    dbg_logf("Set trace log level to: ");
    dbg_log(window._trace_log_level, .EMPTY);
}

w_title :: proc() -> string {
    return window._title;
}

w_set_title :: proc(t: string) {
    window._title = t;
    rl.SetWindowTitle(str.clone_to_cstring(window._title));
    dbg_log(str_add({"Set title to: ", window._title}));
}

w_exit_key :: proc() -> Key {
    return window._exit_key;
}

w_set_exit_key :: proc(key: Key) {
    window._exit_key = key;
    exit_key(window._exit_key);
    dbg_log(str_add("Set exit key to: ", window._exit_key));
}

w_target_fps :: proc() -> i32 {
    return window._target_fps;
}

w_set_target_fps :: proc(fps: i32) {
    window._target_fps = fps;
    rl.SetTargetFPS(window._target_fps);
    dbg_log(str_add("Set target fps to: ", window._target_fps));
}

w_tick :: proc() -> bool {
    using window;

    if (rl.IsWindowResized()) {
        _width = rl.GetScreenWidth();
        _height = rl.GetScreenHeight();
    }
    
    mouse_position.x = f32(rl.GetMouseX()) * (f32(_render_width) / f32(_width));
    mouse_position.y = f32(rl.GetMouseY()) * (f32(_render_height) / f32(_height));

    gui_cursor_timer += rl.GetFrameTime() * 2;

    return !rl.WindowShouldClose();
}

w_begin_render :: proc() {
    rl.BeginTextureMode(window.target);
}

w_end_render :: proc() {
    using window;

    if (debug_stats) {
        rl.DrawText(str.clone_to_cstring(str_add("fps: ", rl.GetFPS())), 10, 10, 16, rl.YELLOW);
        rl.DrawText(str.clone_to_cstring(str_add("dt: ", rl.GetFrameTime())), 10, 30, 16, rl.YELLOW);
        rl.DrawText(str.clone_to_cstring(str_add("time: ", rl.GetTime())), 10, 50, 16, rl.YELLOW);
        rl.DrawText(str.clone_to_cstring(str_add("ents: ", len(ecs_world.ents))), 10, 70, 16, rl.YELLOW);
        rl.DrawText(str.clone_to_cstring(str_add("rbs: ", len(ecs_world.physics.bodies))), 10, 90, 16, rl.YELLOW)
        rl.DrawText(str.clone_to_cstring(str_add("lights: ", light_count)), 10, 110, 16, rl.YELLOW);
    }
    
    rl.EndTextureMode();
    
    rl.BeginDrawing();
    
    rl.DrawTexturePro(target.texture, {0, 0, f32(target.texture.width), f32(-target.texture.height)}, 
        {0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}, vec2_zero(), 0, rl.WHITE);
    
    rl.EndDrawing();
}

w_close :: proc() {
    delete(gui.windows);

    dbg_log(" ");
    dbg_log("Closing...");

    rl.CloseAudioDevice();
    dbg_log("Closed audio device");

    rl.CloseWindow();
    dbg_log("Closed window");
}

w_pos :: proc() -> Vec2 {
    if (sys_os() == .Windows) do return rl.GetWindowPosition();

    return vec2_zero();
}

@(private = "file")
prev_w_pos := w_pos();

w_transform_changed :: proc() -> bool {
    if (w_pos() != prev_w_pos) {
        prev_w_pos = w_pos();
        return true;
    }

    return rl.IsWindowResized();
}

@(private = "file")
w_reload_target :: proc() {
    window.target = rl.LoadRenderTexture(window._render_width, window._render_height);
}

@(private = "file")
w_reload_window :: proc() {
    rl.SetWindowSize(window._width, window._height);
}
