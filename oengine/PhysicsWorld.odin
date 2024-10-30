package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"
import rl "vendor:raylib"
import "fa"

DEFAULT_RESTITUTION :: 0.5
COLLISION_MASK_SIZE :: 10
DAMPING_VEL_FACTOR :: 0.994

MAX_RBS :: 1024
MAX_JOINTS :: 1024
MAX_MSCS :: 64

TriangleCollider :: struct {
    using pts: [3]Vec3,
    color: Color,
    texture_tag: string,
    mesh: rl.Mesh,
    rot: i32,
    is_lit: bool,
    use_fog: bool,
}

PhysicsWorld :: struct {
    bodies: fa.FixedArray(^RigidBody, MAX_RBS),
    reverse_slopes: [dynamic]u32,
    joints: fa.FixedArray(^Joint, MAX_JOINTS),
    mscs: fa.FixedArray(^MSCObject, MAX_MSCS),
    tree: OcTree,

    gravity: Vec3,
    delta_time: f32,
    iterations: i32,
}

pw_init :: proc(using self: ^PhysicsWorld, s_gravity: Vec3, s_iter: i32 = 8) {
    bodies = fa.fixed_array(^RigidBody, MAX_RBS);
    joints = fa.fixed_array(^Joint, MAX_JOINTS);
    mscs = fa.fixed_array(^MSCObject, MAX_MSCS);
    tree = oct_init(0, {0, 0, 0, 1000, 1000, 1000});

    gravity = s_gravity;
    iterations = s_iter;
}

pw_update :: proc(using self: ^PhysicsWorld, dt: f32) {
    delta_time = dt;

    for n: i32; n < iterations; n += 1 {
        // oct_clear(&tree);
        
        // for body in bodies {
        //     oct_insert(&tree, body);
        // }

        for i := 0; i < fa.range(bodies); i += 1 {
            rb := bodies.data[i];
            rb_fixed_update(rb, delta_time / f32(iterations));

            for i in 0..<fa.range(mscs) {
                msc := mscs.data[i];
                if (!aabb_collision(msc._aabb, trans_to_aabb(rb.transform))) {
                    continue;
                }

                if (rb.is_static) do continue;

                for tri in msc.tris {
                    resolve_tri_collision(rb, tri);
                }
            }

            for j := i + 1; j < fa.range(bodies); j += 1 {
                rb2 := bodies.data[j];

                if (ignored(rb, rb2)) do continue;
                if (!collision_transforms(rb.transform, rb2.transform)) do continue;

                if (rb.shape == ShapeType.HEIGHTMAP) {
                    resolve_heightmap_collision(rb, rb2);
                } else if (rb2.shape == ShapeType.HEIGHTMAP) {
                    resolve_heightmap_collision(rb2, rb);
                } else if (rb.shape == ShapeType.SLOPE) {
                    resolve_slope_collision(self, rb, rb2);
                } else if (rb2.shape == ShapeType.SLOPE) {
                    resolve_slope_collision(self, rb2, rb);
                } else {
                    resolve_aabb_collision(self, rb, rb2);
                }
            }

            // potential := oct_retrieve(&tree, {
            //     rb.transform.position.x - 2.5,
            //     rb.transform.position.y - 2.5,
            //     rb.transform.position.z - 2.5,
            //     rb.transform.scale.x + 5,
            //     rb.transform.scale.y + 5,
            //     rb.transform.scale.z + 5,
            // });

            // for rb2 in potential {
            //     if (ignored(rb, rb2)) do continue;
            //     if (!collision_transforms(rb.transform, rb2.transform)) do continue;

            //     if (rb.shape == ShapeType.HEIGHTMAP) {
            //         resolve_heightmap_collision(rb, rb2);
            //     } else if (rb2.shape == ShapeType.HEIGHTMAP) {
            //         resolve_heightmap_collision(rb2, rb);
            //     } else if (rb.shape == ShapeType.SLOPE) {
            //         resolve_slope_collision(self, rb, rb2);
            //     } else if (rb2.shape == ShapeType.SLOPE) {
            //         resolve_slope_collision(self, rb2, rb);
            //     } else {
            //         resolve_aabb_collision(self, rb, rb2);
            //     }
            // }
        }

        for i in 0..<fa.range(joints) {
            joint := joints.data[i];
            joint.update(joint);
        }
    }
}

pw_deinit :: proc(using self: ^PhysicsWorld) {
    for i in 0..<fa.range(joints) {
        joint := joints.data[i];
        free(joint);
    }

    for i in 0..<fa.range(bodies) {
        free(bodies.data[i]);
    }

    for i in 0..<fa.range(mscs) {
        free(mscs.data[i]);
    }
}

@(private = "file")
ignored :: proc(rb, rb2: ^RigidBody) -> bool {
    return rb.is_static && rb2.is_static ||
           rb.shape == ShapeType.HEIGHTMAP && rb2.shape == ShapeType.HEIGHTMAP ||
           rb.shape == ShapeType.SLOPE && rb2.shape == ShapeType.SLOPE ||
           rb.id == rb2.id ||
           !compare_masks(rb.collision_mask, rb2.collision_mask);
}

@(private = "file") 
resolve_heightmap_collision :: proc(rb, rb2: ^RigidBody) {
    terrain_height := rb_get_height_terrain_at(rb, rb2.transform.position.x, rb2.transform.position.z);
    if (rb2.transform.position.y < terrain_height * HEIGHTMAP_SCALE) {
        rb2.transform.position.y = terrain_height * HEIGHTMAP_SCALE;
    }
}

@(private = "file")
resolve_slope_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody) { // rb is the slope rb2 is something else
    collision, height := collision_slope(rb.shape_variant.(Slope), rb.transform, rb2.transform);

    orientation_check := (rb2.transform.position.z < rb.transform.position.z - rb.transform.scale.z * 0.5) ||
    (rb2.transform.position.z > rb.transform.position.z + rb.transform.scale.z * 0.5);

    if (rb_slope_orientation(rb) == .Z) {
        orientation_check = (rb2.transform.position.x < rb.transform.position.x - rb.transform.scale.x * 0.5) ||
        (rb2.transform.position.x > rb.transform.position.x + rb.transform.scale.x * 0.5);
    }

    if (orientation_check) {
        resolve_slope_side_collision(self, rb, rb2, height);
    }

    coll_transform := Transform {
        position = rb.transform.position,
        rotation = rb.transform.rotation,
        scale = rb.transform.scale - 0.5,
    };
    if (collision && collision_transforms(coll_transform, rb2.transform)) {
        reverse := false
        for i in reverse_slopes {
            if (rb.id == i) {
                reverse = true;
                break;
            }
        }

        if (reverse) {
            if (rb2.transform.position.y + rb2.transform.scale.y > height) {
                rb2.transform.position.y = height - rb2.transform.scale.y; 
            }
        } else {
            rb2.transform.position.y = height + rb2.transform.scale.y * 0.5;
        }
    }
}

@(private = "file")
resolve_slope_side_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody, height: f32) {
    contact: CollisionInfo;
    if (collision_transforms(rb2.transform, rb.transform, &contact)) {
        contact.point = vec3_lerp(rb2.transform.position, rb.transform.position, 0.5);

        if (rb2.transform.position.y - rb2.transform.scale.y * 0.5 < height) {
            resolve_collision(rb2, contact.normal, contact.depth);
            resolve_joints(self, rb2, contact.normal, contact.depth); 
        }
    }
}

@(private = "file")
resolve_aabb_collision :: proc(using self: ^PhysicsWorld, rb, rb2: ^RigidBody) {
    contact: CollisionInfo;
    if (collision_transforms(rb.transform, rb2.transform, &contact)) {
        contact.point = vec3_lerp(rb.transform.position, rb2.transform.position, 0.5);

        if (rb2.is_static) {
            resolve_collision(rb, contact.normal, contact.depth);
            resolve_joints(self, rb, contact.normal, contact.depth); 
        } else if (rb.is_static) {
            resolve_collision(rb2, contact.normal, -contact.depth);
            resolve_joints(self, rb2, contact.normal, -contact.depth);
        } else {
            if (len(rb.joints) != 0) {
                for j in rb.joints {
                    if (joints.data[j].variant.(^FixedJoint).child.id == rb2.id || 
                        joints.data[j].variant.(^FixedJoint).parent.id == rb2.id) {
                        return;
                    }
                }
            }

            resolve_collision(rb, contact.normal, (contact.depth * 0.5));
            resolve_collision(rb2, contact.normal, -(contact.depth * 0.5));
        }

        relative_vel := rb2.velocity - rb.velocity;

        if (vec3_dot(relative_vel, contact.normal) < 0) {
            e: f32 = math.min(rb.restitution, rb2.restitution);

            j: f32 = -(1 + e) * vec3_dot(relative_vel, contact.normal);
            j /= rb_inverse_mass(rb^) + rb_inverse_mass(rb2^);

            impulse := contact.normal * j;

            rb_apply_impulse(rb, impulse);
            rb_apply_impulse(rb2, -impulse);
        }

        // friction
        rb_apply_force(rb, rb.force * rb2.friction);
        rb_apply_force(rb2, rb2.force * rb.friction);
    }
}

@(private = "file")
resolve_joints :: proc(using self: ^PhysicsWorld, rb: ^RigidBody, normal: Vec3, depth: f32) {
    if (len(rb.joints) != 0) {
        for j in rb.joints {
            joint := joints.data[j];
            fj := joint.variant.(^FixedJoint);

            if (fj.parent.id == rb.id) {
                resolve_collision(fj.child, normal, (depth * 0.3));
            } else {
                resolve_collision(fj.parent, normal, (depth * 0.3));
            }
        }
    }
}

@(private = "file")
resolve_collision :: proc(rb: ^RigidBody, normal: Vec3, depth: f32) {
    rb.transform.position.x += normal.x * depth;
    rb.transform.position.y += normal.y * depth;
    rb.transform.position.z += normal.z * depth;
}

@(private = "file")
resolve_tri_collision :: proc(rb: ^RigidBody, t: ^TriangleCollider) {
    // Get the dimensions of the cube
    cube_dimensions := rb.transform.scale; // Assuming `scale` is used to store dimensions here

    // Scale the player's position
    scaled_position := rb.transform.position;

    // Calculate the closest point on the triangle
    closest := closest_point_on_triangle(scaled_position, t.pts[0], t.pts[1], t.pts[2]);
    diff := scaled_position - closest;

    // Adjust the distance calculation to account for cube dimensions
    half_dimensions := cube_dimensions * 0.5;
    adjusted_diff := Vec3{
        diff.x / half_dimensions.x,
        diff.y / half_dimensions.y,
        diff.z / half_dimensions.z,
    };
    dist := linalg.length(adjusted_diff);

    normal := adjusted_diff / dist;

    RAD :: 1

    if dist < RAD {
        // Adjust position considering the cube dimensions
        rb.transform.position += Vec3{
            normal.x * (RAD - dist) * half_dimensions.x,
            normal.y * (RAD - dist) * half_dimensions.y,
            normal.z * (RAD - dist) * half_dimensions.z,
        };

        // Project velocity to the normal plane if moving towards it
        vel_normal_dot := linalg.dot(rb.velocity, normal);
        if vel_normal_dot < 0 {
            rb.velocity -= normal * vel_normal_dot;
        }
    }
}
