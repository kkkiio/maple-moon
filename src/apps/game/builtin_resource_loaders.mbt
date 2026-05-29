///|
/// 定义一些内置的资源的加载器.
/// 
/// 资源路径解析由 `resource` 包内部的 PathResolver 统一处理:
/// - resolved asset path 统一为 `assets/...`
/// - 禁止 leading-slash 路径(`/...`)
/// - 禁止 `http(s)` 路径
/// - 相对路径按 source 规则映射到本地 assets 根目录
using @lazy {type Lazy}

///|
priv struct FetchCsvTextLoader {}

///|
fn FetchCsvTextLoader::new() -> FetchCsvTextLoader {
  FetchCsvTextLoader::{  }
}

///|
impl @resource.CsvTextLoader for FetchCsvTextLoader with fn load_text(
  _self,
  path,
) -> String {
  @asset.read_bytes(path)
  .map(fn(bytes) { bytes.to_unchecked_string() })
  .unwrap_or_else(fn() { abort("failed to read CSV/TSV asset: \{path}") })
}

///|
let mapx_loader : Ref[@resource.AsyncLoader?] = Ref(None)

///|
/// 获取地图信息的加载器.
fn get_mapx_loader() -> @resource.AsyncLoader {
  if mapx_loader.val is Some(loader) {
    return loader
  }
  let loader = @resource.AsyncLoader::new(
    "mapx",
    loader=@resource.FileJsonResourceLoader::new("assets/map"),
  )
  mapx_loader.val = Some(loader)
  loader
}

///|
let map_latest_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "map_latest",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Obj/": @resource.DirResourceLoader::new("assets/map/obj"),
      "MapHelper.img/": @resource.DirResourceLoader::new(
        "assets/spritesheets/Map/MapHelper.img",
      ),
    }),
  )
})

///|
fn get_map_latest_loader() -> @resource.AsyncLoader {
  map_latest_loader.get()
}

///|
let map_world_map_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "map_world_map",
    loader=@resource.DirResourceLoader::new("assets/map/WorldMap"),
  )
})

///|
fn get_map_world_map_loader() -> @resource.AsyncLoader {
  map_world_map_loader.get()
}

///|
let background_set_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "background_set_loader",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Back",
      "assets/map/back",
    ),
  )
})

///|
/// 获取背景集的加载器.
fn get_background_set_loader() -> @resource.AsyncLoader {
  background_set_loader.get()
}

///|
let object_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "object_loader",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Obj",
      "assets/map/obj",
    ),
  )
})

///|
/// 获取地图对象的加载器.
fn get_object_loader() -> @resource.AsyncLoader {
  object_loader.get()
}

///|
let tile_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "tile",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Tile",
      "assets/map/tile",
    ),
  )
})

///|
/// 获取地图瓦片的加载器.
fn get_tile_loader() -> @resource.AsyncLoader {
  tile_loader.get()
}

///|
let mob_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "mob",
    loader=@resource.FileJsonResourceLoader::new(
      // "https://maple-res.kkkiiox.work/mob",
      "assets/mob",
    ),
  )
})

///|
/// 获取怪物资源的加载器.
fn get_mob_loader() -> @resource.AsyncLoader {
  mob_loader.get()
}

///|
let skill_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "skill",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Skill",
      "assets/Skill",
    ),
  )
})

///|
fn get_skill_loader() -> @resource.AsyncLoader {
  skill_loader.get()
}

///|
let character_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "character",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Pants/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Pants",
        "assets/Character/Pants",
      ),
      "Weapon/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Weapon",
        "assets/Character/Weapon",
      ),
      "Coat/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Coat",
        "assets/Character/Coat",
      ),
      "Cap/": @resource.DirResourceLoader::new("assets/Character/Cap"),
      "Longcoat/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Longcoat",
        "assets/Character/Longcoat",
      ),
      "Shield/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Shield",
        "assets/Character/Shield",
      ),
      "Shoes/": @resource.DirResourceLoader::new(
        // "https://maple-res.kkkiiox.work/Character/Shoes",
        "assets/Character/Shoes",
      ),
      "Glove/": @resource.DirResourceLoader::new("assets/Character/Glove"),
      "Accessory/": @resource.DirResourceLoader::new(
        "assets/Character/Accessory",
      ),
    }),
  )
})

///|
fn get_character_loader() -> @resource.AsyncLoader {
  character_loader.get()
}

///|
let afterimage_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "afterimage",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Character/Afterimage",
      "assets/Character/Afterimage",
    ),
  )
})

///|
fn get_afterimage_loader() -> @resource.AsyncLoader {
  afterimage_loader.get()
}

///|
let body_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "body",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Character/Body",
      "assets/Character/Body",
    ),
  )
})

///|
fn get_body_loader() -> @resource.AsyncLoader {
  body_loader.get()
}

///|
let effect_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "effect",
    loader=@resource.FileJsonResourceLoader::new("assets/Effect"),
  )
})

///|
fn get_effect_loader() -> @resource.AsyncLoader {
  effect_loader.get()
}

///|
let face_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "face",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Character/Face",
      "assets/Character/Face",
    ),
  )
})

///|
fn get_face_loader() -> @resource.AsyncLoader {
  face_loader.get()
}

///|
let hair_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "hair",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Character/Hair",
      "assets/Character/Hair",
    ),
  )
})

///|
fn get_hair_loader() -> @resource.AsyncLoader {
  hair_loader.get()
}

///|
let item_special_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "item_special",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Item/Special",
      "assets/Item/Special",
    ),
  )
})

///|
fn get_item_special_loader() -> @resource.AsyncLoader {
  item_special_loader.get()
}

///|
let ui_window_2_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "ui_window_2",
    loader=@resource.DirResourceLoader::new("assets/UI/UIWindow2.img"),
  )
})

///|
fn get_ui_window_2_loader() -> @resource.AsyncLoader {
  ui_window_2_loader.get()
}

///|
let ui_window_4_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "ui_window_4",
    loader=@resource.DirResourceLoader::new("assets/UI/UIWindow4.img"),
  )
})

///|
fn get_ui_window_4_loader() -> @resource.AsyncLoader {
  ui_window_4_loader.get()
}

///|
let ui_slice_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "ui_slice",
    loader=@resource.FileJsonResourceLoader::new("assets"),
  )
})

///|
fn get_ui_slice_loader() -> @resource.AsyncLoader {
  ui_slice_loader.get()
}

///|
let npc_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "npc",
    loader=@resource.FileJsonResourceLoader::new("assets"),
  )
})

///|
fn get_npc_loader() -> @resource.AsyncLoader {
  npc_loader.get()
}

///|
let string_loader : Lazy[@resource.AsyncLoader] = Lazy::new(fn() {
  @resource.AsyncLoader::new(
    "string",
    loader=@resource.DirResourceLoader::new("assets/String"),
  )
})

///|
fn get_string_loader() -> @resource.AsyncLoader {
  string_loader.get()
}

///|
/// Install default resource loaders for the game runtime.
pub fn install_builtin_resource_loaders() -> Unit {
  @resource.register_async_loader("mapx", get_mapx_loader())
  @resource.register_async_loader("map_latest", get_map_latest_loader())
  @resource.register_async_loader("map_world_map", get_map_world_map_loader())
  @resource.register_async_loader("background_set", get_background_set_loader())
  @resource.register_async_loader("object", get_object_loader())
  @resource.register_async_loader("tile", get_tile_loader())
  @resource.register_async_loader("mob", get_mob_loader())
  @resource.register_async_loader("skill", get_skill_loader())
  @resource.register_async_loader("character", get_character_loader())
  @resource.register_async_loader("afterimage", get_afterimage_loader())
  @resource.register_async_loader("body", get_body_loader())
  @resource.register_async_loader("effect", get_effect_loader())
  @resource.register_async_loader("face", get_face_loader())
  @resource.register_async_loader("hair", get_hair_loader())
  @resource.register_async_loader("item_special", get_item_special_loader())
  @resource.register_async_loader(
    "item",
    @resource.AsyncLoader::new(
      "item",
      loader=@resource.CompositeAsyncResourceLoader::new({
        "Consume/": @resource.DirResourceLoader::new("assets/Item/Consume"),
        "Cash/": @resource.DirResourceLoader::new("assets/Item/Cash"),
        "Etc/": @resource.DirResourceLoader::new("assets/Item/Etc"),
        "Install/": @resource.DirResourceLoader::new("assets/Item/Install"),
        "Pet/": @resource.DirResourceLoader::new("assets/Item/Pet"),
      }),
    ),
  )
  @resource.register_async_loader(
    "item_anim",
    @resource.AsyncLoader::new(
      "item",
      loader=@resource.FileJsonResourceLoader::new("assets/Item"),
    ),
  )
  @resource.register_async_loader("ui_window_2", get_ui_window_2_loader())
  @resource.register_async_loader("ui_window_4", get_ui_window_4_loader())
  @resource.register_async_loader("ui_slice", get_ui_slice_loader())
  @resource.register_async_loader("npc", get_npc_loader())
  @resource.register_async_loader("string", get_string_loader())
  @resource.register_async_loader(
    "quest",
    @resource.AsyncLoader::new(
      "quest",
      loader=@resource.DirResourceLoader::new("assets/Quest"),
    ),
  )
  @resource.set_csv_loader(
    @resource.CsvLoader::new(loader=FetchCsvTextLoader::new()),
  )
}

///|
pub enum ResourceEnvMode {
  Prod
  Test
}

///|
pub fn install_resource_env(mode : ResourceEnvMode) -> Unit {
  ignore(Test)
  match mode {
    Prod => install_builtin_resource_loaders()
    // Test environment keeps the same resolver/loader rules.
    // Concrete I/O backend can be swapped by test harness when needed.
    Test => install_builtin_resource_loaders()
  }
}

// let status_bar_loader = @resource.SyncLoader::load(
//   "StatusBar",
//   "https://maple-res.kkkiiox.work/UI/StatusBar3.img.json",
//   @resource.ImageLoader::get_path_image_loader(),
// )
