package oengine

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"

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
