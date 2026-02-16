import { Badge, Text } from '@mantine/core';
import { useEffect, useState } from 'react';
import { EditorAPI, EditorStatus } from '../engine/bridge';

/**
 * StatusPanel Component
 * 
 * Displays real-time status information about the editor state.
 * 
 * Functions:
 * - Polls `api.getStatus()` every animation frame to update data.
 * - Shows Map ID/Name, Camera Position, Zoom Level, and FPS.
 * - Displays and colors visibility badges (BG, Tiles, Objects).
 * - Shows debug info like active layers and debug indices.
 * 
 * Usage:
 * - Placed in the sidebar for persistent visibility without obstructing the canvas.
 */
export const StatusPanel = ({ api }: { api: EditorAPI | null }) => {
  const [status, setStatus] = useState<EditorStatus | null>(null);

  useEffect(() => {
    if (!api) return;
    let animationFrameId: number;
    
    const poll = () => {
      const st = api.getStatus?.();
      if (st) setStatus(st);
      animationFrameId = requestAnimationFrame(poll);
    };
    poll();

    return () => cancelAnimationFrame(animationFrameId);
  }, [api]);

  if (!status) return (
    <div className="p-3 border-b border-gray-300 dark:border-gray-700 bg-gray-100 dark:bg-gray-900/50 text-center">
       <Text size="xs" c="dimmed">Status: Offline</Text>
    </div>
  );

  return (
    <div className="p-3 border-b border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
       <div className="space-y-2 text-xs font-mono">
          <div className="text-sm font-bold text-gray-700 dark:text-gray-200 truncate" title={`Map ${status.map_id}: ${status.map_name}`}>
            {status.loading ? "Loading..." : status.error_msg ? `Error: ${status.error_msg}` : `${status.map_name} (${status.map_id})`}
          </div>
          
          <div className="grid grid-cols-2 gap-x-2 gap-y-1 text-gray-600 dark:text-gray-400">
             <div>Cam: {status.cam_x}, {status.cam_y}</div>
             <div>Zoom: {status.zoom.toFixed(2)}</div>
             <div>FPS: {status.fps.toFixed(0)}</div>
          </div>

          <div className="h-px bg-gray-300 dark:bg-gray-700 my-1"></div>

          <div className="flex flex-wrap gap-1 items-center">
            <Badge size="xs" color={status.bg_visible ? "green" : "gray"} variant="light">BG(Q)</Badge>
          </div>
          
          <div className="text-gray-500 text-[10px]">
             Layers: {status.bg_back_visible ? "ON" : "OFF"}/{status.bg_fore_visible ? "ON" : "OFF"} 
             <span className="mx-1">|</span>
             Debug: {status.bg_debug_index !== undefined ? `${status.bg_debug_index + 1}/${status.bg_total_layers}` : "ALL"}
          </div>
       </div>
    </div>
  );
};
