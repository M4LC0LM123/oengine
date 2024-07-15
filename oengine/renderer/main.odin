package rendering

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

import oe "../../oengine"

main :: proc() {
	WINDOW_WIDTH  :: 800
	WINDOW_HEIGHT :: 600
	
	window := SDL.CreateWindow("Odin SDL2 Demo", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL})
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)
	
	gl_context := SDL.GL_CreateContext(window)
	SDL.GL_MakeCurrent(window, gl_context)
	// load the OpenGL procedures once an OpenGL context has been established
	gl.load_up_to(3, 3, SDL.gl_set_proc_address)
	
	// high precision timer
	start_tick := time.tick_now()

    renderer: Renderer;
    renderer_init(&renderer);
    defer render_free(&renderer);
	
	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))
		
		// event polling
		event: SDL.Event
		for SDL.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				}
			case .QUIT:
				// labelled control flow
				break loop
			}
		}
	
        renderer.view = oe.mat4_look_at({0, 0, 5}, {}, {0, 1, 0});

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)

        render_begin(&renderer);

        renderer_triangle(&renderer, 
            {0, 1, 0}, {-1, -1, 0}, {1, -1, 0}, 
            oe.RED, oe.GREEN, oe.BLUE,
            {}, {}, {}, renderer_get_white_tex()
        );

        renderer_end(&renderer);
		
		SDL.GL_SwapWindow(window)		
	}
}

