package oengine

import rl "vendor:raylib"

LIGHT_VERT: cstring = "#version 330\n// Input vertex attributes\nin vec3 vertexPosition;\nin vec2 vertexTexCoord;\nin vec3 vertexNormal;\nin vec4 vertexColor;\n// Input uniform values\nuniform mat4 mvp;\nuniform mat4 matModel;\nuniform mat4 matNormal;\n// Output vertex attributes (to fragment shader)\nout vec3 fragPosition;\nout vec2 fragTexCoord;\nout vec4 fragColor;\nout vec3 fragNormal;\nvoid main()\n{\n    // Send vertex attributes to fragment shader\n    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0));\n    fragTexCoord = vertexTexCoord;\n    fragColor = vertexColor;\n    fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));\n    // Calculate final vertex position\n    gl_Position = mvp*vec4(vertexPosition, 1.0);\n}\n"

LIGHT_FRAG: cstring = "#version 330\n\n// Input vertex attributes (from vertex shader)\nin vec3 fragPosition;\nin vec2 fragTexCoord;\n//in vec4 fragColor;\nin vec3 fragNormal;\n\n// Input uniform values\nuniform sampler2D texture0;\nuniform vec4 colDiffuse;\n\n// Output fragment color\nout vec4 finalColor;\n\n// NOTE: Add here your custom variables\n\n#define     MAX_LIGHTS              100\n#define     LIGHT_DIRECTIONAL       0\n#define     LIGHT_POINT             1\n\nstruct Light {\n    int enabled;\n    int type;\n    vec3 position;\n    vec3 target;\n    vec4 color;\n};\n\n// Input lighting values\nuniform Light lights[MAX_LIGHTS];\nuniform vec4 ambient;\nuniform vec3 viewPos;\n\nvoid main()\n{\n    // Texel color fetching from texture sampler\n    vec4 texelColor = texture(texture0, fragTexCoord);\n    vec3 lightDot = vec3(0.0);\n    vec3 normal = normalize(fragNormal);\n    vec3 viewD = normalize(viewPos - fragPosition);\n    vec3 specular = vec3(0.0);\n\n    // NOTE: Implement here your fragment shader code\n\n    for (int i = 0; i < MAX_LIGHTS; i++)\n    {\n        if (lights[i].enabled == 1)\n        {\n            vec3 light = vec3(0.0);\n\n            if (lights[i].type == LIGHT_DIRECTIONAL)\n            {\n                light = -normalize(lights[i].target - lights[i].position);\n            }\n\n            if (lights[i].type == LIGHT_POINT)\n            {\n                light = normalize(lights[i].position - fragPosition);\n            }\n\n            float NdotL = max(dot(normal, light), 0.0);\n            lightDot += lights[i].color.rgb*NdotL;\n\n            float specCo = 0.0;\n            if (NdotL > 0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0); // 16 refers to shine\n            specular += specCo;\n        }\n    }\n\n    finalColor = (texelColor*((colDiffuse + vec4(specular, 1.0))*vec4(lightDot, 1.0)));\n    finalColor += texelColor*(ambient/10.0)*colDiffuse;\n\n    // Gamma correction\n    finalColor = pow(finalColor, vec4(1.0/2.2));\n}"

WAVE_FRAG: cstring = "#version 330\n\n// Input vertex attributes (from vertex shader)\nin vec2 fragTexCoord;\nin vec4 fragColor;\n\n// Input uniform values\nuniform sampler2D texture0;\nuniform vec4 colDiffuse;\n\n// Output fragment color\nout vec4 finalColor;\n\nuniform float seconds;\n\nuniform vec2 size;\n\nuniform float freqX;\nuniform float freqY;\nuniform float ampX;\nuniform float ampY;\nuniform float speedX;\nuniform float speedY;\n\nvoid main() {\n    float pixelWidth = 1.0 / size.x;\n    float pixelHeight = 1.0 / size.y;\n    float aspect = pixelHeight / pixelWidth;\n    float boxLeft = 0.0;\n    float boxTop = 0.0;\n\n    vec2 p = fragTexCoord;\n    p.x += cos((fragTexCoord.y - boxTop) * freqX / ( pixelWidth * 750.0) + (seconds * speedX)) * ampX * pixelWidth;\n    p.y += sin((fragTexCoord.x - boxLeft) * freqY * aspect / ( pixelHeight * 750.0) + (seconds * speedY)) * ampY * pixelHeight;\n\n    finalColor = texture(texture0, p)*colDiffuse*fragColor;\n}"

shader_location :: proc(shader: rl.Shader, uniformName: cstring) -> rl.ShaderLocationIndex {
    loc := rl.GetShaderLocation(shader, uniformName);
    return rl.ShaderLocationIndex(loc);
}

vec_to_mulptr :: proc {
    vec2_to_mulptr,
    vec3_to_mulptr,
    vec4_to_mulptr,
}

vec3_to_mulptr :: proc(arr: [3]f32) -> rawptr {
    slice := []f32{arr.x, arr.y, arr.z};
    return raw_data(slice);
}

vec2_to_mulptr :: proc(arr: [2]f32) -> rawptr {
    slice := []f32{arr.x, arr.y};
    return raw_data(slice);
}

vec4_to_mulptr :: proc(arr: [4]f32) -> rawptr {
    slice := []f32{arr.x, arr.y, arr.z, arr.w};
    return raw_data(slice);
}
