package oengine

import "core:math"
import "core:fmt"
import rl "vendor:raylib"

MASS_SCALAR :: 100
MAX_VEL :: 50

MAX_HEIGHTMAP_SIZE :: 64
MAX_HEIGHTMAP_SIZE_S :: MAX_HEIGHTMAP_SIZE * MAX_HEIGHTMAP_SIZE

HeightMap :: [MAX_HEIGHTMAP_SIZE][MAX_HEIGHTMAP_SIZE]f32
HEIGHTMAP_SCALE :: 1

Slope :: [2][2]f32

RigidBody :: struct {
    id: u32,
    transform: Transform,
    starting: Transform,

    acceleration, velocity, force: Vec3,
    mass, restitution, friction: f32,

    shape: ShapeType,

    shape_variant: union {
        u8,         // primitive
        HeightMap,
        Slope,
    },

    is_static: bool,

    joints: [dynamic]u32,
}

rb_init :: proc {
    rb_init_def,
    rb_init_terrain,
    rb_init_slope,
}

@(private = "file")
rb_init_all :: proc(using rb: ^RigidBody, s_density, s_restitution: f32, s_static: bool, s_shape: ShapeType) {
    transform = {
        vec3_zero(),
        vec3_zero(),
        vec3_one(),
    };

    starting = transform;
    
    acceleration = {};
    velocity = {};
    force = {};

    vol: f32;
    #partial switch s_shape {
        case .BOX, .HEIGHTMAP:
            vol = transform.scale.x * transform.scale.y * transform.scale.z;
        case .SPHERE:
            vol = (4.0 / 3.0) * math.pow(transform.scale.x * 0.5, 3) * math.PI;
        case .CAPSULE:
            vol = (4.0 / 3.0 * transform.scale.x * 0.5 + transform.scale.y) * math.pow(transform.scale.x * 0.5, 3) * math.PI
        case .SLOPE:
            vol = (transform.scale.x * transform.scale.y * transform.scale.z) * 0.5;
    }

    mass = vol * s_density / MASS_SCALAR;
    restitution = s_restitution;
    shape = s_shape;

    is_static = s_static;
    friction = 0.7;

    shape_variant = 0;

    id = u32(len(&ecs_world.physics.bodies));
    joints = make([dynamic]u32);
    append(&ecs_world.physics.bodies, rb);
}

rb_init_def :: proc(s_starting: Transform, s_density, s_restitution: f32, s_static: bool, s_shape: ShapeType) -> ^Component {
    using component := new(Component);

    component.variant = new(RigidBody);
    rb_init_all(component.variant.(^RigidBody), s_density, s_restitution, s_static, s_shape);
    component.variant.(^RigidBody).starting = s_starting;

    update = rb_update;
    render = rb_render;

    return component;
}

rb_init_terrain :: proc(s_starting: Transform, s_density, s_restitution: f32, s_heightmap: HeightMap) -> ^Component {
    using component := new(Component);

    component.variant = new(RigidBody);
    rb_init_all(component.variant.(^RigidBody), s_density, s_restitution, true, ShapeType.HEIGHTMAP);
    c_variant(component, ^RigidBody).shape_variant = s_heightmap;
    component.variant.(^RigidBody).starting = s_starting;

    update = rb_update;
    render = rb_render;

    return component;
}

rb_init_slope :: proc(s_starting: Transform, s_density, s_restitution: f32, s_slope: Slope, reverse: bool = false) -> ^Component {
    using component := new(Component);

    component.variant = new(RigidBody);
    rb_init_all(component.variant.(^RigidBody), s_density, s_restitution, true, ShapeType.SLOPE);
    c_variant(component, ^RigidBody).shape_variant = s_slope;
    component.variant.(^RigidBody).starting = s_starting;

    if (reverse) {
        append(&ecs_world.physics.reverse_slopes, component.variant.(^RigidBody).id);
    }

    update = rb_update;
    render = rb_render;

    return component;
}

rb_starting_transform :: proc(using self: ^RigidBody, trans: Transform) {
    transform = trans;
    starting = transform;
}

@(private = "package")
rb_fixed_update :: proc(using self: ^RigidBody, dt: f32) {
    if (is_static) do return;

    acceleration.y = -ecs_world.physics.gravity.y;

    velocity.x = math.clamp(velocity.x, -MAX_VEL, MAX_VEL);
    velocity.y = math.clamp(velocity.y, -MAX_VEL, MAX_VEL);
    velocity.z = math.clamp(velocity.z, -MAX_VEL, MAX_VEL);

    velocity += acceleration * dt * DAMPING_VEL_FACTOR;
    transform.position += velocity * dt;
    force = acceleration * mass;
}

rb_update :: proc(component: ^Component, ent: ^Entity) {
    using self := component.variant.(^RigidBody);
    ent.transform = transform;
}

rb_render :: proc(component: ^Component) {
    using self := component.variant.(^RigidBody);

    if (!PHYS_DEBUG) do return;

    if (shape == .BOX) {
        draw_cube_wireframe(transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    } else if (shape == .SPHERE) {
        draw_sphere_wireframe(transform.position, transform.rotation, transform.scale.x * 0.5, PHYS_DEBUG_COLOR);
    } else if (shape == .CAPSULE) {
        draw_capsule_wireframe(transform.position, transform.rotation, transform.scale.x * 0.5, transform.scale.y * 0.5, PHYS_DEBUG_COLOR);
    } else if (shape == .SLOPE) {
        draw_slope_wireframe(shape_variant.(Slope), transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    }
    
    //else if (shape == .HEIGHTMAP) {
    //     draw_heightmap_wireframe(shape_variant.(HeightMap), transform.position, transform.rotation, transform.scale, PHYS_DEBUG_COLOR);
    // }
}

rb_clear :: proc(using self: ^RigidBody) {
    acceleration = {};
    velocity = {};
    force = {};
}

rb_inverse_mass :: proc(using self: RigidBody) -> f32 {
    return 1 / mass;
}

rb_apply_impulse :: proc(using self: ^RigidBody, s_impulse: Vec3) {
    if (is_static) do return;

    delta := s_impulse * rb_inverse_mass(self^);
    velocity += delta * ecs_world.physics.delta_time;
}

rb_apply_force :: proc(using self: ^RigidBody, s_force: Vec3) {
    if (is_static) do return;

    add := s_force * rb_inverse_mass(self^);
    acceleration += add * ecs_world.physics.delta_time;
}

rb_shape :: proc(using self: ^RigidBody, $T: typeid) -> T {
    return shape_variant.(T);
}

rb_get_height_terrain_at :: proc(using self: ^RigidBody, x, z: f32) -> f32 {
    terrain_x := x - transform.position.x;
    terrain_z := z - transform.position.z;

    grid_x := i32(math.floor(terrain_x / HEIGHTMAP_SCALE));
    grid_z := i32(math.floor(terrain_z / HEIGHTMAP_SCALE));

    if (grid_x >= i32(len(shape_variant.(HeightMap))) - 1 || 
        grid_z >= i32(len(shape_variant.(HeightMap))) - 1 ||
        grid_x < 0 || grid_z < 0) {
        return 0;
    }

    x_coord := (i32(terrain_x) % HEIGHTMAP_SCALE) / HEIGHTMAP_SCALE;
    z_coord := (i32(terrain_z) % HEIGHTMAP_SCALE) / HEIGHTMAP_SCALE;
    res: f32;

    if (x_coord <= (1 - z_coord)) {
        res = barry_centric(
            {0, shape_variant.(HeightMap)[grid_x][grid_z], 0},
            {1, shape_variant.(HeightMap)[grid_x + 1][grid_z], 0},
            {1, shape_variant.(HeightMap)[grid_x][grid_z + 1], 1},
            {f32(x_coord), f32(z_coord)},
        );
    } else {
        res = barry_centric(
            {1, shape_variant.(HeightMap)[grid_x + 1][grid_z], 0},
            {1, shape_variant.(HeightMap)[grid_x + 1][grid_z + 1], 1},
            {0, shape_variant.(HeightMap)[grid_x][grid_z + 1], 1},
            {f32(x_coord), f32(z_coord)},
        );
    }

    return res;
}

rb_slope_get_height_at :: proc(slope: Slope, s_x: f32) -> f32{
    x1 := slope[0][0];
    y1 := slope[0][1];

    x2 := slope[1][0];
    y2 := slope[1][1];

    x := -s_x;

    if (x1 == x2 && x1 > y1 && x2 > y2) {
        x1 = slope[1][0];
        y1 = slope[0][0];
        
        x2 = slope[1][1];
    }

    if (x1 == x2 && x1 < y1 && x2 < y2) {
        y1 = slope[1][0];
        
        x2 = slope[1][1];
        y2 = slope[0][1];
    }

    if (x1 == y1 && x1 > x2 && y1 > y2) {
        x = s_x;
    }

    t := (x - x1) / (x2 - x1);
    h := y1 + t * (y2 - y1);
    return h;
}

rb_slope_max :: proc(slope: Slope) -> f32 {
    maxi := slope[0][0];

    if (slope[0][1] > maxi) {
        maxi = slope[0][1];
    } else if (slope[1][0] > maxi) {
        maxi = slope[1][0];
    } else if (slope[1][1] > maxi) {
        maxi = slope[1][1];
    }
    
    return maxi;
}

SlopeOrientation :: enum {
    X,
    Z
}

slope_orientation :: proc(slope: Slope) -> SlopeOrientation {
    return SlopeOrientation(slope[0][0] == slope[1][0]);
}

slope_negative :: proc(slope: Slope) -> bool {
    return (slope[0][0] == slope[1][0] && 
            slope[0][0] > slope[0][1]) ||
            (slope[0][0] == slope[0][1] &&
            slope[0][0] > slope[1][0]);
}

rb_slope_orientation :: proc(using self: ^RigidBody) -> SlopeOrientation {
    return SlopeOrientation(shape_variant.(Slope)[0][0] == shape_variant.(Slope)[1][0]);
}

rb_slope_negative :: proc(using self: ^RigidBody) -> bool {
    return (shape_variant.(Slope)[0][0] == shape_variant.(Slope)[1][0] && 
            shape_variant.(Slope)[0][0] > shape_variant.(Slope)[0][1]) ||
            (shape_variant.(Slope)[0][0] == shape_variant.(Slope)[0][1] &&
            shape_variant.(Slope)[0][0] > shape_variant.(Slope)[1][0]);
}