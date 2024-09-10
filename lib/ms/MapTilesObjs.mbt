// A tile and obj layer.
struct TilesObjs {
  tiles : FixedArray[Tile]
  objs : FixedArray[Obj]
}

pub fn TilesObjs::from_resource(src : NxNode) -> TilesObjs {
  let tileZMap = Map::new()
  let objZMap = Map::new()
  if src["info"].is_null().not() {
    let tileset = src["info"]["tS"].as_string().unwrap() + ".img"
    src["tile"].each(
      fn(tilenode) {
        let tile = Tile::from_resource(tilenode, tileset)
        let z = tile.get_z()
        tileZMap.get_or_init(z, fn() { [] }).push(tile)
      },
    )
    src["obj"].each(
      fn(objnode) {
        let obj = Obj::from_resource(objnode)
        let z = obj.get_z()
        objZMap.get_or_init(z, fn() { [] }).push(obj)
      },
    )
  }
  let zTiles = tileZMap.to_array()
  zTiles.sort_by_key(fn(it) { it.0 })
  let tiles = zTiles.iter().flat_map(fn(it) { it.1.iter() }).collect()
    |> FixedArray::from_array
  let zObjs = objZMap.to_array()
  zObjs.sort_by_key(fn(it) { it.0 })
  let objs = zObjs.iter().flat_map(fn(it) { it.1.iter() }).collect()
    |> FixedArray::from_array
  { tiles, objs }
}

pub fn TilesObjs::default() -> TilesObjs {
  { tiles: [], objs: [] }
}

pub fn update(self : TilesObjs) -> Unit {
  self.objs.each(fn(obj) { obj.update() })
}

pub fn draw(self : TilesObjs, viewpos : Point[Int], alpha : Double) -> Unit {
  self.objs.each(fn(obj) { obj.draw(viewpos, alpha) })
  self.tiles.each(fn(tile) { tile.draw(viewpos) })
}

// The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : FixedArray[TilesObjs]
}

pub fn MapTilesObjs::from_resource(src : NxNode) -> MapTilesObjs {
  let layers = @Layer.ids.map(
    fn(layer_id) { TilesObjs::from_resource(src[layer_id.to_string()]) },
  )
  { layers, }
}

pub fn MapTilesObjs::default() -> MapTilesObjs {
  {
    layers: FixedArray::makei(
      @Layer.ids.length(),
      fn(_i) { TilesObjs::default() },
    ),
  }
}

pub fn update(self : MapTilesObjs) -> Unit {
  self.layers.each(fn(layer) { layer.update() })
}

pub fn draw(
  self : MapTilesObjs,
  layer : Int,
  viewpos : Point[Int],
  alpha : Double
) -> Unit {
  self.layers[layer].draw(viewpos, alpha)
}
