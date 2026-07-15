///|
test "portal tile object uses resource anchor properties for logic position" {
  let map = @tiled.TiledMap::from_tiled_json({
    "type": "map",
    "width": 1,
    "height": 1,
    "tilewidth": 1,
    "tileheight": 1,
    "layers": [
      {
        "id": 1,
        "name": "portal",
        "type": "objectgroup",
        "opacity": 1,
        "visible": true,
        "objects": [
          {
            "id": 1,
            "x": 5863,
            "y": 464,
            "gid": 1,
            "width": 89,
            "height": 257,
            "visible": true,
            "properties": [
              { "name": "x", "type": "int", "value": 5907 },
              { "name": "y", "type": "int", "value": 455 },
              { "name": "pn", "type": "string", "value": "east00" },
              { "name": "pt", "type": "int", "value": 2 },
              { "name": "tm", "type": "int", "value": 100010000 },
              { "name": "tn", "type": "string", "value": "west00" },
            ],
          },
        ],
      },
    ],
    "tilesets": [],
  })
  let portals = MapPortals::from_tiled_map(
    map,
    100000000,
    MapPortalAnimations::load(),
  )
  guard portals.get_portal_pos_by_id(0) is Some(spawn) else {
    fail("missing portal id 0")
  }
  debug_inspect(
    (
      spawn,
      portals.find_manual_warp_at(Point(5907, 455)).map(fn(warp) { warp.name }),
    ),
    content=(
      #|({ x: 5907, y: 425 }, Some("east00"))
    ),
  )
  assert_true(portals.find_manual_warp_at(Point(5863, 464)) is None)
}
