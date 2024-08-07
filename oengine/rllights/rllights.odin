package rllights

import rl "vendor:raylib"
import "core:c"

when ODIN_OS == .Windows do foreign import rll "windows/rllights.lib"
when ODIN_OS == .Linux do foreign import rll "linux/rllights.a"

LightType :: enum {
    DIRECTIONAL = 0,
    OMNI,
    SPOT,
}

RLGShader :: enum {
    LIGHTING = 0,
    DEPTH,
    DEPTH_CUBEMAP,
    EQUIRECTANGULAR_TO_CUBEMAP,
    IRRADIANCE_CONVOLUTION,
    SKYBOX 
}

LightProperty :: enum {
    POSITION = 0,                 
    DIRECTION,                    
    COLOR,                        
    ENERGY,                       
    SPECULAR,                     
    SIZE,                         
    INNER_CUTOFF,                 
    OUTER_CUTOFF,                 
    ATTENUATION_CLQ,              
    ATTENUATION_CONSTANT,         
    ATTENUATION_LINEAR,           
    ATTENUATION_QUADRATIC
}

ShaderLocIndex :: enum {
    /* Same as raylib */

    VERTEX_POSITION = 0,
    VERTEX_TEXCOORD01,
    VERTEX_TEXCOORD02,
    VERTEX_NORMAL,
    VERTEX_TANGENT,
    VERTEX_COLOR,
    MATRIX_MVP,
    MATRIX_VIEW,
    MATRIX_PROJECTION,
    MATRIX_MODEL,
    MATRIX_NORMAL,
    VECTOR_VIEW,
    COLOR_DIFFUSE,
    COLOR_SPECULAR,
    COLOR_AMBIENT,
    MAP_ALBEDO,
    MAP_METALNESS,
    MAP_NORMAL,
    MAP_ROUGHNESS,
    MAP_OCCLUSION,
    MAP_EMISSION,
    MAP_HEIGHT,
    MAP_CUBEMAP,
    MAP_IRRADIANCE,
    MAP_PREFILTER,
    MAP_BRDF,

    /* Specific to rlights.h */

    COLOR_EMISSION,
    METALNESS_SCALE,
    ROUGHNESS_SCALE,
    AO_LIGHT_AFFECT,
    HEIGHT_SCALE,

    /* Internal use */

    COUNT_LOCS
}

Skybox :: struct {
    cubemap, irradiance: rl.TextureCubemap,
    vboPostionID, vboIndicesID, vaoID: c.int,
    isHDR: c.bool,
}

Context :: rawptr
DrawFunc :: proc(shader: rl.Shader)

foreign rll {
    @(link_name = "RLG_CreateContext")
    CreateContext :: proc(lightCount: c.uint) -> Context ---

    @(link_name = "RLG_DestroyContext")
    DestroyContext :: proc(ctx: Context) ---

    @(link_name = "RLG_SetContext")
    SetContext :: proc(ctx: Context) ---

    @(link_name = "RLG_GetContext")
    GetContext :: proc() -> Context ---

    @(link_name = "RLG_SetCustomShaderCode")
    SetCustomShaderCode :: proc(shader: RLGShader, vsCode: cstring, fsCode: cstring) ---

    @(link_name = "RLG_GetShader")
    GetShader :: proc(shader: RLGShader) -> ^rl.Shader ---

    @(link_name = "RLG_SetViewPosition")
    SetViewPosition :: proc(x: c.float, y: c.float, z: c.float) ---

    @(link_name = "RLG_SetViewPositionV")
    SetViewPositionV :: proc(position: rl.Vector3) ---

    @(link_name = "RLG_GetViewPosition")
    GetViewPosition :: proc() -> rl.Vector3 ---

    @(link_name = "RLG_SetAmbientColor")
    SetAmbientColor :: proc(color: rl.Color) ---

    @(link_name = "RLG_GetAmbientColor")
    GetAmbientColor :: proc() -> rl.Color ---

    @(link_name = "RLG_SetParallaxLayers")
    SetParallaxLayers :: proc(min: c.int, max: c.int) ---

    @(link_name = "RLG_GetParallaxLayers")
    GetParallaxLayers :: proc(min: ^c.int, max: ^c.int) ---

    @(link_name = "RLG_UseMap")
    UseMap :: proc(mapIndex: c.int, active: c.bool) ---

    @(link_name = "RLG_IsMapUsed")
    IsMapUsed :: proc(mapIndex: c.int) -> c.bool ---

    @(link_name = "RLG_UseDefaultMap")
    UseDefaultMap :: proc(mapIndex: c.int, active: c.bool) ---

    @(link_name = "RLG_SetDefaultMap")
    SetDefaultMap :: proc(mapIndex: c.int, s_map: rl.MaterialMap) ---

    @(link_name = "RLG_GetDefaultMap")
    GetDefaultMap :: proc(mapIndex: c.int) -> rl.MaterialMap ---

    @(link_name = "RLG_IsDefaultMapUsed")
    IsDefaultMapUsed :: proc(mapIndex: c.int) -> c.bool ---

    @(link_name = "RLG_GetLightcount")
    GetLightcount :: proc() -> c.uint ---

    @(link_name = "RLG_UseLight")
    UseLight :: proc(light: c.uint, active: c.bool) ---

    @(link_name = "RLG_IsLightUsed")
    IsLightUsed :: proc(light: c.uint) -> c.bool ---

    @(link_name = "RLG_ToggleLight")
    ToggleLight :: proc(light: c.uint) ---

    @(link_name = "RLG_SetLightType")
    SetLightType :: proc(light: c.uint, type: LightType) ---

    @(link_name = "RLG_GetLightType")
    GetLightType :: proc(light: c.uint) -> LightType ---

    @(link_name = "RLG_SetLightValue")
    SetLightValue :: proc(light: c.uint, property: LightProperty, value: c.float) ---

    @(link_name = "RLG_SetLightXYZ")
    SetLightXYZ :: proc(light: c.uint, property: LightProperty, x: c.float, y: c.float, z: c.float) ---

    @(link_name = "RLG_SetLightVec3")
    SetLightVec3 :: proc(light: c.uint, property: LightProperty, value: rl.Vector3) ---

    @(link_name = "RLG_SetLightColor")
    SetLightColor :: proc(light: c.uint, color: rl.Color) ---

    @(link_name = "RLG_GetLightValue")
    GetLightValue :: proc(light: c.uint, property: LightProperty) -> c.float ---

    @(link_name = "RLG_GetLightVec3")
    GetLightVec3 :: proc(light: c.uint, property: LightProperty) -> rl.Vector3 ---

    @(link_name = "RLG_GetLightColor")
    GetLightColor :: proc(light: c.uint) -> rl.Color ---

    @(link_name = "RLG_LightTranslate")
    LightTranslate :: proc(light: c.uint, x: c.float, y: c.float, z: c.float) ---

    @(link_name = "RLG_LightTranslateV")
    LightTranslateV :: proc(light: c.uint, v: rl.Vector3) ---

    @(link_name = "RLG_LightRotateX")
    LightRotateX :: proc(light: c.uint, degrees: c.float) ---

    @(link_name = "RLG_LightRotateY")
    LightRotateY :: proc(light: c.uint, degrees: c.float) ---

    @(link_name = "RLG_LightRotateZ")
    LightRotateZ :: proc(light: c.uint, degrees: c.float) ---

    @(link_name = "RLG_LightRotate")
    LightRotate :: proc(light: c.uint, axis: rl.Vector3, degrees: c.float) ---

    @(link_name = "RLG_SetLightTarget")
    SetLightTarget :: proc(light: c.uint, x: c.float, y: c.float, z: c.float) ---

    @(link_name = "RLG_SetLightTargetV")
    SetLightTargetV :: proc(light: c.uint, targetPosition: rl.Vector3) ---

    @(link_name = "RLG_GetLightTarget")
    GetLightTarget :: proc(light: c.uint) -> rl.Vector3 ---

    @(link_name = "RLG_EnableShadow")
    EnableShadow :: proc(light: c.uint, shadowMapResolution: c.int) ---

    @(link_name = "RLG_DisableShadow")
    DisableShadow :: proc(light: c.uint) ---

    @(link_name = "RLG_IsShadowEnabled")
    IsShadowEnabled :: proc(light: c.uint) -> c.bool ---

    @(link_name = "RLG_SetShadowBias")
    SetShadowBias :: proc(light: c.uint, value: c.float) ---

    @(link_name = "RLG_GetShadowBias")
    GetShadowBias :: proc(light: c.uint) -> c.float ---

    @(link_name = "RLG_UpdateShadowMap")
    UpdateShadowMap :: proc(light: c.uint, drawFunc: DrawFunc) ---

    @(link_name = "RLG_GetShadowMap")
    GetShadowMap :: proc(light: c.uint) -> rl.Texture ---

    @(link_name = "RLG_CastMesh")
    CastMesh :: proc(shader: rl.Shader, mesh: rl.Mesh, transform: rl.Matrix) ---

    @(link_name = "RLG_CastModel")
    CastModel :: proc(shader: rl.Shader, model: rl.Model, position: rl.Vector3, scale: c.float) ---

    @(link_name = "RLG_CastModelEx")
    CastModelEx :: proc(shader: rl.Shader, model: rl.Model, position: rl.Vector3, rotationAxis: rl.Vector3, rotationAngle: c.float, scale: rl.Vector3) ---

    @(link_name = "RLG_DrawMesh")
    DrawMesh :: proc(mesh: rl.Mesh, material: rl.Material, transform: rl.Matrix) ---

    @(link_name = "RLG_DrawModel")
    DrawModel :: proc(model: rl.Model, position: rl.Vector3, scale: c.float, tint: rl.Color) ---

    @(link_name = "RLG_DrawModelEx")
    DrawModelEx :: proc(model: rl.Model, position: rl.Vector3, rotationAxis: rl.Vector3, rotationAngle: c.float, scale: rl.Vector3, tint: rl.Color) ---

    @(link_name = "RLG_LoadSkybox")
    LoadSkybox :: proc(skyboxFileName: cstring) -> Skybox ---

    @(link_name = "RLG_LoadSkyboxHDR")
    LoadSkyboxHDR :: proc(skyboxFileName: cstring, size: c.int, format: c.int) -> Skybox ---

    @(link_name = "RLG_UnloadSkybox")
    UnloadSkybox :: proc(skybox: Skybox) ---

    @(link_name = "RLG_DrawSkybox")
    DrawSkybox :: proc(skybox: Skybox) ---
}
