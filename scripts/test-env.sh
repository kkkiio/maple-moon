export MAPLE_MOON_NODE_MOCK_REQUIRE="--require=./src/apps/game/node-dom-mock.js"
if [ -n "${NODE_OPTIONS:-}" ]; then
  export NODE_OPTIONS="${MAPLE_MOON_NODE_MOCK_REQUIRE} ${NODE_OPTIONS}"
else
  export NODE_OPTIONS="${MAPLE_MOON_NODE_MOCK_REQUIRE}"
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ENV_FILE="${SCRIPT_DIR}/../.env.test"
if [ -f "${ENV_FILE}" ]; then
  set -a
  . "${ENV_FILE}"
  set +a
fi
