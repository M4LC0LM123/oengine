package oengine

import "fa"
import "core:fmt"

// sector based partitioning

SBP_AABB :: struct {
    min, max: Vec3,
}

sbp_overlaps :: proc(a, b: SBP_AABB) -> bool {
    return (a.min.x <= b.max.x && a.max.x >= b.min.x &&
            a.min.y <= b.max.y && a.max.y >= b.min.y &&
            a.min.z <= b.max.z && a.max.z >= b.min.z);
}

aabb_to_sbp :: proc(a: AABB) -> SBP_AABB {
    return SBP_AABB {
        min = {a.x - a.width * 0.5, a.y - a.height * 0.5, a.z - a.depth * 0.5},
        max = {a.x + a.width * 0.5, a.y + a.height * 0.5, a.z + a.depth * 0.5},
    };
}

Sector :: struct {
    bounds: SBP_AABB,
    _rbs: fa.FixedArray(^RigidBody, MAX_RBS),
}

sector_init :: proc(bounds: SBP_AABB) -> Sector {
    return Sector {
        bounds = bounds,
        _rbs = fa.fixed_array(^RigidBody, MAX_RBS),
    };
}

SBPTree :: struct($D: i32) {
    _sectors: [D][D][D]Sector,
}

sbp_clear :: proc(sbp: ^$T/SBPTree) {
    for i in 0..<len(sbp._sectors) {
        for j in 0..<len(sbp._sectors) {
            for k in 0..<len(sbp._sectors) {
                sbp._sectors[i][j][k]._rbs.len = 0;
            }
        }
    }
}

sbp_retrieve :: proc(sbp: SBPTree($D), index_sbp: SBP_AABB) -> Sector {
    i := i32(index_sbp.max.x - index_sbp.min.x) / 2;
    j := i32(index_sbp.max.y - index_sbp.min.y) / 2;
    k := i32(index_sbp.max.z - index_sbp.min.z) / 2;
    return sbp._sectors[i][j][k];
}

sbp_bounds :: proc(sbp: $T/SBPTree) -> SBP_AABB {
    dx := f32(len(sbp._sectors) * SECTOR_SIZE);
    dy := f32(len(sbp._sectors[0]) * SECTOR_SIZE);
    dz := f32(len(sbp._sectors[0][0]) * SECTOR_SIZE);

    return SBP_AABB {
        min = Vec3 {-dx * 0.5, -dy * 0.5, -dz * 0.5},
        max = Vec3 {dx * 0.5, dy * 0.5, dz * 0.5},
    };
}

aabb_valid :: proc(aabb: SBP_AABB) -> bool {
    return aabb.min.x > 0 && aabb.min.y > 0 && aabb.min.z > 0 &&
        aabb.max.x > 0 && aabb.max.y > 0 && aabb.max.z > 0;
}