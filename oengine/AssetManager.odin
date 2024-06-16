package oengine

Asset :: union {
    Texture,
    Model,
    Shader,
    CubeMap,
}

asset_manager: struct {
    assets: map[string]Asset,
}

asset_variant :: proc(self: Asset, $T: typeid) -> T {
    return self.(T);
}

reg_asset :: proc(tag: string, asset: Asset) {
    using asset_manager;
    assets[tag] = asset;
}

get_asset :: proc(tag: string) -> Asset {
    using asset_manager;
    
    if (assets[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
        return nil;
    }

    return assets[tag];
}

get_asset_var :: proc(tag: string, $T: typeid) -> T {
    using asset_manager;
    
    if (assets[tag] == nil) {
        dbg_log(str_add({"Asset ", tag, " doesn\'t exist"}), DebugType.WARNING);
    }

    return asset_variant(assets[tag], T);
}

asset_exists :: proc(tag: string) -> bool {
    return asset_manager.assets[tag] != nil;
}
