package oengine

import rl "vendor:raylib"
import rlg "../oengine/rllights"
import "core:fmt"

WAVE_FRAG: cstring = `
#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float seconds;

uniform vec2 size;

uniform float freqX;
uniform float freqY;
uniform float ampX;
uniform float ampY;
uniform float speedX;
uniform float speedY;

void main() {
    float pixelWidth = 1.0 / size.x;
    float pixelHeight = 1.0 / size.y;
    float aspect = pixelHeight / pixelWidth;
    float boxLeft = 0.0;
    float boxTop = 0.0;

    vec2 p = fragTexCoord;
    p.x += cos((fragTexCoord.y - boxTop) * freqX / ( pixelWidth * 750.0) + (seconds * speedX)) * ampX * pixelWidth;
    p.y += sin((fragTexCoord.x - boxLeft) * freqY * aspect / ( pixelHeight * 750.0) + (seconds * speedY)) * ampY * pixelHeight;

    finalColor = texture(texture0, p)*colDiffuse*fragColor;
}`;

DEF_VERT: cstring = `
#version 100

attribute vec3 vertexPosition;
attribute vec2 vertexTexCoord;
attribute vec4 vertexTangent;
attribute vec3 vertexNormal;
attribute vec4 vertexColor;

uniform lowp int useNormalMap;
uniform mat4 matNormal;
uniform mat4 matModel;
uniform mat4 mvp;

varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec3 fragNormal;
varying vec4 fragColor;
varying mat3 TBN;

void main()
{
    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0));
    fragNormal = (matNormal*vec4(vertexNormal, 0.0)).xyz;

    fragTexCoord = vertexTexCoord ;
    fragColor = vertexColor ;

    // The TBN matrix is used to transform vectors from tangent space to world space
    // It is currently used to transform normals from a normal map to world space normals
    vec3 T = normalize(vec3(matModel*vec4(vertexTangent.xyz, 0.0)));
    vec3 B = cross(fragNormal, T)*vertexTangent.w;
    TBN = mat3(T, B, fragNormal);

    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
`;

DEF_FRAG: cstring = `
#version 100
#define TEX texture2D
#define TEXCUBE textureCube

#define NUM_LIGHTS 44
#define NUM_MATERIAL_MAPS 7
#define NUM_MATERIAL_CUBEMAPS 2

#define DIRLIGHT 0
#define OMNILIGHT 1
#define SPOTLIGHT 2

#define ALBEDO 0
#define METALNESS 1
#define NORMAL 2
#define ROUGHNESS 3
#define OCCLUSION 4
#define EMISSION 5
#define HEIGHT 6

#define CUBEMAP 0
#define IRRADIANCE 1

#define PI 3.1415926535897932384626433832795028

precision mediump float;

uniform mat4 matLights[NUM_LIGHTS];

varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec3 fragNormal;
varying vec4 fragColor;
varying mat3 TBN;

struct MaterialMap {
    sampler2D texture;
    mediump vec4 color;
    mediump float value;
    lowp int active;
};

struct MaterialCubemap {
    samplerCube texture;
    mediump vec4 color;
    mediump float value;
    lowp int active;
};

struct Light {
    samplerCube shadowCubemap;
    sampler2D shadowMap;
    vec3 position;
    vec3 direction;
    vec3 color;
    float energy;
    float specular;
    float size;
    float innerCutOff;
    float outerCutOff;
    float constant;
    float linear;
    float quadratic;
    float shadowMapTxlSz;
    float depthBias;
    lowp int type;
    lowp int shadow;
    lowp int enabled;
};

uniform MaterialCubemap cubemaps[NUM_MATERIAL_CUBEMAPS];
uniform MaterialMap maps[NUM_MATERIAL_MAPS];
uniform Light lights[NUM_LIGHTS];

uniform lowp int parallaxMinLayers;
uniform lowp int parallaxMaxLayers;

uniform float farPlane;
uniform vec3 colAmbient;
uniform vec3 viewPos;

uniform float fogDensity;
uniform vec4 fogColor;

float DistributionGGX(float cosTheta, float alpha) {
    float a = cosTheta * alpha;
    float k = alpha / (1.0 - cosTheta * cosTheta + a * a);
    return k * k * (1.0 / PI);
}

float GeometrySmith(float NdotL, float NdotV, float alpha) {
    return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

float SchlickFresnel(float u) {
    float m = 1.0 - u;
    float m2 = m * m;
    return m2 * m2 * m;
}

vec3 ComputeF0(float metallic, float specular, vec3 albedo) {
    float dielectric = 0.16 * specular * specular;
    return mix(vec3(dielectric), albedo, vec3(metallic));
}

vec2 Parallax(vec2 uv, vec3 V) {
    float height = 1.0 - TEX(maps[HEIGHT].texture, uv).r;
    return uv - vec2(V.xy / V.z) * height * maps[HEIGHT].value;
}

vec2 DeepParallax(vec2 uv, vec3 V) {
    float numLayers = mix(
        float(parallaxMaxLayers),
        float(parallaxMinLayers),
        abs(dot(vec3(0.0, 0.0, 1.0), V))
    );
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;

    vec2 P = V.xy / V.z * maps[HEIGHT].value;
    vec2 deltaTexCoord = P / numLayers;

    vec2 currentUV = uv;
    float currentDepthMapValue = 1.0 - TEX(maps[HEIGHT].texture, currentUV).y;

    while (currentLayerDepth < currentDepthMapValue) {
        currentUV += deltaTexCoord;
        currentLayerDepth += layerDepth;
        currentDepthMapValue = 1.0 - TEX(maps[HEIGHT].texture, currentUV).y;
    }

    vec2 prevTexCoord = currentUV - deltaTexCoord;
    float afterDepth = currentDepthMapValue + currentLayerDepth;
    float beforeDepth = 1.0 - TEX(maps[HEIGHT].texture, prevTexCoord).y - currentLayerDepth - layerDepth;
    float weight = afterDepth / (afterDepth - beforeDepth);

    return prevTexCoord * weight + currentUV * (1.0 - weight);
}

float ShadowOmni(int i, float cNdotL) {
    vec3 fragToLight = fragPosition - lights[i].position;
    float closestDepth = TEXCUBE(lights[i].shadowCubemap, fragToLight).r * farPlane;
    float currentDepth = length(fragToLight);
    float bias = lights[i].depthBias * max(1.0 - cNdotL, 0.05);
    return currentDepth - bias > closestDepth ? 0.0 : 1.0;
}

float Shadow(int i, float cNdotL) {
    vec4 p = matLights[i] * vec4(fragPosition, 1.0);
    vec3 projCoords = p.xyz / p.w;
    projCoords = projCoords * 0.5 + 0.5;

    float bias = max(lights[i].depthBias * (1.0 - cNdotL), 0.00002) + 0.00001;
    projCoords.z -= bias;

    if (projCoords.z > 1.0 || projCoords.x > 1.0 || projCoords.y > 1.0)
        return 1.0;

    float depth = projCoords.z;
    float shadow = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float pcfDepth = TEX(lights[i].shadowMap, projCoords.xy + vec2(x, y) * lights[i].shadowMapTxlSz).r;
            shadow += step(depth, pcfDepth);
        }
    }

    return shadow / 9.0;
}

void main() {
    vec3 V = normalize(viewPos - fragPosition);
    vec2 uv = fragTexCoord.xy;

    if (maps[HEIGHT].active != 0) {
        uv = (parallaxMinLayers > 0 && parallaxMaxLayers > 1)
            ? DeepParallax(uv, V)
            : Parallax(uv, V);

        if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0)
            discard;
    }

    vec3 albedo = maps[ALBEDO].color.rgb * fragColor.rgb;
    if (maps[ALBEDO].active != 0)
        albedo *= TEX(maps[ALBEDO].texture, uv).rgb;

    float metalness = maps[METALNESS].value;
    if (maps[METALNESS].active != 0)
        metalness *= TEX(maps[METALNESS].texture, uv).b;

    float roughness = maps[ROUGHNESS].value;
    if (maps[ROUGHNESS].active != 0)
        roughness *= TEX(maps[ROUGHNESS].texture, uv).g;

    vec3 F0 = ComputeF0(metalness, 0.5, albedo);
    vec3 N = (maps[NORMAL].active == 0) ? normalize(fragNormal)
        : normalize(TBN * (TEX(maps[NORMAL].texture, uv).rgb * 2.0 - 1.0));

    float NdotV = dot(N, V);
    float cNdotV = max(NdotV, 1e-4);

    vec3 diffLighting = vec3(0.0);
    vec3 specLighting = vec3(0.0);

    for (int i = 0; i < NUM_LIGHTS; i++) {
        if (lights[i].enabled != 0) {
            float size_A = 0.0;
            vec3 L = vec3(0.0);

            if (lights[i].type != DIRLIGHT) {
                vec3 LV = lights[i].position - fragPosition;
                L = normalize(LV);
                if (lights[i].size > 0.0) {
                    float t = lights[i].size / max(0.001, length(LV));
                    size_A = max(0.0, 1.0 - 1.0 / sqrt(1.0 + t * t));
                }
            } else {
                L = normalize(-lights[i].direction);
            }

            float NdotL = min(size_A + dot(N, L), 1.0);
            float cNdotL = max(NdotL, 0.0);

            vec3 H = normalize(V + L);
            float cNdotH = clamp(size_A + dot(N, H), 0.0, 1.0);
            float cLdotH = clamp(size_A + dot(L, H), 0.0, 1.0);

            vec3 lightColE = lights[i].color * lights[i].energy;

            vec3 diffLight = vec3(0.0);
            if (metalness < 1.0) {
                float FD90_minus_1 = 2.0 * cLdotH * cLdotH * roughness - 0.5;
                float FdV = 1.0 + FD90_minus_1 * SchlickFresnel(cNdotV);
                float FdL = 1.0 + FD90_minus_1 * SchlickFresnel(cNdotL);
                float diffBRDF = (1.0 / PI) * FdV * FdL * cNdotL;
                diffLight = diffBRDF * lightColE;
            }

            vec3 specLight = vec3(0.0);
            if (roughness > 0.0) {
                float alphaGGX = roughness * roughness;
                float D = DistributionGGX(cNdotH, alphaGGX);
                float G = GeometrySmith(cNdotL, cNdotV, alphaGGX);
                float cLdotH5 = SchlickFresnel(cLdotH);
                float F90 = clamp(50.0 * F0.g, 0.0, 1.0);
                vec3 F = F0 + (F90 - F0) * cLdotH5;
                vec3 specBRDF = cNdotL * D * F * G;
                specLight = specBRDF * lightColE * lights[i].specular;
            }

            float intensity = 1.0;
            if (lights[i].type == SPOTLIGHT) {
                float theta = dot(L, normalize(-lights[i].direction));
                float epsilon = (lights[i].innerCutOff - lights[i].outerCutOff);
                intensity = smoothstep(0.0, 1.0, (theta - lights[i].outerCutOff) / epsilon);
            }

            float distance = length(lights[i].position - fragPosition);
            float attenuation = 1.0 / (lights[i].constant + lights[i].linear * distance + lights[i].quadratic * (distance * distance));

            float shadow = 1.0;
            if (lights[i].shadow != 0) {
                shadow = (lights[i].type == OMNILIGHT) ? ShadowOmni(i, cNdotL) : Shadow(i, cNdotL);
            }

            float factor = intensity * attenuation * shadow;
            diffLighting += diffLight * factor;
            specLighting += specLight * factor;
        }
    }

    vec3 ambient = colAmbient;
    if (cubemaps[IRRADIANCE].active != 0) {
        vec3 kS = F0 + (1.0 - F0) * SchlickFresnel(cNdotV);
        vec3 kD = (1.0 - kS) * (1.0 - metalness);
        ambient = kD * TEXCUBE(cubemaps[IRRADIANCE].texture, N).rgb;
    }

    if (maps[OCCLUSION].active != 0) {
        float ao = TEX(maps[OCCLUSION].texture, uv).r;
        ambient *= ao;
        float lightAffect = mix(1.0, ao, maps[OCCLUSION].value);
        diffLighting *= lightAffect;
        specLighting *= lightAffect;
    }

    if (cubemaps[CUBEMAP].active != 0) {
        vec3 reflectCol = TEXCUBE(cubemaps[CUBEMAP].texture, reflect(-V, N)).rgb;
        specLighting = mix(specLighting, reflectCol, 1.0 - roughness);
    }

    vec3 diffuse = albedo * (ambient + diffLighting);

    vec3 emission = maps[EMISSION].color.rgb;
    if (maps[EMISSION].active != 0) {
        emission *= TEX(maps[EMISSION].texture, uv).rgb;
    }

    vec4 finalColor = vec4(diffuse + specLighting + emission, 1.0);

    // fog
    float dist = length(viewPos - fragPosition);
    // const vec4 fogColor = vec4(0.5, 0.5, 0.5, 1.0);
    // const float fogDensity = 0.08;

    float fogFactor = 1.0/exp((dist * fogDensity) * (dist * fogDensity));
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    finalColor = mix(fogColor, finalColor, fogFactor);

    gl_FragColor = finalColor;
}

`;

set_fog_color :: proc(color: Color) {
    fog_shader := rlg.GetShader(.LIGHTING)^;
    color_loc := shader_location(fog_shader, "fogColor");

    color_f := Vec4 {
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    };

    rl.SetShaderValue(fog_shader, color_loc, &color_f, .VEC4);
}

set_fog_density :: proc(density: f32) {
    fog_shader := rlg.GetShader(.LIGHTING)^;
    density_loc := shader_location(fog_shader, "fogDensity");
    density_v := density;

    rl.SetShaderValue(fog_shader, density_loc, &density_v, .FLOAT);
}

shader_location :: proc(shader: rl.Shader, uniformName: cstring) -> rl.ShaderLocationIndex {
    loc := rl.GetShaderLocation(shader, uniformName);
    return loc;
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
