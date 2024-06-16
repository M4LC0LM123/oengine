package oengine

import rl "vendor:raylib"
import "core:math"

Raycast :: struct {
    position, target: rl.Vector3,
}

rc_debug :: proc(using self: Raycast) {
    rl.DrawLine3D(position, target, rl.GREEN);
}

rc_is_colliding :: proc(using self: Raycast, transform: Transform, shape: ShapeType) -> bool {
    if (shape == ShapeType.BOX) {
        tmin, tmax, tymin, tymax, tzmin, tzmax: f32;
        
        // apply rotation to ray
        rotationMatrix: Mat4 = mat4_from_yaw_pitch_roll(
            transform.rotation.y * rl.DEG2RAD,
            transform.rotation.x * rl.DEG2RAD,
            transform.rotation.z * rl.DEG2RAD,
        );

        rayDirection: rl.Vector3 = vec3_normalize(target - position);
        rotatedRayDirection: rl.Vector3 = vec3_transform(rayDirection, rotationMatrix);
        
        boxSize: rl.Vector3 = transform.scale;
        boxMin: rl.Vector3 = transform.position - boxSize * 0.5;
        boxMax: rl.Vector3 = transform.position + boxSize * 0.5;

        tmin = (boxMin.x - position.x) / rayDirection.x;
        tmax = (boxMax.x - position.x) / rayDirection.x;

        if (tmin > tmax) {
            tmin, tmax = tmax, tmin;
        }

        tymin = (boxMin.y - position.y) / rayDirection.y;
        tymax = (boxMax.y - position.y) / rayDirection.y;

        if (tymin > tymax) {
            tymin, tymax = tymax, tymin;
        }

        if ((tmin > tymax) || (tymin > tmax)) {
            return false;
        }

        if (tymin > tmin) {
            tmin = tymin;
        }

        if (tymax < tmax) {
            tmax = tymax;
        }

        tzmin = (boxMin.z - position.z) / rayDirection.z;
        tzmax = (boxMax.z - position.z) / rayDirection.z;

        if (tzmin > tzmax) {
            tzmin, tzmax = tzmax, tzmin;
        }

        if ((tmin > tzmax) || (tzmin > tmax)) {
            return false;
        }

        if (tzmin > tmin) {
            tmin = tzmin;
        }

        if (tzmax < tmax) {
            tmax = tzmax;
        }

        // Calculate contact point for a box
        // contactPoint = position + rotatedRayDirection * tmin;
        return true;
    }
     
    if (shape == ShapeType.SPHERE) {
        t1, t2: f32;

        rayDirection: rl.Vector3 = vec3_normalize(target - position);
        sphereCenter: rl.Vector3 = transform.position;
        sphereRadius: f32 = transform.scale.x * 0.5;

        oc: rl.Vector3 = position - sphereCenter;
        a: f32 = vec3_dot(rayDirection, rayDirection);
        b: f32 = 2.0 * vec3_dot(oc, rayDirection);
        c: f32 = vec3_dot(oc, oc) - sphereRadius * sphereRadius;
        discriminant: f32 = b * b - 4 * a * c;

        if (discriminant < 0) {
            return false;
        }

        sqrtDiscriminant: f32 = f32(math.sqrt(discriminant));
        t1 = (-b - sqrtDiscriminant) / (2.0 * a);
        t2 = (-b + sqrtDiscriminant) / (2.0 * a);

        if (t1 >= 0 || t2 >= 0) {
            // // Calculate contact point for a sphere
            // contactPoint = position + rayDirection * t1; // You can choose either t1 or t2
            return true;
        }

        return false;
    }

    return false;
}