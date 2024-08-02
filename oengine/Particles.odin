package oengine

import rl "vendor:raylib"
import "core:fmt"

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
}

Particles :: struct {
    particles: [dynamic]^Particle,
    position: Vec3,
    timer: Timer,
}

particle_init :: proc(spawn_pos: Vec3 = {}, test_behaviour: bool = true, s_grav: Vec3 = {0, -9.81, 0}) -> ^Particle {
    using res := new(Particle);
    tint = WHITE;
    texture = load_texture(rl.LoadTextureFromImage(rl.GenImageChecked(4, 4, 1, 1, WHITE, BLACK)));
    position = spawn_pos;
    size = {0.5, 0.5, 0.5};

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

ps_init :: proc() -> ^Component {
    using component := new(Component);

    variant = new(Particles);
    ps_init_all(variant.(^Particles));

    update = ps_update;
    render = ps_render;

    return component;
}

ps_update :: proc(component: ^Component, ent: ^Entity) {
    using self := component.variant.(^Particles);
    position = ent.transform.position;

    for p in particles {
        for &b in p.behaviours {
            b.behave(&b, p);
        }
    }
}

ps_render :: proc(component: ^Component) {
    using self := component.variant.(^Particles);

    for p in particles {
        p->render();
    }
}

