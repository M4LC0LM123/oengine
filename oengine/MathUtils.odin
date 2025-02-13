package oengine

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"
import sc "core:strconv"

to_radians :: proc(degrees: f32) -> f32 {
    return degrees * rl.DEG2RAD;
}

to_degrees :: proc(radians: f32) -> f32 {
    return radians * rl.RAD2DEG;
}

look_at_vec2 :: proc(pos, target: Vec2) -> f32 {
    return math.atan2_f32(pos.y - target.y, pos.x - target.x) * Rad2Deg;
}

rotate_x :: proc(v: Vec3, angle: f32) -> Vec3 {
    s := math.sin(angle);
    c := math.cos(angle);
    return { v.x, v.y * c - v.z * s, v.y * s + v.z * c };
}

rotate_y :: proc(v: Vec3, angle: f32) -> Vec3 {
    s := math.sin(angle);
    c := math.cos(angle);
    return { v.x * c + v.z * s, v.y, -v.x * s + v.z * c };
}

rotate_z :: proc(v: Vec3, angle: f32) -> Vec3 {
    s := math.sin(angle);
    c := math.cos(angle);
    return { v.x * c - v.y * s, v.x * s + v.y * c, v.z };
}

set_axes_from_euler :: proc(obb: ^OBB, angles: Vec3) {
    obb.axis_x = rotate_x({1, 0, 0}, to_radians(angles.x));
    obb.axis_y = rotate_y({0, 1, 0}, to_radians(angles.y));
    obb.axis_z = rotate_z({0, 0, 1}, to_radians(angles.z));
}

barry_centric :: proc(p1, p2, p3: Vec3, pos: Vec2) -> f32 {
    det := (p2.z - p3.z) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.z - p3.z);
    l1 := ((p2.z - p3.z) * (pos.x - p3.x) + (p3.x - p2.x) * (pos.y - p3.z)) / det;
    l2 := ((p3.z - p1.z) * (pos.x - p3.x) + (p1.x - p3.x) * (pos.y - p3.z)) / det;
    l3 := 1.0 - l1 - l2;
    return l1 * p1.y + l2 * p2.y + l3 * p3.y;
}

// real time collision detection 5.1.5
closest_point_on_triangle :: proc(p, a, b, c: Vec3) -> Vec3 {
    // Check if P in vertex region outside A
    ab := b - a
    ac := c - a
    ap := p - a
    d1 := linalg.dot(ab, ap)
    d2 := linalg.dot(ac, ap)
    if d1 <= 0.0 && d2 <= 0.0 do return a // barycentric coordinates (1,0,0)
    // Check if P in vertex region outside B
    bp := p - b
    d3 := linalg.dot(ab, bp)
    d4 := linalg.dot(ac, bp)
    if d3 >= 0.0 && d4 <= d3 do return b // barycentric coordinates (0,1,0)
    // Check if P in edge region of AB, if so return projection of P onto AB
    vc := d1 * d4 - d3 * d2
    if vc <= 0.0 && d1 >= 0.0 && d3 <= 0.0 {
        v := d1 / (d1 - d3)
        return a + v * ab // barycentric coordinates (1-v,v,0)
    }
    // Check if P in vertex region outside C
    cp := p - c
    d5 := linalg.dot(ab, cp)
    d6 := linalg.dot(ac, cp)
    if d6 >= 0.0 && d5 <= d6 do return c // barycentric coordinates (0,0,1)
    // Check if P in edge region of AC, if so return projection of P onto AC
    vb := d5 * d2 - d1 * d6
    if vb <= 0.0 && d2 >= 0.0 && d6 <= 0.0 {
        w := d2 / (d2 - d6)
        return a + w * ac // barycentric coordinates (1-w,0,w)
    }
    // Check if P in edge region of BC, if so return projection of P onto BC
    va := d3 * d6 - d5 * d4
    if va <= 0.0 && (d4 - d3) >= 0.0 && (d5 - d6) >= 0.0 {
        w := (d4 - d3) / ((d4 - d3) + (d5 - d6))
        return b + w * (c - b) // barycentric coordinates (0,1-w,w)
    }
    // P inside face region. Compute Q through its barycentric coordinates (u,v,w)
    denom := 1.0 / (va + vb + vc)
    v := vb * denom
    w := vc * denom
    return a + ab * v + ac * w // = u*a + v*b + w*c, u = va * denom = 1.0-v-w
}

next_power_of_2 :: proc(v: i32) -> i32 {
    x := v;
    x -= 1;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
}

find_best_fit_rect :: proc(
    free_rects: ^[dynamic]Rect, width: i32, height: i32) -> Rect {
    best_rect: Rect = {0, 0, 0, 0};
    best_short_side: f32 = 99999;

    for rect in free_rects {
        short_side_fit := abs(rect.width - f32(width));
        if (rect.width >= f32(width) && 
            rect.height >= f32(height) && 
            short_side_fit < best_short_side) {
            best_rect = rect;
            best_short_side = short_side_fit;
        }
    }

    return best_rect;
}

split_free_space :: proc(free_rects: ^[dynamic]Rect, used_rect: Rect) {
    new_rects: [dynamic]Rect;

    for rect in free_rects {
        if (!rect_intersects(rect, used_rect)) {
            append(&new_rects, rect);
            continue;
        }

        // Generate new free spaces
        if (used_rect.x > rect.x) {
            append(&new_rects, Rect{rect.x, rect.y, used_rect.x - rect.x, rect.height});
        }
        if (used_rect.y > rect.y) {
            append(&new_rects, Rect{
                rect.x, rect.y, rect.width, used_rect.y - rect.y});
        }
        if (used_rect.x + used_rect.width < rect.x + rect.width) {
            append(&new_rects, Rect{
                used_rect.x + used_rect.width, 
                rect.y, 
                rect.x + rect.width - (used_rect.x + used_rect.width), 
                rect.height
            });
        }
        if (used_rect.y + used_rect.height < rect.y + rect.height) {
            append(&new_rects, Rect{
                rect.x, used_rect.y + used_rect.height, 
                rect.width, 
                rect.y + rect.height - (used_rect.y + used_rect.height)
            });
        }
    }

    free_rects^ = new_rects;
}

rect_intersects :: proc(a: Rect, b: Rect) -> bool {
    return !(b.x >= a.x + a.width || 
            b.x + b.width <= a.x || 
            b.y >= a.y + a.height || 
            b.y + b.height <= a.y);
}

triangle_uvs :: proc(v1, v2, v3: Vec3, #any_int rotation_steps: i32 = 0) -> (Vec2, Vec2, Vec2) {
    edge1 := v2 - v1;
    edge2 := v3 - v1;
    normal := vec3_cross(edge1, edge2);

    abs_normal := Vec3 {
        math.abs(normal.x),
        math.abs(normal.y),
        math.abs(normal.z)
    };

    cp1, cp2, cp3: Vec2;

    if (abs_normal.z >= abs_normal.x && abs_normal.z >= abs_normal.y) {
        // XY
        cp1 = v1.xy;
        cp2 = v2.xy;
        cp3 = v3.xy;
    } else if (abs_normal.x >= abs_normal.y && abs_normal.x >= abs_normal.z) {
        // YZ 
        cp1 = v1.zy;
        cp2 = v2.zy;
        cp3 = v3.zy;
    } else {
        // XZ 
        cp1 = v1.xz;
        cp2 = v2.xz;
        cp3 = v3.xz;
    }

    min_x := math.min(cp1.x, math.min(cp2.x, cp3.x));
    max_x := math.max(cp1.x, math.max(cp2.x, cp3.x));
    min_y := math.min(cp1.y, math.min(cp2.y, cp3.y));
    max_y := math.max(cp1.y, math.max(cp2.y, cp3.y));

    delta_x := max_x - min_x;
    delta_y := max_y - min_y;

    if (delta_x == 0) do delta_x = 1; 
    if (delta_y == 0) do delta_y = 1;

    uv1 := Vec2 {
        (cp1.x - min_x) / delta_x,
        (cp1.y - min_y) / delta_y
    };

    uv2 := Vec2 {
        (cp2.x - min_x) / delta_x,
        (cp2.y - min_y) / delta_y
    };

    uv3 := Vec2 {
        (cp3.x - min_x) / delta_x,
        (cp3.y - min_y) / delta_y
    };

    rotate_uv := proc(uv: Vec2, #any_int steps: i32) -> Vec2 {
        if (steps == 1) {
            return Vec2{uv.y, -uv.x};
        } else if (steps == 2) {
            return Vec2{-uv.x, -uv.y};
        } else if (steps == 3) {
            return Vec2{-uv.y, uv.x};
        }
        return uv;
    };

    uv1 = rotate_uv(uv1, rotation_steps);
    uv2 = rotate_uv(uv2, rotation_steps);
    uv3 = rotate_uv(uv3, rotation_steps);

    return uv1, uv2, uv3;
}

atlas_triangle_uvs :: proc(
    v1, v2, v3: Vec3, 
    region_uvs: [4]Vec2, 
    #any_int rotation_steps: i32 = 0) -> (Vec2, Vec2, Vec2) {
    edge1 := v2 - v1;
    edge2 := v3 - v1;
    normal := vec3_cross(edge1, edge2);

    abs_normal := Vec3 {
        math.abs(normal.x),
        math.abs(normal.y),
        math.abs(normal.z)
    };

    cp1, cp2, cp3: Vec2;

    if (abs_normal.z >= abs_normal.x && abs_normal.z >= abs_normal.y) {
        // XY projection
        cp1 = v1.xy;
        cp2 = v2.xy;
        cp3 = v3.xy;
    } else if (abs_normal.x >= abs_normal.y && abs_normal.x >= abs_normal.z) {
        // YZ projection
        cp1 = v1.zy;
        cp2 = v2.zy;
        cp3 = v3.zy;
    } else {
        // XZ projection
        cp1 = v1.xz;
        cp2 = v2.xz;
        cp3 = v3.xz;
    }

    // Compute triangle UVs (normalized between 0 and 1)
    min_x := math.min(cp1.x, math.min(cp2.x, cp3.x));
    max_x := math.max(cp1.x, math.max(cp2.x, cp3.x));
    min_y := math.min(cp1.y, math.min(cp2.y, cp3.y));
    max_y := math.max(cp1.y, math.max(cp2.y, cp3.y));

    delta_x := max_x - min_x;
    delta_y := max_y - min_y;

    if (delta_x == 0) do delta_x = 1; 
    if (delta_y == 0) do delta_y = 1;

    local_uv1 := Vec2 {
        (cp1.x - min_x) / delta_x,
        (cp1.y - min_y) / delta_y
    };

    local_uv2 := Vec2 {
        (cp2.x - min_x) / delta_x,
        (cp2.y - min_y) / delta_y
    };

    local_uv3 := Vec2 {
        (cp3.x - min_x) / delta_x,
        (cp3.y - min_y) / delta_y
    };

    rotate_uv := proc(uv: Vec2, #any_int steps: i32) -> Vec2 {
        if (steps == 1) {
            return Vec2{ uv.y, -uv.x };
        } else if (steps == 2) {
            return Vec2{ -uv.x, -uv.y };
        } else if (steps == 3) {
            return Vec2{ -uv.y, uv.x };
        }
        return uv;
    };

    // Rotate UVs if needed
    local_uv1 = rotate_uv(local_uv1, rotation_steps);
    local_uv2 = rotate_uv(local_uv2, rotation_steps);
    local_uv3 = rotate_uv(local_uv3, rotation_steps);

    // **Interpolate UVs using the 4 provided region UVs**
    interpolate_uv := proc(local_uv: Vec2, region_uvs: [4]Vec2) -> Vec2 {
        return Vec2 {
            (1 - local_uv.x) * (1 - local_uv.y) * region_uvs[0].x +
            (local_uv.x) * (1 - local_uv.y) * region_uvs[1].x +
            (local_uv.x) * (local_uv.y) * region_uvs[2].x +
            (1 - local_uv.x) * (local_uv.y) * region_uvs[3].x,

            (1 - local_uv.x) * (1 - local_uv.y) * region_uvs[0].y +
            (local_uv.x) * (1 - local_uv.y) * region_uvs[1].y +
            (local_uv.x) * (local_uv.y) * region_uvs[2].y +
            (1 - local_uv.x) * (local_uv.y) * region_uvs[3].y
        };
    };

    uv1 := interpolate_uv(local_uv1, region_uvs);
    uv2 := interpolate_uv(local_uv2, region_uvs);
    uv3 := interpolate_uv(local_uv3, region_uvs);

    return uv1, uv2, uv3;
}

square_from_tri :: proc(tri: [3]Vec3) -> [4]Vec3 {
    v1 := tri[1] - tri[0];
    v2 := tri[2] - tri[0];

    normal := vec3_normalize(vec3_cross(v1, v2));

    v3 := tri[2] - tri[1];

    center := (tri[0] + tri[1] + tri[2]) * (1 / 3);
    v1_unit := vec3_normalize(v1);
    v2_unit := vec3_normalize(v2);
    len_v1 := math.sqrt(vec3_dot(v1, v1));
    len_v2 := math.sqrt(vec3_dot(v2, v2));
    side_len := max(len_v1, len_v2);

    assumed_v := v1_unit + v2_unit;
    two: f32 = 2.0;
    assumed_v *= side_len / math.sqrt(two);
    p4 := center + assumed_v;

    return {tri[0], tri[1], tri[2], p4};
}

rand_digits :: proc(digit_count: i32) -> i32 {
    res_str := str_add("", rl.GetRandomValue(0, 9));

    for i in 1..<digit_count {
        digit := rl.GetRandomValue(0, 9);
        res_str = str_add(res_str, digit);
    }

    res, ok := sc.parse_int(res_str);

    if (ok) do return i32(res);

    return 0;
}

look_at :: proc(pos, target: Vec3, up: Vec3 = {0, 1, 0}) -> Vec3 {
    quat := linalg.quaternion_look_at(pos, target, up);
    quat = linalg.quaternion_normalize(quat);
    x, y, z := linalg.euler_angles_from_quaternion_f32(quat, .XYZ);
    x *= Rad2Deg; y *= Rad2Deg; z *= Rad2Deg;

    forward := linalg.quaternion128_mul_vector3(quat, vec3_z());
    expected_forward := vec3_normalize(target - pos);

    if (vec3_dot(forward, expected_forward) < 0) {
        x = -x;
        y = -y;
        z = -z;
    }

    // gimbal lock
    if (math.is_nan(x) || math.is_nan(y) || math.is_nan(z)) {
        x = 90; y = 0; z = 0;
    }

    // pitch yaw roll
    return {x, y, z};
}
