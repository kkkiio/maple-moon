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

const DEFAULT_MAP_ID = '100030000';

function replaceMapIdQuery(mapId: string) {
  const url = new URL(window.location.href);
  url.searchParams.set('mapId', mapId);
  window.history.replaceState({}, '', url);
}

function pushMapIdQuery(mapId: string) {
  const url = new URL(window.location.href);
  url.searchParams.set('mapId', mapId);
  window.history.pushState({}, '', url);
}

export default function EditorApp() {
  const [opened, { toggle }] = useDisclosure();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [sceneGraph, setSceneGraph] = useState<EditorSceneGraph | null>(null);
  const [selectedObj, setSelectedObj] = useState<any | null>(null);
  const [api, setApi] = useState<EditorAPI | null>(null);
  const [selectedMapId, setSelectedMapId] = useState<string>(DEFAULT_MAP_ID);
  const [mapDataRaw, setMapDataRaw] = useState<any>(null);
  const editorApiRef = useRef<EditorAPI | null>(null);
  const lastSceneRevisionRef = useRef<number>(-1);
  const wasLoadingRef = useRef<boolean>(false);

  useEffect(() => {
    fetch('/assets/String/Map.img.json')
      .then(r => r.json())
      .then(setMapDataRaw)
      .catch(e => console.error("Failed to load Map.img.json:", e));
  }, []);

  const { mapOptions, mapIdSet } = useMemo(() => {
    const options: { group: string; items: { value: string; label: string }[] }[] = [];
    const ids = new Set<string>();
    if (!mapDataRaw) return { mapOptions: options, mapIdSet: ids };
    for (const [region, maps] of Object.entries(mapDataRaw)) {
      const items: { value: string; label: string }[] = [];
      for (const [id, info] of Object.entries(maps as any)) {
        // @ts-ignore
        const label = `${info.mapName} (${id})`;
        items.push({ value: id, label });
        ids.add(id);
      }
      if (items.length > 0) {
        options.push({ group: region, items });
      }
    }
    return { mapOptions: options, mapIdSet: ids };
  }, [mapDataRaw]);

  useEffect(() => {
    if (mapIdSet.size === 0) return;
    const search = new URLSearchParams(window.location.search);
    const mapId = search.get('mapId');
    const validMapId = mapId && mapIdSet.has(mapId) ? mapId : DEFAULT_MAP_ID;
    setSelectedMapId(validMapId);
    if (mapId !== validMapId) {
      replaceMapIdQuery(validMapId);
    }
    const onPopState = () => {
      const nextSearch = new URLSearchParams(window.location.search);
      const nextMapId = nextSearch.get('mapId');
      const nextValidMapId = nextMapId && mapIdSet.has(nextMapId)
        ? nextMapId
        : DEFAULT_MAP_ID;
      setSelectedMapId(nextValidMapId);
      if (nextMapId !== nextValidMapId) {
        replaceMapIdQuery(nextValidMapId);
      }
    };
    window.addEventListener('popstate', onPopState);
    return () => window.removeEventListener('popstate', onPopState);
  }, [mapIdSet]);

  useEffect(() => {
    // Pass the canvas ID string to the engine
    initMoonBitEngine("canvas", (msg, type) => {
      console.log(`[MoonBit ${type}]: ${msg}`);
    }).then(editorApi => {
      console.log("MoonBit Engine Initialized");
      editorApiRef.current = editorApi;
      setApi(editorApi);
    });

    return () => {
      editorApiRef.current?.cleanup();
    };
  }, []);

  useEffect(() => {
    if (!api) return;
    const mapId = Number.parseInt(selectedMapId, 10);
    if (Number.isNaN(mapId)) return;
    api.loadMap(mapId);
    setSelectedObj(null);
  }, [api, selectedMapId]);

  useEffect(() => {
    if (!api) return;
    let animationFrameId = 0;

    const poll = () => {
      const status = api.getStatus?.();
      if (status) {
        if (status.loading) {
          if (!wasLoadingRef.current) {
            setSceneGraph(null);
          }
          wasLoadingRef.current = true;
        } else {
          wasLoadingRef.current = false;
          if (status.scene_revision != lastSceneRevisionRef.current) {
            const graph = api.getSceneGraph?.();
            if (graph) {
              setSceneGraph(graph);
              lastSceneRevisionRef.current = status.scene_revision;
            }
          }
        }
      }
      animationFrameId = requestAnimationFrame(poll);
    };
    poll();

    return () => cancelAnimationFrame(animationFrameId);
  }, [api]);

  const handleMapChange = (mapId: string) => {
    setSelectedMapId(mapId);
    pushMapIdQuery(mapId);
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
             <MapSelector
               api={api}
               mapOptions={mapOptions}
               selectedMapId={selectedMapId}
               onMapChange={handleMapChange}
             />
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
                        api={api}
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
