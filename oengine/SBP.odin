package oengine

import "fa"

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
