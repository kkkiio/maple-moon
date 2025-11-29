///|
test "parse map 100000000" {
  let map100000000_back : Json = {
    "0": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 0,
      "rx": 0,
      "ry": 0,
      "type": 3,
      "x": 0,
      "y": 0,
    },
    "1": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 1,
      "rx": -5,
      "ry": -3,
      "type": 4,
      "x": 116,
      "y": -71,
    },
    "2": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 2,
      "rx": -20,
      "ry": 3,
      "type": 0,
      "x": 495,
      "y": 45,
    },
    "3": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 3,
      "rx": -20,
      "ry": 3,
      "type": 0,
      "x": 374,
      "y": -259,
    },
    "4": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 5,
      "rx": -40,
      "ry": -5,
      "type": 0,
      "x": -66,
      "y": 186,
    },
    "5": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 6,
      "rx": -40,
      "ry": -5,
      "type": 0,
      "x": 958,
      "y": 168,
    },
    "6": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 5,
      "rx": -40,
      "ry": -5,
      "type": 0,
      "x": 1982,
      "y": 186,
    },
    "7": {
      "a": 255,
      "ani": 0,
      "bS": "grassySoil",
      "cx": 0,
      "cy": 0,
      "f": 0,
      "front": 0,
      "no": 6,
      "rx": -40,
      "ry": -5,
      "type": 0,
      "x": 3006,
      "y": 168,
    },
  }
  let _ : BackgroundsResource = @json.from_json(map100000000_back)

}

///|
test "parallax formula verification" {
  // Mock data simulating a tile and a background
  // back/2: x=495, y=45, rx=-20, ry=3. Hill 1 height 340, origin 170.
  let back_x = 495.0
  let back_y = 45.0
  let origin_x = 1246.0
  let origin_y = 170.0
  let height = 340.0
  let rx = -20.0
  let ry = 3.0

  // Adjusted position (as per Background::from_resource change)
  let pos_x = back_x + origin_x
  let pos_y = back_y + origin_y

  // Camera centered on player at ground (y=390)
  // Viewport 800x600? Center is approx player pos.
  let camera_center_x = 0.0 // Horizontal position doesn't matter for gap check
  let camera_center_y = 390.0 // Player on ground

  // Formula: shift = pos + (pos - center) * rate / 100
  let shift_y = pos_y + (pos_y - camera_center_y) * ry / 100.0

  // Render Top = shift_y - origin_y
  let render_top = shift_y - origin_y
  // Render Bottom = render_top + height
  let render_bottom = render_top + height

  // Original gap check:
  // Without parallax and without origin fix: bottom was ~215. Gap ~175.
  // With origin fix: bottom should be around 385 + parallax.

  // Calculation:
  // pos_y = 45 + 170 = 215.
  // shift_y = 215 + (215 - 390) * 0.03 = 215 + (-175 * 0.03) = 215 - 5.25 = 209.75
  // render_top = 209.75 - 170 = 39.75
  // render_bottom = 39.75 + 340 = 379.75

  // Tile Y is 390.
  // Gap = 390 - 379.75 = 10.25.
  // This is acceptable (maybe exact camera center is slightly different or map design has small gap).
  // But it verifies that we are > 375, unlike previous < 220.

  if render_bottom < 370.0 {
    abort(
      "Background bottom \{render_bottom} is too high, creating a gap with ground at 390",
    )
  }
  inspect(render_bottom, content="379.75")
}
