PROJECT_DIR=$(pwd -P)
SCRIPT_DIR="${PROJECT_DIR}/scripts"

export MAPLE_MOON_NODE_MOCK_REQUIRE="--require=${PROJECT_DIR}/src/test/node-dom-mock.js"
case " ${NODE_OPTIONS:-} " in
*" ${MAPLE_MOON_NODE_MOCK_REQUIRE} "*) ;;
*) export NODE_OPTIONS="${MAPLE_MOON_NODE_MOCK_REQUIRE}${NODE_OPTIONS:+ ${NODE_OPTIONS}}" ;;
esac

ENV_FILE="${PROJECT_DIR}/.env.test"
if [ -f "${ENV_FILE}" ]; then
  set -a
  . "${ENV_FILE}"
  set +a
fi
