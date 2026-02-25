///|
async test "parse weapon resource" {
  let src : Json = {
    "alert": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [20, 28] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96634",
        },
      },
      "1": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [19, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96635",
        },
      },
      "2": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [20, 26] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96636",
        },
      },
    },
    "fly": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [11, 36] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96656",
        },
      },
      "1": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [11, 36] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96656",
        },
      },
    },
    "heal": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [19, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96635",
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [20, 43] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96641",
        },
      },
      "2": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [31, 41] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96640",
        },
      },
    },
    "info": {
      "afterImage": "mace",
      "attack": 6,
      "attackSpeed": 4,
      "cash": 0,
      "expireOnLogout": 1,
      "icon": {
        "__h": 32,
        "__w": 31,
        "origin": [-1, 32],
        "__i": "/Character/Weapon/spritesheets/01382032.img#96627",
      },
      "iconRaw": {
        "__h": 32,
        "__w": 31,
        "origin": [-1, 32],
        "__i": "/Character/Weapon/spritesheets/01382032.img#96628",
      },
      "incMAD": 80,
      "incPAD": 53,
      "islot": "Wp",
      "notSale": 1,
      "only": 1,
      "price": 200000,
      "reqDEX": 0,
      "reqINT": 168,
      "reqJob": 2,
      "reqLUK": 58,
      "reqLevel": 55,
      "reqSTR": 0,
      "sfx": "mace",
      "stand": 1,
      "tradeBlock": 1,
      "tuc": 7,
      "vslot": "Wp",
      "walk": 1,
    },
    "jump": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [10, 35] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96657",
        },
      },
    },
    "prone": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [48, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96654",
        },
      },
    },
    "proneStab": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [48, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96654",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [63, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96655",
        },
      },
    },
    "shoot1": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [8, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96650",
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [22, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96651",
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [22, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96651",
        },
      },
    },
    "shootF": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [10, 25] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96652",
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [27, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96653",
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [27, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96653",
        },
      },
    },
    "stabO1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [8, 10] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96646",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [49, 26] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96647",
        },
      },
    },
    "stabO2": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [13, 29] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96648",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [46, 24] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96649",
        },
      },
    },
    "stand1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96633",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96633",
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96633",
        },
      },
    },
    "swingO1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [31, 14] },
          "origin": [11, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96637",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [29, 5] },
          "origin": [11, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96638",
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-19, 53] },
          "origin": [11, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96639",
        },
      },
    },
    "swingO2": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [31, 41] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96640",
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [20, 43] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96641",
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-19, 30] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96642",
        },
      },
    },
    "swingO3": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-21, 44] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96643",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [43, 15] },
          "origin": [12, 5],
          "z": "weaponOverBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96644",
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [25, 14] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96645",
        },
      },
    },
    "walk1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [9, 11] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96629",
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [11, 19] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96630",
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [9, 12] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96631",
        },
      },
      "3": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [12, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "/Character/Weapon/spritesheets/01382032.img#96632",
        },
      },
    },
  }
  let spritesheet_json : Json = {
    "meta": {
      "image": "01382032.img.png",
      "size": { "w": 337, "h": 267 },
      "scale": "1",
    },
    "frames": {
      "96639.png": {
        "frame": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96641.png": {
        "frame": { "x": 35, "y": 0, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96642.png": {
        "frame": { "x": 70, "y": 0, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96643.png": {
        "frame": { "x": 105, "y": 0, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96650.png": {
        "frame": { "x": 0, "y": 70, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96651.png": {
        "frame": { "x": 35, "y": 70, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96652.png": {
        "frame": { "x": 70, "y": 70, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96653.png": {
        "frame": { "x": 105, "y": 70, "w": 35, "h": 70 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 35, "h": 70 },
        "sourceSize": { "w": 35, "h": 70 },
      },
      "96629.png": {
        "frame": { "x": 140, "y": 0, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96630.png": {
        "frame": { "x": 140, "y": 35, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96631.png": {
        "frame": { "x": 140, "y": 70, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96632.png": {
        "frame": { "x": 140, "y": 105, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96633.png": {
        "frame": { "x": 0, "y": 140, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96637.png": {
        "frame": { "x": 70, "y": 140, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96638.png": {
        "frame": { "x": 140, "y": 140, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96644.png": {
        "frame": { "x": 0, "y": 175, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96645.png": {
        "frame": { "x": 70, "y": 175, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96646.png": {
        "frame": { "x": 140, "y": 175, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96647.png": {
        "frame": { "x": 210, "y": 0, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96648.png": {
        "frame": { "x": 210, "y": 35, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96649.png": {
        "frame": { "x": 210, "y": 70, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96654.png": {
        "frame": { "x": 210, "y": 105, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96655.png": {
        "frame": { "x": 210, "y": 140, "w": 70, "h": 35 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 70, "h": 35 },
        "sourceSize": { "w": 70, "h": 35 },
      },
      "96634.png": {
        "frame": { "x": 0, "y": 210, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96635.png": {
        "frame": { "x": 57, "y": 210, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96636.png": {
        "frame": { "x": 114, "y": 210, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96640.png": {
        "frame": { "x": 171, "y": 210, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96656.png": {
        "frame": { "x": 280, "y": 0, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96657.png": {
        "frame": { "x": 280, "y": 57, "w": 57, "h": 57 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 57, "h": 57 },
        "sourceSize": { "w": 57, "h": 57 },
      },
      "96627.png": {
        "frame": { "x": 280, "y": 114, "w": 31, "h": 32 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 32 },
        "sourceSize": { "w": 31, "h": 32 },
      },
      "96628.png": {
        "frame": { "x": 280, "y": 146, "w": 31, "h": 32 },
        "rotated": false,
        "trimmed": false,
        "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 32 },
        "sourceSize": { "w": 31, "h": 32 },
      },
    },
  }
  let metadata : @resource.SpritesheetMetadata = @json.from_json(
    spritesheet_json,
  )
  let atlases : Map[String, @resource.SpritesheetMetadata] = {
    "/Character/Weapon/spritesheets/01382032.img": metadata,
  }
  // Skip image operations by not providing load_spritesheet and save_image
  let res = process_resource(
    src,
    atlases,
    "01382032.img",
    "weapon",
    keep_source_sheets=false,
  )
  json_inspect(res, content={
    "alert": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [20, 28] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [0, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [19, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [57, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [20, 26] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [114, 0],
        },
      },
    },
    "fly": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [11, 36] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "weapon/01382032.img.png",
          "__off": [171, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [11, 36] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "weapon/01382032.img.png",
          "__off": [171, 0],
        },
      },
    },
    "heal": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "hand": [19, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [57, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [20, 43] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [228, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [31, 41] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [263, 0],
        },
      },
    },
    "info": {
      "afterImage": "mace",
      "attack": 6,
      "attackSpeed": 4,
      "cash": 0,
      "expireOnLogout": 1,
      "icon": {
        "__h": 32,
        "__w": 31,
        "origin": [-1, 32],
        "__i": "weapon/01382032.img.png",
        "__off": [320, 0],
      },
      "iconRaw": {
        "__h": 32,
        "__w": 31,
        "origin": [-1, 32],
        "__i": "weapon/01382032.img.png",
        "__off": [351, 0],
      },
      "incMAD": 80,
      "incPAD": 53,
      "islot": "Wp",
      "notSale": 1,
      "only": 1,
      "price": 200000,
      "reqDEX": 0,
      "reqINT": 168,
      "reqJob": 2,
      "reqLUK": 58,
      "reqLevel": 55,
      "reqSTR": 0,
      "sfx": "mace",
      "stand": 1,
      "tradeBlock": 1,
      "tuc": 7,
      "vslot": "Wp",
      "walk": 1,
    },
    "jump": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [10, 35] },
          "origin": [13, 5],
          "z": "weaponOverArm",
          "__i": "weapon/01382032.img.png",
          "__off": [382, 0],
        },
      },
    },
    "prone": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [48, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "weapon/01382032.img.png",
          "__off": [439, 0],
        },
      },
    },
    "proneStab": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [48, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "weapon/01382032.img.png",
          "__off": [439, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [63, 15] },
          "origin": [5, 3],
          "z": "weaponBelowArm",
          "__i": "weapon/01382032.img.png",
          "__off": [509, 0],
        },
      },
    },
    "shoot1": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [8, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [579, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [22, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [614, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [22, 21] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [614, 0],
        },
      },
    },
    "shootF": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [10, 25] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [649, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [27, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [684, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "hand": [27, 27] },
          "origin": [23, 10],
          "z": "weaponOverHand",
          "__i": "weapon/01382032.img.png",
          "__off": [684, 0],
        },
      },
    },
    "stabO1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [8, 10] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [719, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [49, 26] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [789, 0],
        },
      },
    },
    "stabO2": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [13, 29] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [859, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [46, 24] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [929, 0],
        },
      },
    },
    "stand1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [999, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [999, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [8, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [999, 0],
        },
      },
    },
    "swingO1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [31, 14] },
          "origin": [11, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [1069, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [29, 5] },
          "origin": [11, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [1139, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-19, 53] },
          "origin": [11, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1209, 0],
        },
      },
    },
    "swingO2": {
      "0": {
        "weapon": {
          "__h": 57,
          "__w": 57,
          "map": { "navel": [31, 41] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [263, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [20, 43] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [228, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-19, 30] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1244, 0],
        },
      },
    },
    "swingO3": {
      "0": {
        "weapon": {
          "__h": 70,
          "__w": 35,
          "map": { "navel": [-21, 44] },
          "origin": [12, 5],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1279, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [43, 15] },
          "origin": [12, 5],
          "z": "weaponOverBody",
          "__i": "weapon/01382032.img.png",
          "__off": [1314, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "navel": [25, 14] },
          "origin": [12, 5],
          "z": "weaponBelowBody",
          "__i": "weapon/01382032.img.png",
          "__off": [1384, 0],
        },
      },
    },
    "walk1": {
      "0": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [9, 11] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1454, 0],
        },
      },
      "1": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [11, 19] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1524, 0],
        },
      },
      "2": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [9, 12] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1594, 0],
        },
      },
      "3": {
        "weapon": {
          "__h": 35,
          "__w": 70,
          "map": { "hand": [12, 4] },
          "origin": [25, 7],
          "z": "weapon",
          "__i": "weapon/01382032.img.png",
          "__off": [1664, 0],
        },
      },
    },
  })
}
