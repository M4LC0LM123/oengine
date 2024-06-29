package oengine

import "core:math"

AABB :: struct {
    x, y, z: f32,
    width, height, depth: f32,
}

trans_to_aabb :: proc(t: Transform) -> AABB {
    return AABB {
        x = t.position.x,
        y = t.position.y,
        z = t.position.z,
        width = t.scale.x,
        height = t.scale.y,
        depth = t.scale.z,
    }
}

aabb_collision :: proc(cube1, cube2: AABB) -> bool {
    cube1MinX: f32 = cube1.x - cube1.width / 2;
    cube1MaxX: f32 = cube1.x + cube1.width / 2;
    cube1MinY: f32 = cube1.y - cube1.height / 2;
    cube1MaxY: f32 = cube1.y + cube1.height / 2;
    cube1MinZ: f32 = cube1.z - cube1.depth / 2;
    cube1MaxZ: f32 = cube1.z + cube1.depth / 2;

    cube2MinX: f32 = cube2.x - cube2.width / 2;
    cube2MaxX: f32 = cube2.x + cube2.width / 2;
    cube2MinY: f32 = cube2.y - cube2.height / 2;
    cube2MaxY: f32 = cube2.y + cube2.height / 2;
    cube2MinZ: f32 = cube2.z - cube2.depth / 2;
    cube2MaxZ: f32 = cube2.z + cube2.depth / 2;

    if (cube1MinX <= cube2MaxX && cube1MaxX >= cube2MinX &&
        cube1MinY <= cube2MaxY && cube1MaxY >= cube2MinY &&
        cube1MinZ <= cube2MaxZ && cube1MaxZ >= cube2MinZ) {
        return true; 
    }

    return false;
}

tris_to_aabb :: proc(tris: [dynamic]^TriangleCollider) -> AABB {
    min := vec3_one() * math.F32_MAX;
    max := vec3_one() * math.F32_MIN;

    for t in tris {
        for pt in t.pts {
            if (pt.x < min.x) do min.x = pt.x;
            if (pt.y < min.y) do min.y = pt.y;
            if (pt.z < min.z) do min.z = pt.z;

            if (pt.x > max.x) do max.x = pt.x;
            if (pt.y > max.y) do max.y = pt.y;
            if (pt.z > max.z) do max.z = pt.z;
        }
    }

    w := max.x - min.x;
    h := max.y - min.y;
    d := max.z - min.z;

    return AABB {
        x = min.x + w * 0.5, y = min.y + h * 0.5, z = min.z + d * 0.5,
        width = w,
        height = h,
        depth = d
    };
} 
