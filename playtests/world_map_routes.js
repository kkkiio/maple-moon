const bot = globalThis.__bot;

const assert = (condition, message, data = {}) => {
  if (!condition) {
    const error = new Error(message);
    error.data = data;
    throw error;
  }
};

const routes = [
  { mapId: 101020010, page: "WorldMap010" },
  { mapId: 120000100, page: "WorldMap010" },
  { mapId: 130000000, page: "WorldMap090" },
  { mapId: 140000000, page: "WorldMap100" },
];

const observed = [];
for (const route of routes) {
  await bot.warp(route.mapId, 0, { timeoutFrames: 1800 });
  await bot.idle(30);
  await bot.tap_key("KeyW");

  let worldMap = null;
  for (let attempt = 0; attempt < 180; attempt += 1) {
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

  assert(worldMap?.visible, "World Map did not open", { route, worldMap });
  assert(worldMap.resources_ready, "World Map resources did not load", {
    route,
    worldMap,
  });
  assert(worldMap.has_page, "World Map route did not load a page", {
    route,
    worldMap,
  });
  assert(worldMap.current_world_name === route.page, "World Map route is incorrect", {
    route,
    worldMap,
  });
  assert(worldMap.page_parent_map === "WorldMap", "World Map route is not top-level", {
    route,
    worldMap,
  });
  observed.push({ mapId: route.mapId, page: worldMap.current_world_name });

  await bot.tap_key("KeyW");
  await bot.idle(4);
  const closed = JSON.parse(globalThis.$console.render_game_to_text()).world_map;
  assert(!closed.visible, "World Map did not close between route cases", {
    route,
    closed,
  });
  assert(closed.render_entity_count === 0, "World Map entities remained after close", {
    route,
    closed,
  });
}

return {
  scenario: "world_map_routes",
  observed,
};
