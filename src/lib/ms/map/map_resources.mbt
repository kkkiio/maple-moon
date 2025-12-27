///|
pub(all) struct MapRawResources {
  id : Int
  nx_map : NxMap
  tilesets : Map[String, NxTileSet]
  object_animation_sets : Map[
    String,
    Map[ObjectAnimationPath, @resource.NxAnimation],
  ]
  background_animation_sets : Map[
    String,
    Map[BackgroundAnimationPath, @resource.NxAnimation],
  ]
  root : @resource.NxNode
}

///|
using @resource {get_mapx_loader, get_background_set_loader}

///|
/// Loads the raw map resources by map id.
pub async fn load_map_resources_by_id(map_id : Int) -> MapRawResources {
  guard map_id >= 0 else { fail("invalid map_id=\{map_id}") }
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading raw map resource")
  let src = get_mapx_loader().load_res_async(path)
  guard not(src.is_null()) else {
    raise @resource.LoadError("map not found, id=\{map_id}")
  }
  let nx_map : NxMap = @json.from_json(src.value()) catch {
    err => fail("failed to parse nx map: \{err.to_string()}")
  }
  let tilesets = {}
  for layer in nx_map.layers {
    if layer.info is Some({ tS }) {
      tilesets[tS] = load_tileset(tS)
    }
  }
  let object_animation_sets = {}
  for layer in nx_map.layers {
    for obj in layer.obj {
      let path = ObjectAnimationPath::from_obj(obj)
      let sets = object_animation_sets.get_or_init(obj.oS, fn() { Map::new() })
      sets[path] = load_obj_animation(obj.oS, path)
    }
  }
  let bs_loader = get_background_set_loader()
  let background_animation_sets = {}
  for background in nx_map.back.0 {
    let sets = background_animation_sets.get_or_init(background.bS, fn() {
      Map::new()
    })
    let path = BackgroundAnimationPath::from_nx(background)
    sets[path] = load_background_animation(bs_loader, background.bS, path)
  }
  {
    id: map_id,
    nx_map,
    tilesets,
    object_animation_sets,
    background_animation_sets,
    root: src,
  }
}

///|
pub fn MapRawResources::get_layers(self : MapRawResources) -> Array[NxLayer] {
  self.nx_map.layers
}

///|
pub fn MapRawResources::get_backgrounds(
  self : MapRawResources,
) -> BackgroundsResource {
  self.nx_map.back
}

///|
pub fn MapRawResources::get_portals(self : MapRawResources) -> Array[NxPortal] {
  self.nx_map.portal
}

///|
pub struct NxMap {
  layers : Array[NxLayer]
  back : BackgroundsResource
  portal : Array[NxPortal]
  foothold : @physics.NxFootholdTree
  mini_map : MiniMapResource?
  life : Array[NxLife]
}

///|
pub impl @json.FromJson for NxMap with from_json(json, path) {
  let layers = @resource.parse_map_based_array(json, path~)
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let back : BackgroundsResource = if obj.get("back") is Some(back) {
    @json.from_json(back, path=path.add_key("back"))
  } else {
    BackgroundsResource([])
  }
  let portal : Array[NxPortal] = if obj.get("portal") is Some(portal) {
    @resource.parse_map_based_array(portal, path=path.add_key("portal"))
  } else {
    []
  }
  let foothold = if obj.get("foothold") is Some(foothold) {
    @json.from_json(foothold, path=path.add_key("foothold"))
  } else {
    @physics.NxFootholdTree(Map::new())
  }
  let mini_map = if obj.get("mini_map") is Some(mini_map) {
    @json.from_json(mini_map, path=path.add_key("mini_map"))
  } else {
    None
  }
  let life : Array[NxLife] = if obj.get("life") is Some(life) {
    @resource.parse_map_based_array(life, path=path.add_key("life"))
  } else {
    []
  }
  { layers, back, portal, foothold, mini_map, life }
}

///|
pub struct NxLayer {
  info : MapLayerInfoResource?
  tile : Array[NxTileRef]
  obj : Array[NxObj]
} derive(Show)

///|
pub impl @json.FromJson for NxLayer with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let info = if obj is { "info": Object(_) as info, .. } {
    Some(@json.from_json(info, path=path.add_key("info")))
  } else {
    None
  }
  let tile = if obj is { "tile": Object(_) as tile, .. } {
    @resource.parse_map_based_array(tile, path=path.add_key("tile"))
  } else {
    []
  }
  let obj = if obj is { "obj": Object(_) as obj, .. } {
    @resource.parse_map_based_array(obj, path=path.add_key("obj"))
  } else {
    []
  }
  { info, tile, obj }
}

///|
test "parse empty layer" {
  let data =
    #|{
    #|    "info": null,
    #|    "obj": null,
    #|    "tile": null
    #|}
  let json = @json.parse(data)
  let layer : NxLayer = @json.from_json(json)
  inspect(layer, content="{info: None, tile: [], obj: []}")
}

///|
pub struct NxTileRef {
  /// tile index
  no : Int
  /// group name
  u : String
  x : Int
  y : Int
  zM : Int
} derive(@json.FromJson, Show)

///|
pub struct NxObj {
  f : Bool
  l0 : String
  l1 : String
  l2 : String
  oS : String
  x : Int
  y : Int
  z : Int
  zM : Int
} derive(Show)

///|
pub impl @json.FromJson for NxObj with from_json(json, path) {
  match json {
    {
      "f": Number(f, ..),
      "l0": String(l0),
      "l1": String(l1),
      "l2": String(l2),
      "oS": String(oS),
      "x": Number(x, ..),
      "y": Number(y, ..),
      "z": Number(z, ..),
      "zM": Number(zM, ..),
      ..
    } =>
      {
        f: f != 0,
        l0,
        l1,
        l2,
        oS,
        x: x.to_int(),
        y: y.to_int(),
        z: z.to_int(),
        zM: zM.to_int(),
      }
    _ => raise @json.JsonDecodeError((path, "missing obj fields"))
  }
}

///|
pub struct MapLayerInfoResource {
  tS : String
} derive(@json.FromJson, Show)

///|
pub struct NxLife {
  cy : Int
  f : Int
  fh : Int
  hide : Int
  id : String
  mob_time : Int? // mobTime can be null or missing
  rx0 : Int
  rx1 : Int
  type_ : String
  x : Int
  y : Int
} derive(Show)

///|
pub impl @json.FromJson for NxLife with from_json(json, path) {
  match json {
    {
      "cy": Number(cy, ..),
      "fh": Number(fh, ..),
      "id": String(id),
      "rx0": Number(rx0, ..),
      "rx1": Number(rx1, ..),
      "type": String(type_),
      "x": Number(x, ..),
      "y": Number(y, ..),
      ..
    } => {
      // f, hide, mobTime are optional
      let f = if json is { "f": Number(f, ..), .. } { f.to_int() } else { 0 }
      let hide = if json is { "hide": Number(hide, ..), .. } {
        hide.to_int()
      } else {
        0
      }
      let mob_time = if json is { "mobTime": Number(mob_time, ..), .. } {
        Some(mob_time.to_int())
      } else {
        None
      }
      {
        cy: cy.to_int(),
        f,
        fh: fh.to_int(),
        hide,
        id,
        mob_time,
        rx0: rx0.to_int(),
        rx1: rx1.to_int(),
        type_,
        x: x.to_int(),
        y: y.to_int(),
      }
    }
    _ => raise @json.JsonDecodeError((path, "missing life fields"))
  }
}

///|
test "parse misssing" {
  let src : Json = {
    "cy": 274,
    "fh": 126,
    "id": "1012000",
    "rx0": 99,
    "rx1": 199,
    "type": "n",
    "x": 149,
    "y": 267,
  }
  let life : NxLife = @json.from_json(src)
  inspect(
    life,
    content=(
      #|{cy: 274, f: 0, fh: 126, hide: 0, id: "1012000", mob_time: None, rx0: 99, rx1: 199, type_: "n", x: 149, y: 267}
    ),
  )
}
