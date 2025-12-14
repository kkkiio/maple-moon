/// 定义一些内置的资源的加载器.
/// 
/// 部分资源还保存在 r2:maple 存储里, 旧域名是 maple-res.kkkiiox.work.
/// 这些资源需要先复制回本地项目, 可以通过 `rclone` 复制, 例如:
/// ```bash
/// rclone copy -v --no-update-modtime r2:maple/Map/Map0 assets/map/map0
/// ```
///
/// 对于从 r2 迁移的资源, 它们引用的子资源路径往往是相对于旧域名根目录的.
/// 例如: 资源中引用 `"images/Map/29108.png"`, 而本地实际存储在 `"assets/images/Map/29108.png"`.
/// 为了兼容这种情况, `AsyncLoader` 提供了 `base_url` 和 `image_base_url` 选项来修正路径解析.

///|
let mapx_loader : Ref[AsyncLoader?] = Ref::new(None)

///|
/// 获取地图信息的加载器.
pub fn get_mapx_loader() -> AsyncLoader {
  if mapx_loader.val is Some(loader) {
    return loader
  }
  let loader = CompositeAsyncResourceLoader::new({
    "Map0/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map0"),
    "Map1/": DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Map1",
      "/assets/map/map1",
    ),
    "Map2/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map2"),
    "Map3/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map3"),
    "Map4/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map4"),
    "Map5/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map5"),
    "Map6/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map6"),
    "Map7/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map7"),
    "Map8/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map8"),
    "Map9/": DirResourceLoader::new("https://maple-res.kkkiiox.work/Map/Map9"),
  })
  let loader = AsyncLoader::new("mapx", loader~)
  mapx_loader.val = Some(loader)
  loader
}

///|
let background_set_loader : Lazy[AsyncLoader] = Lazy::new(fn() {
  AsyncLoader::new(
    "background_set_loader",
    loader=DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Back",
      "/assets/map/back",
    ),
    base_url="/assets",
  )
})

///|
/// 获取背景集的加载器.
pub fn get_background_set_loader() -> AsyncLoader {
  background_set_loader.get()
}

///|
let object_loader : Lazy[AsyncLoader] = Lazy::new(fn() {
  AsyncLoader::new(
    "object_loader",
    loader=DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Obj",
      "/assets/map/obj",
    ),
    base_url="/assets",
  )
})

///|
/// 获取地图对象的加载器.
pub fn get_object_loader() -> AsyncLoader {
  object_loader.get()
}

///|
let tile_loader : Lazy[AsyncLoader] = Lazy::new(fn() {
  AsyncLoader::new(
    "tile",
    loader=DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Tile",
      "/assets/map/tile",
    ),
    base_url="/assets",
  )
})

///|
/// 获取地图瓦片的加载器.
pub fn get_tile_loader() -> AsyncLoader {
  tile_loader.get()
}

///|
let mob_loader : Lazy[AsyncLoader] = Lazy::new(fn() {
  AsyncLoader::new(
    "mob",
    loader=DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Mob",
      "/assets/mob",
    ),
    base_url="/assets",
  )
})

///|
/// 获取怪物资源的加载器.
pub fn get_mob_loader() -> AsyncLoader {
  mob_loader.get()
}

///|
/// Lazy initialization.
priv struct Lazy[T] {
  mut val : T?
  init_f : () -> T
}

///|
fn[T] Lazy::new(init_f : () -> T) -> Lazy[T] {
  { val: None, init_f }
}

///|
fn[T] Lazy::get(self : Lazy[T]) -> T {
  if self.val is Some(val) {
    return val
  }
  let val = (self.init_f)()
  self.val = Some(val)
  val
}
