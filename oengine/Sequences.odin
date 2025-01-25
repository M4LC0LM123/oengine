package oengine

import "core:math"

FollowPath :: []Vec3

total_dist :: proc(fp: FollowPath) -> f32 {
    res: f32;

    for i in 1..<len(fp) {
        res += vec3_dist(fp[i - 1], fp[i]);
    }

    return res;
}

position_sequence :: proc(fp: FollowPath, speed, time: f32) -> Vec3 {
    dist := total_dist(fp);
    travelled := math.mod(speed * time, dist);

    for i in 1..<len(fp) {
        seg_dist := vec3_dist(fp[i - 1], fp[i]);
        if (travelled <= seg_dist) {
            t := travelled / seg_dist;
            return math.lerp(fp[i - 1], fp[i], t);
        }
        
        travelled -= seg_dist;
    }

    return fp[len(fp) - 1];
}
