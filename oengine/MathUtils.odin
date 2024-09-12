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

triangle_uvs :: proc(v1, v2, v3: Vec3) -> (Vec2, Vec2, Vec2) {
    // default XY plane
    cp1 := v1.xy;
    cp2 := v2.xy;
    cp3 := v3.xy;
    min_x := math.min(v1.x, min(v2.x, v3.x));
    max_x := math.max(v1.x, max(v2.x, v3.x));
    min_y := math.min(v1.y, min(v2.y, v3.y));
    max_y := math.max(v1.y, max(v2.y, v3.y));

    // ZY plane
    if (v1.x == v2.x && v1.x == v3.x) {
        cp1 = v1.zy;
        cp2 = v2.zy;
        cp3 = v3.zy;
        min_x = math.min(v1.z, min(v2.z, v3.z));
        max_x = math.max(v1.z, max(v2.z, v3.z));
    } else if (v1.y == v2.y && v1.y == v3.y) { // XZ plane
        cp1 = v1.xz;
        cp2 = v2.xz;
        cp3 = v3.xz;
        min_y = math.min(v1.z, min(v2.z, v3.z));
        max_y = math.max(v1.z, max(v2.z, v3.z));
    }

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
