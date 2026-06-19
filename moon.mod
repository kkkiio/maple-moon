name = "KKKIIO/maple-moon"

version = "0.1.0"

import {
  "moonbitlang/async@0.16.8",
  "moonbitlang/x@0.4.41",
  "Milky2018/selene@0.33.2",
  "Milky2018/selene_webgpu@0.33.2",
  "Milky2018/selene_raylib@0.33.2",
  "tonyfettes/raylib@0.3.1",
  "Yoorkin/ArgParser@0.2.0",
}

readme = "README.md"

repository = ""

license = "AGPL-3.0"

keywords = [ ]

description = ""

preferred_target = "native"

warnings = "-28"

options(
  source: "src",
  link: { "native": { "cc": "clang" } },
)
