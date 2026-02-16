import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Divider,
  Group,
  ScrollArea,
  Stack,
  Text,
  UnstyledButton,
} from '@mantine/core';
import { useEffect, useMemo, useState } from 'react';
import { EditorAPI, EditorSceneGraph, EditorTileObjVisibilityState } from '../engine/bridge';

interface AssetsPanelProps {
  api: EditorAPI | null;
  sceneGraph: EditorSceneGraph | null;
  selectedObj: any;
  setSelectedObj: (obj: any) => void;
}

const DEFAULT_EXPANDED_KEYS = new Set<string>(['layer-root']);

function visibilityLabel(allVisible: boolean, allHidden: boolean): 'ON' | 'OFF' | 'MIX' {
  if (allVisible) return 'ON';
  if (allHidden) return 'OFF';
  return 'MIX';
}

function visibilityColor(label: 'ON' | 'OFF' | 'MIX'): 'green' | 'gray' | 'yellow' {
  if (label === 'ON') return 'green';
  if (label === 'OFF') return 'gray';
  return 'yellow';
}

/**
 * AssetsPanel Component
 *
 * Renders the hierarchical tree of assets in the current map.
 */
export const AssetsPanel = ({ api, sceneGraph, selectedObj, setSelectedObj }: AssetsPanelProps) => {
  const [expandedKeys, setExpandedKeys] = useState<Set<string>>(DEFAULT_EXPANDED_KEYS);
  const [visibility, setVisibility] = useState<EditorTileObjVisibilityState | null>(null);

  useEffect(() => {
    setExpandedKeys(new Set(DEFAULT_EXPANDED_KEYS));
    setVisibility(null);
  }, [sceneGraph]);

  useEffect(() => {
    if (!api) return;
    let animationFrameId = 0;
    const poll = () => {
      const state = api.getTileObjVisibilityState?.();
      if (state) setVisibility(state);
      animationFrameId = requestAnimationFrame(poll);
    };
    poll();
    return () => cancelAnimationFrame(animationFrameId);
  }, [api]);

  const toggleExpanded = (key: string) => {
    setExpandedKeys(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const isExpanded = (key: string) => expandedKeys.has(key);
  const isSelected = (key: string) => selectedObj?.__key === key;

  const layerVisMap = useMemo(() => {
    const map = new Map<number, { tiles_visible: boolean; objs_visible: boolean }>();
    for (const layer of visibility?.layers ?? []) {
      map.set(layer.layer, {
        tiles_visible: layer.tiles_visible,
        objs_visible: layer.objs_visible,
      });
    }
    return map;
  }, [visibility]);

  const renderNode = (params: {
    keyId: string;
    label: string;
    onClick: () => void;
    right?: React.ReactNode;
    dimmed?: boolean;
    indent?: number;
    expandable?: boolean;
    expanded?: boolean;
    onToggleExpand?: () => void;
  }) => {
    const {
      keyId,
      label,
      onClick,
      right,
      dimmed = false,
      indent = 0,
      expandable = false,
      expanded = false,
      onToggleExpand,
    } = params;
    return (
      <Group gap={6} wrap="nowrap" style={{ paddingLeft: indent * 14 }}>
        {expandable ? (
          <ActionIcon variant="subtle" size="sm" onClick={onToggleExpand} aria-label="toggle">
            <Text size="xs">{expanded ? 'v' : '>'}</Text>
          </ActionIcon>
        ) : (
          <Box w={26} />
        )}
        <UnstyledButton
          onClick={onClick}
          style={{
            flex: 1,
            borderRadius: 4,
            padding: '2px 6px',
            opacity: dimmed ? 0.45 : 1,
            color: 'var(--mantine-color-dark-9)',
            background: isSelected(keyId) ? 'var(--mantine-color-blue-light)' : 'transparent',
          }}
        >
          <Text size="sm" fw={500} style={{ color: 'var(--mantine-color-dark-9)' }}>
            {label}
          </Text>
        </UnstyledButton>
        {right}
      </Group>
    );
  };

  return (
    <Stack gap={0} h="100%">
      <Box px="sm" py={8}>
        <Text size="xs" fw={700} c="dimmed" tt="uppercase">Assets / Hierarchy</Text>
      </Box>
      <Divider />
      <ScrollArea flex={1} p="xs">
        {!sceneGraph ? (
          <Box p="md">
            <Text size="sm" c="dimmed" ta="center">等待地图加载...</Text>
          </Box>
        ) : (
          <Stack gap="sm">
            <Box>
              <Text size="lg" fw={700} style={{ color: 'var(--mantine-color-dark-9)' }} mb={4}>
                背景 ({sceneGraph.backgrounds.length})
              </Text>
              <Stack gap={2}>
                {sceneGraph.backgrounds.map(bg => {
                  const key = `bg-${bg.id}`;
                  return renderNode({
                    keyId: key,
                    label: `#${bg.id} ${bg.bS}:${bg.no} (${bg.type_})`,
                    onClick: () => setSelectedObj({ __key: key, ...bg }),
                  });
                })}
              </Stack>
            </Box>

            <Box>
              <Group justify="space-between" mb={6}>
                <Text size="lg" fw={700} style={{ color: 'var(--mantine-color-dark-9)' }}>
                  图层 ({sceneGraph.layers.length})
                </Text>
                <Group gap={6}>
                  <Button
                    size="compact-xs"
                    variant={(visibility?.tiles_visible ?? true) ? 'light' : 'default'}
                    onClick={() => api?.setTilesScopeVisibility(!(visibility?.tiles_visible ?? true))}
                  >
                    Tiles {(visibility?.tiles_visible ?? true) ? 'ON' : 'OFF'}
                  </Button>
                  <Button
                    size="compact-xs"
                    variant={(visibility?.objs_visible ?? true) ? 'light' : 'default'}
                    onClick={() => api?.setObjsScopeVisibility(!(visibility?.objs_visible ?? true))}
                  >
                    Objs {(visibility?.objs_visible ?? true) ? 'ON' : 'OFF'}
                  </Button>
                  <Button size="compact-xs" variant="default" onClick={() => api?.resetTileObjVisibility()}>
                    Reset
                  </Button>
                </Group>
              </Group>

              <Stack gap={2}>
                {sceneGraph.layers.map(layer => {
                  const layerKey = `layer-${layer.index}`;
                  const tilesKey = `tiles-${layer.index}`;
                  const objsKey = `objs-${layer.index}`;
                  const layerVisibility = layerVisMap.get(layer.index);
                  const tileLayerVisible = layerVisibility?.tiles_visible ?? true;
                  const objLayerVisible = layerVisibility?.objs_visible ?? true;
                  const tileItems = visibility?.tile_items[layer.index] ?? [];
                  const objItems = visibility?.obj_items[layer.index] ?? [];
                  const tilesScopeVisible = visibility?.tiles_visible ?? true;
                  const objsScopeVisible = visibility?.objs_visible ?? true;

                  const layerLabel = visibilityLabel(
                    tileLayerVisible && objLayerVisible,
                    !tileLayerVisible && !objLayerVisible,
                  );

                  const tileAllVisible = tileItems.length === 0
                    ? tileLayerVisible && tilesScopeVisible
                    : tileItems.every(Boolean) && tileLayerVisible && tilesScopeVisible;
                  const tileAllHidden = tileItems.length === 0
                    ? !tileLayerVisible || !tilesScopeVisible
                    : tileItems.every(v => !v) || !tileLayerVisible || !tilesScopeVisible;
                  const objAllVisible = objItems.length === 0
                    ? objLayerVisible && objsScopeVisible
                    : objItems.every(Boolean) && objLayerVisible && objsScopeVisible;
                  const objAllHidden = objItems.length === 0
                    ? !objLayerVisible || !objsScopeVisible
                    : objItems.every(v => !v) || !objLayerVisible || !objsScopeVisible;

                  return (
                    <Box key={layerKey}>
                      {renderNode({
                        keyId: layerKey,
                        label: `Layer ${layer.index} (Tiles: ${layer.tiles.length}, Objs: ${layer.objects.length})`,
                        onClick: () => setSelectedObj({
                          __key: layerKey,
                          type: 'Layer',
                          layer: layer.index,
                          tile_count: layer.tiles.length,
                          obj_count: layer.objects.length,
                        }),
                        expandable: true,
                        expanded: isExpanded(layerKey),
                        onToggleExpand: () => toggleExpanded(layerKey),
                        right: (
                          <Badge
                            size="sm"
                            variant="light"
                            color={visibilityColor(layerLabel)}
                            style={{ cursor: 'pointer' }}
                            onClick={() => api?.setLayerVisibility(
                              layer.index,
                              !(tileLayerVisible && objLayerVisible),
                              !(tileLayerVisible && objLayerVisible),
                            )}
                          >
                            {layerLabel}
                          </Badge>
                        ),
                      })}

                      {isExpanded(layerKey) && (
                        <Stack gap={2}>
                          {renderNode({
                            keyId: `${tilesKey}-group`,
                            label: `Tiles (${layer.tiles.length})`,
                            onClick: () => undefined,
                            indent: 1,
                            expandable: true,
                            expanded: isExpanded(tilesKey),
                            onToggleExpand: () => toggleExpanded(tilesKey),
                            right: (
                              <Badge
                                size="sm"
                                variant="light"
                                color={visibilityColor(visibilityLabel(tileLayerVisible, !tileLayerVisible))}
                                style={{ cursor: 'pointer' }}
                                onClick={() => api?.setLayerVisibility(layer.index, !tileLayerVisible, objLayerVisible)}
                              >
                                {visibilityLabel(tileLayerVisible, !tileLayerVisible)}
                              </Badge>
                            ),
                          })}
                          {isExpanded(tilesKey) && (
                            <Stack gap={2}>
                              {layer.tiles.map((tile, idx) => {
                                const key = `tile-${layer.index}-${idx}`;
                                const visible = (tileItems[idx] ?? true) && tileLayerVisible && tilesScopeVisible;
                                return renderNode({
                                  keyId: key,
                                  label: `Tile #${idx} (${tile.x}, ${tile.y}, z=${tile.z})`,
                                  onClick: () => setSelectedObj({
                                    __key: key,
                                    type: 'Tile',
                                    layer: layer.index,
                                    resource_index: idx,
                                    ...tile,
                                  }),
                                  indent: 2,
                                  dimmed: !visible,
                                  right: (
                                    <Badge
                                      size="sm"
                                      variant="light"
                                      color={visible ? 'green' : 'gray'}
                                      style={{ cursor: 'pointer' }}
                                      onClick={() => api?.setTileVisibility(layer.index, idx, !visible)}
                                    >
                                      {visible ? 'ON' : 'OFF'}
                                    </Badge>
                                  ),
                                });
                              })}
                            </Stack>
                          )}

                          {renderNode({
                            keyId: `${objsKey}-group`,
                            label: `Objects (${layer.objects.length})`,
                            onClick: () => undefined,
                            indent: 1,
                            expandable: true,
                            expanded: isExpanded(objsKey),
                            onToggleExpand: () => toggleExpanded(objsKey),
                            right: (
                              <Badge
                                size="sm"
                                variant="light"
                                color={visibilityColor(visibilityLabel(objLayerVisible, !objLayerVisible))}
                                style={{ cursor: 'pointer' }}
                                onClick={() => api?.setLayerVisibility(layer.index, tileLayerVisible, !objLayerVisible)}
                              >
                                {visibilityLabel(objLayerVisible, !objLayerVisible)}
                              </Badge>
                            ),
                          })}
                          {isExpanded(objsKey) && (
                            <Stack gap={2}>
                              {layer.objects.map((obj, idx) => {
                                const key = `obj-${layer.index}-${idx}`;
                                const visible = (objItems[idx] ?? true) && objLayerVisible && objsScopeVisible;
                                return renderNode({
                                  keyId: key,
                                  label: `Obj #${idx} (${obj.x}, ${obj.y}, z=${obj.z})`,
                                  onClick: () => setSelectedObj({
                                    __key: key,
                                    type: 'Object',
                                    layer: layer.index,
                                    resource_index: idx,
                                    ...obj,
                                  }),
                                  indent: 2,
                                  dimmed: !visible,
                                  right: (
                                    <Badge
                                      size="sm"
                                      variant="light"
                                      color={visible ? 'green' : 'gray'}
                                      style={{ cursor: 'pointer' }}
                                      onClick={() => api?.setObjVisibility(layer.index, idx, !visible)}
                                    >
                                      {visible ? 'ON' : 'OFF'}
                                    </Badge>
                                  ),
                                });
                              })}
                            </Stack>
                          )}
                        </Stack>
                      )}
                    </Box>
                  );
                })}
              </Stack>
            </Box>
          </Stack>
        )}
      </ScrollArea>
    </Stack>
  );
};
