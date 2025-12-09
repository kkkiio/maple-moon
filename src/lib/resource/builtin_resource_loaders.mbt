/// 定义一些内置的资源的加载器.
/// 
/// 部分资源还保存在 r2:maple 存储里, 旧域名是 maple-res.kkkiiox.work.
/// 这些资源需要先复制回本地项目, 可以通过 `rclone` 复制, 例如:
/// ```bash
/// rclone copy -v --no-update-modtime r2:maple/Map/Map0 assets/map/map0
/// ```
///

///|
let mapx_loader : Ref[AsyncLoader?] = Ref::new(None)

///|
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
