package oengine

import "core:os"
import "core:fmt"
import str "core:strings"
import sdl "vendor:sdl2"
import mix "vendor:sdl2/mixer"
import "core:time"
import "gl"

window: struct {
    _width, _height: i32,
    _render_width, _render_height: i32,

    _title: string,

    _handle: ^sdl.Window,
    now, last: u64,
    _delta: f32,
    _frame_count, _last_time, _last_frame, _fps: i32,
    _running: bool,
    _resizable: bool,
    _vsync: bool,

    _exit_key: Key,

    _target_fps: i32,

    _fbo, _target: u32,

    mouse_position: Vec2, // mouse position relative to screen not world

    debug_stats: bool,

    instance_name: string,
}

w_create :: proc(name: string = "Game") {
    using window;

    _width = 800;
    _height = 600;
    _render_width = 800;
    _render_height = 600;

    _title = "oengine window";

    dbg_log(str_add("Detected os: ", OSTypeStr[int(sys_os())]));

    _exit_key = Key.UNKNOWN;

    w_set_target_fps(60);

    mouse_position = vec2_zero();
    _running = true;
    _resizable = true;

    debug_stats = false;

    now = sdl.GetPerformanceCounter();

    if (sdl.Init(sdl.INIT_EVERYTHING) < 0) {
        dbg_log("Failed to sdl2", .ERROR);
    } else do dbg_log("Initialized sdl2");

    _handle = sdl.CreateWindow(
        str.clone_to_cstring(_title), sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height, {.OPENGL}
    );

    sdl.SetWindowResizable(_handle, sdl.bool(_resizable));

    if (_handle != nil) {
        dbg_log("Initalized window");
    } else do dbg_log("Failed to initialize window", .ERROR);

    sdl.GL_MakeCurrent(_handle, sdl.GL_CreateContext(_handle));
    gl.load_gl(sdl.gl_set_proc_address);

    if (mix.OpenAudio(9600, mix.DEFAULT_FORMAT, mix.DEFAULT_CHANNELS, 1024) < 0) {
        dbg_log("Failed to initialize sdl mixer", .ERROR);
    } else do dbg_log("Initialized sdl mixer");

    dbg_log(str_add("Set exit key to: ", _exit_key));
    // create_fbo(&_fbo, &_target, _render_width, _render_height);
}

w_handle :: proc() -> ^sdl.Window {
    return window._handle;
}

w_delta_time :: proc() -> f32 {
    return window._delta;
}

w_set_instance_name :: proc(name: string) {
    window.instance_name = name;
    dbg_log(str_add("Set instance name to: ", window.instance_name));
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

w_title :: proc() -> string {
    return window._title;
}

w_set_title :: proc(t: string) {
    window._title = t;
    sdl.SetWindowTitle(window._handle, str.clone_to_cstring(window._title));
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
    dbg_log(str_add("Set target fps to: ", window._target_fps));
}

w_get_fps :: proc() -> i32 {
    return window._fps;
}

w_set_vsync :: proc(v: bool) {
    window._vsync = v;
}

w_tick :: proc() -> bool {
    using window;

    // if (rl.IsWindowResized()) {
    //     _width = rl.GetScreenWidth();
    //     _height = rl.GetScreenHeight();
    // }
   
    mp := mouse_pos();
    mouse_position.x = f32(mp.x) * (f32(_render_width) / f32(_width));
    mouse_position.y = f32(mp.y) * (f32(_render_height) / f32(_height));
    //
    // gui_cursor_timer += rl.GetFrameTime() * 2;

    // console_update();


    last = now;
    now = sdl.GetPerformanceCounter();

    _delta = f32((now - last)) / f32(sdl.GetPerformanceFrequency());

    _last_frame = i32(sdl.GetTicks());
    if (_last_frame >= (_last_time + 1000)) {
        _last_time = _last_frame;
        _fps = _frame_count;
        _frame_count = 0;
    }

    event: sdl.Event;
    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .QUIT: _running = false;
            case .WINDOWEVENT:
                #partial switch event.window.event {
                    case .RESIZED:
                        sdl.GetWindowSize(_handle, &_width, &_height);
                        gl.Viewport(0, 0, _width, _height);
                }
            case .KEYDOWN:
                #partial switch event.key.keysym.sym {
                    case _exit_key: _running = false;
                }
        }
    }

    return _running;
}

w_begin_render :: proc() {
    // begin_fbo(window._fbo, window._render_width, window._render_height);
}

w_end_render :: proc() {
    using window;

    // end_fbo(_target);

    sdl.GL_SetSwapInterval(i32(_vsync));
    sdl.GL_SwapWindow(_handle);

    _frame_count += 1;
    _timer_fps := i32(sdl.GetTicks()) - _last_frame;
    if (_timer_fps < 1000 / _target_fps) {
        sdl.Delay(u32(1000 / _target_fps - _timer_fps));
    }
}

w_close :: proc() {
    using window;
    delete(gui.windows);

    dbg_log(" ");
    dbg_log("Closing...");

    mix.CloseAudio();
    dbg_log("Closed audio device");

    sdl.DestroyWindow(_handle);
    dbg_log("Closed window");
}

w_pos :: proc() -> Vec2 {
    x, y: i32;
    sdl.GetWindowPosition(window._handle, &x, &y);

    return Vec2 {f32(x), f32(y)};
}

@(private = "file")
prev_w_pos := w_pos();

w_transform_changed :: proc() -> bool {
    if (w_pos() != prev_w_pos) {
        prev_w_pos = w_pos();
        return true;
    }

    return false;
}

@(private)
w_reload_target :: proc() {
    // window.target = rl.LoadRenderTexture(window._render_width, window._render_height);
}

@(private = "file")
w_reload_window :: proc() {
    sdl.SetWindowSize(window._handle, window._width, window._height);
}

@(private = "file")
create_fbo :: proc(fbo, texture: ^u32, w, h: i32) {
    gl.GenFramebuffers(1, fbo);
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo^);

    gl.GenTextures(1, texture);
    gl.BindTexture(gl.TEXTURE_2D, texture^);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, w, h, 0, gl.RGB, gl.UNSIGNED_BYTE, nil);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture^, 0);

    if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
        dbg_log("Failed to create framebuffer", .ERROR);
    } else do dbg_log("Created framebuffer");

    gl.BindFramebuffer(gl.FRAMEBUFFER, 0);
}

@(private = "file")
begin_fbo :: proc(fbo: u32, w, h: i32) {
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo);
    gl.Viewport(0, 0, w, h);
}

@(private = "file")
end_fbo :: proc(texture: u32) {
    using window;
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0);
    gl.Viewport(0, 0, _width, _height);
    gl.ClearColor(0.0, 0.0, 0.0, 1.0); // Clear to black
    gl.Clear(gl.COLOR_BUFFER_BIT);
    render_fbo(_target, _width, _height);
}

@(private = "file")
render_fbo :: proc(texture: u32, w, h: i32) {
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.Enable(gl.TEXTURE_2D);

    gl.Color3f(1, 1, 1);
    gl.Begin(gl.QUADS);

    gl.TexCoord2f(0.0, 0.0); gl.Vertex2f(-1.0, -1.0);
    gl.TexCoord2f(1.0, 0.0); gl.Vertex2f( 1.0, -1.0);
    gl.TexCoord2f(1.0, 1.0); gl.Vertex2f( 1.0,  1.0);
    gl.TexCoord2f(0.0, 1.0); gl.Vertex2f(-1.0,  1.0);

    gl.End();

    gl.Disable(gl.TEXTURE_2D);
    gl.BindTexture(gl.TEXTURE_2D, 0);
}
