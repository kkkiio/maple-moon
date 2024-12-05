/// A tile and obj layer.
struct TilesObjs {
  tiles : Array[Tile]
  objs : Array[Obj]
}

pub fn TilesObjs::load(src : NxNode) -> @utils.Future[Result[TilesObjs, Error]] {
  let tileset = match src.value() {
    { "info": { "tS": String(tileset) } } => tileset + ".img"
    _ => ""
  }

  // Load tiles
  let tiles_future = src["tile"]
    .iter()
    .map(fn(tilenode) { Tile::load(tilenode, tileset) })
    .collect()
    |> @utils.Future::all_of()

  // Load objects
  let objs_future = src["obj"]
    .iter()
    .map(fn(objnode) { Obj::load(objnode) })
    .collect()
    |> @utils.Future::all_of()

  // Combine both futures
  tiles_future
  .combine(objs_future)
  .map_exn(
    fn(it) {
      let (tiles, objs) = it
      let objs = @utils.flatten_ok(objs).unwrap_or_error!()
      TilesObjs::new(tiles, objs)
    },
  )
}

fn TilesObjs::new(tiles : Array[Tile], objs : Array[Obj]) -> TilesObjs {
  let tileZMap = Map::new()
  for tile in tiles {
    let z = tile.get_z()
    tileZMap.get_or_init(z, fn() { [] }).push(tile)
  }
  let objZMap = Map::new()
  for obj in objs {
    let z = obj.get_z()
    objZMap.get_or_init(z, fn() { [] }).push(obj)
  }
  let zTiles = tileZMap.to_array()
  zTiles.sort_by_key(fn(it) { it.0 })
  let zObjs = objZMap.to_array()
  zObjs.sort_by_key(fn(it) { it.0 })
  { tiles, objs }
}

pub fn TilesObjs::default() -> TilesObjs {
  { tiles: [], objs: [] }
}

pub fn update(self : TilesObjs) -> Unit {
  for obj in self.objs {
    obj.update()
  }
}

pub fn draw(self : TilesObjs, viewpos : Point[Int], alpha : Double) -> Unit {
  for obj in self.objs {
    obj.draw(viewpos, alpha)
  }
  for tile in self.tiles {
    tile.draw(viewpos)
  }
}

/// The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : Array[TilesObjs]
}

pub fn MapTilesObjs::load(
  src : NxNode
) -> @utils.Future[Result[MapTilesObjs, Error]] {
  @layer.ids.map(fn(layer_id) { TilesObjs::load(src[layer_id.to_string()]) })
  |> Array::from_fixed_array
  |> @utils.Future::all_of()
  |> @utils.Future::map_exn(
    fn(res) {
      let layers = Array::new(capacity=@layer.ids.length())
      for r in res {
        layers.push(r.unwrap_or_error!())
      }
      { layers, }
    },
  )
}

pub fn MapTilesObjs::default() -> MapTilesObjs {
  { layers: Array::makei(@layer.ids.length(), fn(_i) { TilesObjs::default() }) }
}

pub fn update(self : MapTilesObjs) -> Unit {
  for layer in self.layers {
    layer.update()
  }
}

pub fn draw(
  self : MapTilesObjs,
  layer : Int,
  viewpos : Point[Int],
  alpha : Double
) -> Unit {
  self.layers[layer].draw(viewpos, alpha)
}
