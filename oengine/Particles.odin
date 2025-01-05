package oengine

import rl "vendor:raylib"
import "core:fmt"
import ecs "ecs"
import "core:encoding/json"

ParticleBehaviour :: struct {
    vel, accel, grav: Vec3,
    data: rawptr,
    behave: proc(self: ^ParticleBehaviour, p: ^Particle),
}

Particle :: struct {
    render: proc(self: ^Particle),
    behaviours: [dynamic]ParticleBehaviour,
    tint: Color,
    texture: Texture,
    position: Vec3,
    size: Vec3,
    life_time: f32,
}

Particles :: struct {
    particles: [dynamic]^Particle,
    _removed_particles: [dynamic]int,
    position: Vec3,
    timer: Timer,
}

checkered_image: Texture; 

particle_init :: proc(spawn_pos: Vec3 = {}, test_behaviour: bool = true, s_grav: Vec3 = {0, -9.81, 0}, slf: f32 = 10, color: Color = WHITE) -> ^Particle {
    using res := new(Particle);
    tint = color;
    texture = checkered_image;
    position = spawn_pos;
    size = {0.5, 0.5, 0.5};
    life_time = slf;

    render = proc(using self: ^Particle) {
        rl.DrawBillboard(ecs_world.camera.rl_matrix, texture, position, size.x, tint);
    }

    behaviours = make([dynamic]ParticleBehaviour);

    if (test_behaviour) {    
        append(&behaviours, ParticleBehaviour{
            grav = s_grav,

            behave = proc(using self: ^ParticleBehaviour, p: ^Particle) {
                accel.y = -grav.y;
                vel += accel * rl.GetFrameTime();
                p.position += vel * rl.GetFrameTime(); 
            }
        });
    }

    return res;
}

particle_add_behaviour :: proc(using self: ^Particle, behaviour: ParticleBehaviour) {
    append(&behaviours, behaviour);
}

@(private = "file")
ps_init_all :: proc(using ps: ^Particles) {
    particles = make([dynamic]^Particle);
}

ps_add_particle :: proc(using self: ^Particles, p: ^Particle, delay: f32 = 0) {
    if (!interval(&timer, delay)) do return;

    clone := new_clone(p^);
    clone.position += position;
    append(&particles, clone);
}

ps_init :: proc() -> Particles {
    ps: Particles;

    ps_init_all(&ps);

    return ps;
}

ps_update :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    t, ps := ecs.get_components(ent, Transform, Particles);
    if (is_nil(t, ps)) do return;
    using ps;

    position = t.position;


    for i in 0..<len(particles) {
        p := particles[i];
        p.life_time -= 10 * rl.GetFrameTime();

        if (p.life_time <= 0) do append(&_removed_particles, i);

        for &b in p.behaviours {
            b.behave(&b, p);
        }
    }

    for &p in _removed_particles {
        if (p != -1 && p < len(particles)) { 
            pr := particles[p];
            
            for b in pr.behaviours {
                free(b.data); 
            }

            delete(pr.behaviours);
            free(pr);
            ordered_remove(&particles, p); 
        }
        p = -1;
    }
}

ps_render :: proc(ctx: ^ecs.Context, ent: ^ecs.Entity) {
    ps := ecs.get_component(ent, Particles);
    if (is_nil(ps)) do return;
    using ps;

    for p in particles {
        p->render();
    }
}

ps_parse :: proc(aj: json.Object) -> rawptr {
    
}
