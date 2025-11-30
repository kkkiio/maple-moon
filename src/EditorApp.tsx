import { AppShell, Group, ScrollArea, Tabs, Text } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { Allotment } from 'allotment';
import React, { useEffect, useRef, useState } from 'react';
import { initMoonBitEngine, MouseInfo } from './engine/bridge';

type EditorBackground = {
  id: number;
  type_: string;
  bS: string;
  no: number;
  x: number;
  y: number;
  rx: number;
  ry: number;
  type_val: number;
  front: boolean;
};

type EditorTile = {
  x: number;
  y: number;
  z: number;
  _off: number[];
};

type EditorObj = {
  x: number;
  y: number;
  z: number;
  flip: boolean;
};

type EditorLayer = {
  index: number;
  tiles: EditorTile[];
  objects: EditorObj[];
};

type EditorSceneGraph = {
  backgrounds: EditorBackground[];
  layers: EditorLayer[];
};

export default function EditorApp() {
  const [opened, { toggle }] = useDisclosure();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [sceneGraph, setSceneGraph] = useState<EditorSceneGraph | null>(null);
  const [mouseInfo, setMouseInfo] = useState<MouseInfo | null>(null);
  const [activeTab, setActiveTab] = useState<string | null>('assets');

  useEffect(() => {
    let intervalId: number | undefined;
    let animationFrameId: number | undefined;
    
    // Pass the canvas ID string to the engine
    initMoonBitEngine("canvas", (msg, type) => {
      console.log(`[MoonBit ${type}]: ${msg}`);
    }).then(api => {
      console.log("MoonBit Engine Initialized");
      
      const checkGraph = () => {
        const graph = api.getSceneGraph?.();
        if (graph) {
          setSceneGraph(graph);
          return true;
        }
        return false;
      };

      if (!checkGraph()) {
        intervalId = window.setInterval(() => {
          if (checkGraph()) {
            window.clearInterval(intervalId);
          }
        }, 1000);
      }

      // Poll for mouse info
      const pollMouse = () => {
        const info = api.getMouseInfo();
        if (info) {
          setMouseInfo(info);
        }
        animationFrameId = requestAnimationFrame(pollMouse);
      };
      pollMouse();
    });

    return () => {
      if (intervalId) window.clearInterval(intervalId);
      if (animationFrameId) cancelAnimationFrame(animationFrameId);
    };
  }, []);

  return (
    <AppShell
      header={{ height: 40 }}
      footer={{ height: 30 }}
      padding="0"
    >
      <AppShell.Header>
        <Group h="100%" px="md">
          <Text size="sm" fw={700}>Maple Moon Editor</Text>
        </Group>
      </AppShell.Header>

      <AppShell.Main style={{ height: 'calc(100vh - 70px)' }}>
         <Allotment>
            {/* Sidebar: Assets & Inspector */}
            <Allotment.Pane minSize={250} preferredSize={350} maxSize={500}>
              <div className="h-full flex flex-col bg-gray-50 dark:bg-gray-800 border-r border-gray-300 dark:border-gray-700">
                <Tabs value={activeTab} onChange={setActiveTab} className="flex-1 flex flex-col">
                  <Tabs.List>
                    <Tabs.Tab value="assets">Assets / Hierarchy</Tabs.Tab>
                    <Tabs.Tab value="inspector">Inspector</Tabs.Tab>
                  </Tabs.List>

                  <Tabs.Panel value="assets" className="flex-1 overflow-hidden">
                    <ScrollArea h="100%" p="xs">
                      {sceneGraph ? (
                        <div className="space-y-3 text-sm">
                          <div>
                            <Text size="sm" fw={500}>背景 ({sceneGraph.backgrounds.length})</Text>
                            <ul className="list-disc list-inside text-xs text-gray-500 dark:text-gray-400 pl-2">
                              {sceneGraph.backgrounds.map(bg => (
                                <li key={`bg-${bg.id}`}>
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
                  </Tabs.Panel>

                  <Tabs.Panel value="inspector" className="flex-1 overflow-hidden">
                     <ScrollArea h="100%" p="md">
                        <Text size="sm">选择一个对象查看属性</Text>
                     </ScrollArea>
                  </Tabs.Panel>
                </Tabs>
              </div>
            </Allotment.Pane>
            
            {/* Main Canvas Area */}
            <Allotment.Pane>
              <div className="w-full h-full bg-gray-900 overflow-auto flex items-center justify-center p-4">
                 {/* Fixed size canvas wrapper */}
                 <div style={{ width: 1366, height: 768, flexShrink: 0 }} className="bg-black shadow-lg relative">
                    <canvas 
                      ref={canvasRef} 
                      id="canvas" 
                      width={1366}
                      height={768}
                      className="block w-full h-full outline-none cursor-crosshair"
                      onContextMenu={(e) => e.preventDefault()}
                    />
                 </div>
              </div>
            </Allotment.Pane>
          </Allotment>
      </AppShell.Main>

      <AppShell.Footer p="xs" className="flex items-center border-t border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
        <Group justify="space-between" w="100%">
          <Text size="xs" c="dimmed">Ready</Text>
          {mouseInfo && (
             <Group gap="md">
               <Text size="xs" fw={500} style={{ fontFamily: 'monospace' }}>
                 Screen: ({mouseInfo.screen_x}, {mouseInfo.screen_y})
               </Text>
               <Text size="xs" fw={500} style={{ fontFamily: 'monospace' }}>
                 World: ({mouseInfo.world_x}, {mouseInfo.world_y})
               </Text>
             </Group>
          )}
        </Group>
      </AppShell.Footer>
    </AppShell>
  );
}
