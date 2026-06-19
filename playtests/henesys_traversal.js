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

let state = bot.state();
assert(state.phase === "GameActive", "game is not active after Henesys warp", state);
assert(state.mapId === 100000000, "expected Henesys map after warp", state);

const portals = bot.nearby_portals();
const portalNames = new Set(portals.map((portal) => portal.name));
for (const name of ["west00", "east00", "east10", "in00", "in01", "in02"]) {
  assert(portalNames.has(name), `missing Henesys portal: ${name}`, { portals });
}

const route = [
  { label: "west road", x: -850, y: 272 },
  { label: "market street", x: 1473, y: 260 },
  { label: "center", x: 2741, y: 259 },
  { label: "mushroom park", x: 3827, y: 368 },
  { label: "east village", x: 4690, y: 300 },
  { label: "east gate", x: 5634, y: 402 },
];

const reached = [];
for (const waypoint of route) {
  await bot.walk_to(waypoint.x, waypoint.y, { timeoutFrames: 2200 });
  state = bot.state();
  assert(state.mapId === 100000000, "left Henesys while traversing", { waypoint, state });
  assert(state.player && Math.abs(state.player.x - waypoint.x) <= 32, "missed waypoint x", { waypoint, state });
  reached.push({ label: waypoint.label, x: state.player.x, y: state.player.y });
  bot.telemetry.log("henesys waypoint", reached[reached.length - 1]);
}

return {
  scenario: "henesys_traversal",
  mapId: state.mapId,
  portalCount: portals.length,
  reached,
};
