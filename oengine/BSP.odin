package oengine

import "fa"

MAX_NODES :: 512
MAX_RBS_PER_NODE :: 10

BSP_AABB :: struct {
    min, max: Vec3,
}

bsp_overlaps :: proc(a, b: BSP_AABB) -> bool {
    return (a.min.x <= b.max.x && a.max.x >= b.min.x &&
            a.min.y <= b.max.y && a.max.y >= b.min.y &&
            a.min.z <= b.max.z && a.max.z >= b.min.z);
}

aabb_to_bsp :: proc(a: AABB) -> BSP_AABB {
    return BSP_AABB {
        min = {a.x - a.width, a.y - a.height, a.z - a.depth},
        max = {a.x + a.width, a.y + a.height, a.z + a.depth},
    };
}

BSPNode :: struct {
    region: BSP_AABB,
    is_leaf: bool,
    rbs: fa.FixedArray(^RigidBody, MAX_RBS_PER_NODE),
    left, right: ^BSPNode,
}

bsp_init :: proc(region: BSP_AABB) -> ^BSPNode {
    bsp := new(BSPNode);
    bsp.region = region;
    bsp.is_leaf = true;
    bsp.rbs = fa.fixed_array(^RigidBody, MAX_RBS_PER_NODE);
    return bsp;
}

bsp_insert :: proc(node: ^BSPNode, rb: ^RigidBody) {
    if (!bsp_overlaps(node.region, aabb_to_bsp(trans_to_aabb(rb.transform)))) do return;

    if (node.is_leaf) {
        if (node.rbs.len < MAX_RBS_PER_NODE) {
            fa.append(&node.rbs, rb);
        } else {
            left_reg := node.region;
            right_reg := node.region;

            left_reg.max.x = (node.region.min.x + node.region.max.x) * 0.5;
            right_reg.min.x = (node.region.min.x + node.region.max.x) * 0.5;

            node.left = bsp_init(left_reg);
            node.right = bsp_init(right_reg);
            node.is_leaf = false;

            for i in 0..<node.rbs.len {
                bsp_insert(node.left, node.rbs.data[i]);
                bsp_insert(node.right, node.rbs.data[i]);
            }

            bsp_insert(node, rb);
            fa.clear(&node.rbs);
        }
    } else {
        bsp_insert(node.left, rb);
        bsp_insert(node.right, rb);
    }
}

bsp_collision :: proc(node: ^BSPNode, rb: ^RigidBody) -> ^RigidBody {
    if (!bsp_overlaps(node.region, aabb_to_bsp(trans_to_aabb(rb.transform)))) do return nil;

    if (node.is_leaf) {
        for i in 0..<node.rbs.len {
            a := aabb_to_bsp(trans_to_aabb(node.rbs.data[i].transform));
            b := aabb_to_bsp(trans_to_aabb(rb.transform));
            if (bsp_overlaps(a, b)) do return node.rbs.data[i];
        }
    } else {
        l := bsp_collision(node.left, rb);
        r := bsp_collision(node.right, rb);

        if (l != nil) do return l;
        if (r != nil) do return r;
    }

    return nil;
}

MAX_COLLS :: 100
bsp_collisions :: proc(node: ^BSPNode, rb: ^RigidBody, max_results: i32 = MAX_COLLS) -> fa.FixedArray(^RigidBody, MAX_COLLS) {
    if (!bsp_overlaps(node.region, aabb_to_bsp(trans_to_aabb(rb.transform)))) do return {};

    res := fa.fixed_array(^RigidBody, MAX_COLLS);
    count: i32;

    if (node.is_leaf) {
        for i := 0; i < int(node.rbs.len) && count < max_results; i += 1 {
            a := aabb_to_bsp(trans_to_aabb(node.rbs.data[i].transform));
            b := aabb_to_bsp(trans_to_aabb(rb.transform));
            if (bsp_overlaps(a, b)) {
                fa.append(&res, node.rbs.data[i]);
                count += 1;
            }
        }
    } else {
        left_results := bsp_collisions(node.left, rb, max_results - count);
        for j in 0..<left_results.len {
            fa.append(&res, left_results.data[j]);
            count += 1;
            if (count >= max_results) do break;
        }

        if (count < max_results) {
            right_results := bsp_collisions(node.right, rb, max_results - count);
            for k in 0..<right_results.len {
                fa.append(&res, right_results.data[k]);
                count += 1;
                if (count >= max_results) do break;
            }
        }
    }

    return res;
}

bsp_remove :: proc(node: ^BSPNode, rb: ^RigidBody) -> bool {
    if (!bsp_overlaps(node.region, aabb_to_bsp(trans_to_aabb(rb.transform)))) do return false;

    if (node.is_leaf) {
        for i in 0..<node.rbs.len {
            a := aabb_to_bsp(trans_to_aabb(node.rbs.data[i].transform));
            b := aabb_to_bsp(trans_to_aabb(rb.transform));
            if (bsp_overlaps(a, b)) {
                fa.remove(&node.rbs, fa.get_id(node.rbs, rb));
                return true;
            }
        }
    } else {
        return bsp_remove(node.left, rb) || bsp_remove(node.right, rb);
    }

    return false;
}
