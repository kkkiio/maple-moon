import { ScrollArea, Text } from '@mantine/core';
import { EditorSceneGraph } from '../engine/bridge';

interface AssetsPanelProps {
  sceneGraph: EditorSceneGraph | null;
  selectedObj: any;
  setSelectedObj: (obj: any) => void;
}

/**
 * AssetsPanel Component
 * 
 * Renders the hierarchical tree of objects in the current map.
 * 
 * Functions:
 * - Lists all Background items grouped by type.
 * - Lists all Tile Layers and their object counts.
 * - Allows user to click an item to select it (`setSelectedObj`).
 * - Highlights the currently selected object.
 */
export const AssetsPanel = ({ sceneGraph, selectedObj, setSelectedObj }: AssetsPanelProps) => {
  return (
    <div className="flex flex-col h-full">
      <div className="px-3 py-2 border-b border-gray-300 dark:border-gray-700 bg-gray-100 dark:bg-gray-900/50">
        <Text size="xs" fw={700} c="dimmed" style={{ textTransform: 'uppercase' }}>Assets / Hierarchy</Text>
      </div>
      <ScrollArea className="flex-1" p="xs">
        {sceneGraph ? (
          <div className="space-y-3 text-sm">
            <div>
              <Text size="sm" fw={500}>背景 ({sceneGraph.backgrounds.length})</Text>
              <ul className="list-disc list-inside text-xs text-gray-500 dark:text-gray-400 pl-2">
                {sceneGraph.backgrounds.map(bg => (
                  <li 
                    key={`bg-${bg.id}`}
                    className={`cursor-pointer hover:bg-blue-100 dark:hover:bg-blue-900/30 px-1 rounded ${selectedObj === bg ? 'bg-blue-200 dark:bg-blue-900/50 text-blue-800 dark:text-blue-200' : ''}`}
                    onClick={() => setSelectedObj(bg)}
                  >
                    #{bg.id} {bg.bS}:{bg.no} ({bg.type_})
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <Text size="sm" fw={500}>图层 ({sceneGraph.layers.length})</Text>
              <ul className="list-disc list-inside text-xs text-gray-500 dark:text-gray-400 pl-2">
                {sceneGraph.layers.map(layer => (
                  <li key={`layer-${layer.index}`}>
                    Layer {layer.index}
                    <span className="ml-2 opacity-70">
                      Tiles: {layer.tiles.length}, Objs: {layer.objects.length}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        ) : (
          <div className="p-4 text-center">
            <Text size="sm" c="dimmed">等待地图加载...</Text>
          </div>
        )}
      </ScrollArea>
    </div>
  );
};
