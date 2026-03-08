///|
async test "process bitmap resource" {
  let test_bitmap_json : Json = {
    "Teleport": {
      "0": {
        "__b": 1902,
        "__h": 172,
        "__w": 62,
        "delay": 80,
        "origin": [34, 122],
      },
      "1": {
        "__b": 1903,
        "__h": 143,
        "__w": 45,
        "delay": 80,
        "origin": [25, 105],
      },
    },
    // Non-animation node
    "info": { "foo": "bar" },
  }

  // Skip image operations
  let res = process_bitmap_resource(
    test_bitmap_json, "BasicEff.img", "BasicEff.img",
  )
  json_inspect(res, content={
    "Teleport": {
      "0": {
        "__h": 172,
        "__w": 62,
        "delay": 80,
        "origin": [34, 122],
        "__i": "BasicEff.img/Teleport.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 172,
        "__w": 62,
        "delay": 80,
        "origin": [34, 122],
        "__i": "BasicEff.img/Teleport.png",
        "__off": [62, 0],
      },
    },
    "info": { "foo": "bar" },
  })
}

///|
async test "process simple pack handles mixed world map bitmap tree" {
  let mixed_json : Json = {
    "WorldMap.img": {
      "BaseImg": {
        "0": {
          "__b": 3990,
          "__w": 640,
          "__h": 470,
          "origin": [320, 235],
          "z": "0",
        },
      },
      "MapLink": {
        "0": {
          "link": {
            "linkImg": {
              "__b": 4002,
              "__w": 63,
              "__h": 49,
              "origin": [208, 189],
              "z": "1",
            },
            "linkMap": "WorldMap000",
          },
          "toolTip": "Maple Island",
        },
      },
      "MapList": {
        "0": {
          "path": {
            "__b": 3991,
            "__w": 112,
            "__h": 125,
            "origin": [279, 180],
            "z": "2",
          },
          "spot": [-178, -169],
          "title": "Maple Island",
          "type": "3",
        },
        "1": {
          "path": {
            "__b": 3991,
            "__w": 112,
            "__h": 125,
            "origin": [279, 180],
            "z": "2",
          },
          "spot": [-100, -100],
          "title": "Maple Island Copy",
          "type": "3",
        },
      },
      "info": { "parentMap": "WorldMap" },
    },
    "curPos": {
      "0": {
        "__b": 1725,
        "__w": 17,
        "__h": 35,
        "delay": "180",
        "origin": [9, 42],
      },
      "1": {
        "__b": 1726,
        "__w": 17,
        "__h": 35,
        "delay": "180",
        "origin": [9, 40],
      },
    },
  }

  let res = process_resource(
    mixed_json,
    {},
    "WorldMap",
    "map/WorldMap",
    bitmaps_dir="unused",
    keep_source_sheets=false,
  )
  fn expect_processed_frame(
    json : Json,
    expected_path : String,
    expected_width : Int,
    expected_height : Int,
  ) -> (Int, Int) raise {
    match json {
      {
        "__i": String(image_path),
        "__off": [Number(off_x, ..), Number(off_y, ..)],
        "__w": Number(w, ..),
        "__h": Number(h, ..),
        ..
      } => {
        assert_eq(image_path, expected_path)
        assert_eq(w.to_int(), expected_width)
        assert_eq(h.to_int(), expected_height)
        match json {
          Object(obj) =>
            match obj.get("__b") {
              None => ()
              Some(_) => fail("expected processed frame to remove __b")
            }
          _ => fail("expected frame object")
        }
        (off_x.to_int(), off_y.to_int())
      }
      _ => fail("expected processed frame")
    }
  }

  guard res
    is {
      "WorldMap.img": {
        "BaseImg": { "0": { } as base_img_json, .. },
        "MapLink": {
          "0": {
            "link": {
              "linkImg": { } as link_img_json,
              "linkMap": "WorldMap000",
              ..
            },
            "toolTip": "Maple Island",
            ..
          },
          ..
        },
        "MapList": {
          "0": {
            "path": { } as map_path0_json,
            "spot": [-178, -169],
            "title": "Maple Island",
            "type": "3",
            ..
          },
          "1": {
            "path": { } as map_path1_json,
            "spot": [-100, -100],
            "title": "Maple Island Copy",
            "type": "3",
            ..
          },
          ..
        },
        "info": { "parentMap": "WorldMap", .. },
        ..
      },
      "curPos": {
        "0": { "delay": "180", "origin": [9, 42], .. } as cur_pos0_json,
        "1": { "delay": "180", "origin": [9, 40], .. } as cur_pos1_json,
        ..
      },
      ..
    } else {
    fail("unexpected processed world map json")
  }

  let base_off = expect_processed_frame(
    base_img_json, "map/WorldMap/WorldMap.png", 640, 470,
  )
  let link_off = expect_processed_frame(
    link_img_json, "map/WorldMap/WorldMap.png", 63, 49,
  )
  let path0_off = expect_processed_frame(
    map_path0_json, "map/WorldMap/WorldMap.png", 112, 125,
  )
  let path1_off = expect_processed_frame(
    map_path1_json, "map/WorldMap/WorldMap.png", 112, 125,
  )
  let cur_pos0_off = expect_processed_frame(
    cur_pos0_json, "map/WorldMap/WorldMap.png", 17, 35,
  )
  let cur_pos1_off = expect_processed_frame(
    cur_pos1_json, "map/WorldMap/WorldMap.png", 17, 35,
  )

  assert_eq(base_off.1, 0)
  assert_eq(link_off.1, 0)
  assert_eq(path0_off.1, 0)
  assert_eq(path1_off.1, 0)
  assert_eq(cur_pos0_off.1, 0)
  assert_eq(cur_pos1_off.1, 0)

  assert_true(base_off.0 != link_off.0)
  assert_true(base_off.0 != path0_off.0)
  assert_true(base_off.0 != cur_pos0_off.0)
  assert_true(link_off.0 != path0_off.0)
  assert_true(link_off.0 != cur_pos0_off.0)
  assert_true(path0_off.0 != cur_pos0_off.0)
  assert_eq(path0_off.0, path1_off.0)
  assert_true(cur_pos0_off.0 != cur_pos1_off.0)
}
