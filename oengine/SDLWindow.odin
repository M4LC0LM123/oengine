package oengine

import "core:fmt"
import "core:time"
import strs "core:strings"
import sdl "vendor:sdl2"

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

sdl_window :: proc(window: ^sdl.Window, renderer: ^sdl.Renderer, update: proc(), render: proc(^sdl.Renderer)) {
    defer sdl.DestroyWindow(window);
    defer sdl.DestroyRenderer(renderer);

    start_tick := time.tick_now();

    loop: for {
        duration := time.tick_since(start_tick);
        t := f32(time.duration_seconds(duration));

        if (update != nil) do update();

        event: sdl.Event;
        for (sdl.PollEvent(&event)) {
            #partial switch event.type {
                case .KEYDOWN:
                    #partial switch event.key.keysym.sym {
                        case .ESCAPE:
                            break loop;
                }
                case .QUIT:
                    break loop;
            }
        }

        if (render != nil) do render(renderer);
        else {
            sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255);
            sdl.RenderClear(renderer);
        }

        sdl.RenderPresent(renderer);
    }
}
