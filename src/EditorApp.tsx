import { AppShell, Group, Text } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { Allotment } from 'allotment';
import { useEffect, useMemo, useRef, useState } from 'react';
import { AssetsPanel } from './components/AssetsPanel';
import { FooterInfo } from './components/FooterInfo';
import { InspectorPanel } from './components/InspectorPanel';
import { MapSelector } from './components/MapSelector';
import { StatusPanel } from './components/StatusPanel';
import { EditorAPI, EditorSceneGraph, initMoonBitEngine } from './engine/bridge';
import mapDataRaw from './utils/map.img.json';

export default function EditorApp() {
  const [opened, { toggle }] = useDisclosure();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [sceneGraph, setSceneGraph] = useState<EditorSceneGraph | null>(null);
  const [selectedObj, setSelectedObj] = useState<any | null>(null);
  const [api, setApi] = useState<EditorAPI | null>(null);
  const editorApiRef = useRef<EditorAPI | null>(null);

  const mapOptions = useMemo(() => {
    const options: { group: string; items: { value: string; label: string }[] }[] = [];
    for (const [region, maps] of Object.entries(mapDataRaw)) {
      const items: { value: string; label: string }[] = [];
      for (const [id, info] of Object.entries(maps)) {
        // @ts-ignore
        const label = `${info.mapName} (${id})`;
        items.push({ value: id, label });
      }
      if (items.length > 0) {
        options.push({ group: region, items });
      }
    }
    return options;
  }, []);

  useEffect(() => {
    let intervalId: number | undefined;
    
    // Pass the canvas ID string to the engine
    initMoonBitEngine("canvas", (msg, type) => {
      console.log(`[MoonBit ${type}]: ${msg}`);
    }).then(editorApi => {
      console.log("MoonBit Engine Initialized");
      editorApiRef.current = editorApi;
      setApi(editorApi);
      
      const checkGraph = () => {
        const graph = editorApi.getSceneGraph?.();
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
      
      // Removed main loop polling from here
    });

    return () => {
      if (intervalId) window.clearInterval(intervalId);
      editorApiRef.current?.cleanup();
    };
  }, []);

  const handleMapLoad = () => {
    // Reset selection when map changes
    setSelectedObj(null);
    // Force a re-check of the scene graph after map load
    if (api) {
      const graph = api.getSceneGraph?.();
      if (graph) {
        setSceneGraph(graph);
      }
    }
  };

  return (
    <AppShell
      header={{ height: 40 }}
      footer={{ height: 30 }}
      padding="0"
    >
      <AppShell.Header>
        <Group h="100%" px="md" justify="space-between">
          <Group>
            <Text size="sm" fw={700}>Maple Moon Editor</Text>
          </Group>
          <Group>
             <MapSelector api={api} mapOptions={mapOptions} onMapLoad={handleMapLoad} />
          </Group>
        </Group>
      </AppShell.Header>

      <AppShell.Main style={{ height: 'calc(100vh - 70px)' }}>
         <Allotment>
            {/* Sidebar: Assets & Inspector */}
            <Allotment.Pane minSize={250} preferredSize={350} maxSize={500}>
              <div className="h-full flex flex-col bg-gray-50 dark:bg-gray-800 border-r border-gray-300 dark:border-gray-700">
                <StatusPanel api={api} />
                <div className="flex-1 min-h-0">
                  <Allotment vertical>
                    {/* Assets Panel */}
                    <Allotment.Pane minSize={100}>
                      <AssetsPanel 
                        sceneGraph={sceneGraph} 
                        selectedObj={selectedObj} 
                        setSelectedObj={setSelectedObj} 
                      />
                    </Allotment.Pane>
                    
                    {/* Inspector Panel */}
                    <Allotment.Pane minSize={100} preferredSize={200}>
                       <InspectorPanel selectedObj={selectedObj} />
                    </Allotment.Pane>
                  </Allotment>
                </div>
              </div>
            </Allotment.Pane>
            
            {/* Main Canvas Area */}
            <Allotment.Pane>
              <div className="w-full h-full bg-gray-900 overflow-auto flex items-center justify-center p-4 relative">
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
         <FooterInfo api={api} />
      </AppShell.Footer>
    </AppShell>
  );
}
