package oengine

import "core:math"
import "core:math/linalg"
import "core:fmt"

FollowPath :: []Vec3

total_dist :: proc(fp: FollowPath) -> f32 {
    res: f32;

    for i in 1..<len(fp) {
        res += vec3_dist(fp[i - 1], fp[i]);
    }

    return res;
}

total_time :: proc(fp: FollowPath, speed: f32) -> f32 {
    return total_dist(fp) / speed;
}

calc_rotation :: proc(pos, next: Vec3) -> Vec3 {
    return {0, math.atan2(next.z - pos.z, next.x - pos.x), 0} * Rad2Deg;
}

position_sequence :: proc(fp: FollowPath, speed, time: f32) -> (Vec3, Vec3) {
    dist := total_dist(fp);
    travelled := math.mod(speed * time, dist);

    for i in 1..<len(fp) {
        seg_dist := vec3_dist(fp[i - 1], fp[i]);
        if (travelled <= seg_dist) {
            t := travelled / seg_dist;
            return math.lerp(fp[i - 1], fp[i], t), calc_rotation(fp[i - 1], fp[i]);
        }

        travelled -= seg_dist;
    }

    return fp[len(fp) - 1], {};
}
