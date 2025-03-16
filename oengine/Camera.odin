package oengine

import "core:math"
import "gl"

GLData :: struct {
    left, right, bottom, top: f64
}

Camera :: struct {
    _matrix: Mat4,
    fov, near, far, aspect: f32,

    position, rotation, target: Vec3,
    up, right, front: Vec3,

    prev_mp, curr_mp: Vec2,

    raycast: Raycast,
    gl_data: GLData,
}

cm_init :: proc(
    s_position: Vec3, 
    s_fov: f32 = 60, 
    s_near: f32 = 0.001, 
    s_far: f32 = 100) -> Camera {
    using res: Camera;
    
    fov = s_fov;
    near = s_near;
    far = s_far;
    aspect = f32(w_render_width()) / f32(w_render_height());

    position = s_position;
    target = vec3_zero();
    up = vec3_y();

    prev_mp = {};
    curr_mp = {};

    right = vec3_zero();
    rotation = vec3_zero();
    front = -vec3_z();

    raycast = Raycast {
        position,
        position * front * far,
    };

    // Set up the projection matrix
    gl.MatrixMode(gl.PROJECTION);
    gl.LoadIdentity();

    // Define perspective manually using glFrustum
    top: f64 = f64(near * math.tan(fov * 0.5 * Deg2Rad));
    bottom: f64 = -top;
    _right: f64 = top * f64(aspect);
    _left: f64 = f64(-_right);
    gl_data = {_left, _right, bottom, top};

    gl.Frustum(
        gl_data.left, 
        gl_data.right, 
        gl_data.bottom, 
        gl_data.top, 
        f64(near), f64(far)
    );

    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();

    return res;
}

cm_update :: proc(using self: ^Camera) {
    _matrix = mat4_look_at(position, target, up);

    raycast.position = position;
    raycast.target = position + vec3_normalize(front) * far;
}

cm_begin :: proc(using self: Camera) {
    gl.MatrixMode(gl.PROJECTION);
    gl.PushMatrix();
    gl.LoadIdentity();

    gl.Frustum(
        gl_data.left, 
        gl_data.right, 
        gl_data.bottom, 
        gl_data.top, 
        f64(near), f64(far)
    );

    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    mat := mat4_to_arr(_matrix);
    gl.MultMatrixf(&mat[0]);
    gl.Translatef(-position.x, -position.y, -position.z);
}

cm_end :: proc() {
    gl.MatrixMode(gl.PROJECTION);
    gl.PopMatrix(); 
}

cm_set_fps :: proc(using self: ^Camera, sensitivity: f32, is_mouse_locked: bool) {
    if (is_mouse_locked) {
        hide_cursor();
        curr_mp = mouse_pos();
        mouseDelta := Vec2 {curr_mp.x - prev_mp.x, -(curr_mp.y - prev_mp.y)};
        rotation.y -= mouseDelta.x * sensitivity;
        rotation.x += mouseDelta.y * sensitivity;

        rotation.x = math.clamp(rotation.x, -89.9, 89.9);

        prev_mp = curr_mp;
        set_mouse_pos({f32(w_render_width()) / 2, f32(w_render_height()) / 2});
        prev_mp = mouse_pos();
    } else {
        show_cursor();
    }
    
    cameraRotation: Mat4 = mat4_rotate_XYZ(
        Deg2Rad * rotation.x, 
        Deg2Rad * rotation.y, 
        Deg2Rad * rotation.z
    );
    front = vec3_transform(-vec3_z(), cameraRotation);
    right = vec3_transform(vec3_x(), cameraRotation);
    up = vec3_transform(vec3_y(), cameraRotation);
}

cm_set_fps_controls :: proc(using self: ^Camera, speed: f32, is_mouse_locked, fly: bool) {
    if (key_down(.W) && is_mouse_locked) {
        position.x += front.x * speed * w_delta_time();
        position.z += front.z * speed * w_delta_time();
    }

    if (key_down(.S) && is_mouse_locked) {
        position.x -= front.x * speed * w_delta_time();
        position.z -= front.z * speed * w_delta_time();
    }
    
    if (key_down(.A) && is_mouse_locked) {
        position.x -= right.x * speed * w_delta_time();
        position.z -= right.z * speed * w_delta_time();
    }

    if (key_down(.D) && is_mouse_locked) {
        position.x += right.x * speed * w_delta_time();
        position.z += right.z * speed * w_delta_time();
    }
    
    if (fly) {
        if (key_down(.SPACE) && is_mouse_locked) {
            position.y += speed * w_delta_time();
        }
        if (key_down(.LCTRL) || (key_down(.LGUI)) && is_mouse_locked) {
            position.y -= speed * w_delta_time();
        }
    }
}

cm_default_fps_matrix :: proc(using self: ^Camera) {
    target = position + vec3_normalize(front);
}
