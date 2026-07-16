const bot = globalThis.__bot;

const assert = (condition, message, data = {}) => {
  if (!condition) {
    const error = new Error(message);
    error.data = data;
    throw error;
  }
};

await bot.warp(100000000, 0, { timeoutFrames: 1200 });
await bot.idle(30);
await bot.tap_key("KeyW");

let worldMap = null;
for (let attempt = 0; attempt < 120; attempt += 1) {
  await bot.idle(2);
  const state = JSON.parse(globalThis.$console.render_game_to_text());
  worldMap = state.world_map ?? null;
  if (
    worldMap?.visible &&
    worldMap.resources_ready &&
    worldMap.has_page &&
    worldMap.render_entity_count > 0
  ) {
    break;
  }
}

assert(worldMap?.visible, "world map did not become visible", { worldMap });
assert(worldMap.resources_ready, "world map UI resources did not load", { worldMap });
assert(worldMap.has_page, "world map page did not load", { worldMap });
assert(worldMap.render_entity_count > 0, "world map did not render sprites", { worldMap });
assert(
  worldMap.current_world_name === "WorldMap010",
  "Henesys opened the wrong World Map page",
  { worldMap },
);
assert(worldMap.page_parent_map === "WorldMap", "World Map parent page is invalid", {
  worldMap,
});

const initialPage = worldMap;
await bot.tap_key("Escape");
let parentPage = null;
for (let attempt = 0; attempt < 120; attempt += 1) {
  await bot.idle(2);
  const state = JSON.parse(globalThis.$console.render_game_to_text());
  parentPage = state.world_map ?? null;
  if (
    parentPage?.visible &&
    parentPage.current_world_name === "WorldMap" &&
    parentPage.has_page &&
    parentPage.render_entity_count > 0
  ) {
    break;
  }
}
assert(parentPage?.visible, "World Map parent page did not stay visible", { parentPage });
assert(parentPage.current_world_name === "WorldMap", "World Map parent page did not open", {
  parentPage,
});
assert(parentPage.has_page, "World Map parent page did not load", { parentPage });
assert(parentPage.page_parent_map === "", "World Map root has an invalid parent", {
  parentPage,
});

await bot.tap_key("Escape");
await bot.idle(4);
const closedPage = JSON.parse(globalThis.$console.render_game_to_text()).world_map;
assert(!closedPage.visible, "World Map did not close from its root page", { closedPage });
assert(closedPage.render_entity_count === 0, "World Map sprites remained after close", {
  closedPage,
});

return {
  scenario: "world_map_smoke",
  initialPage,
  parentPage,
  closedPage,
};
