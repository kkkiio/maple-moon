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
