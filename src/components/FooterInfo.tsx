import { Group, Text } from '@mantine/core';
import { useEffect, useState } from 'react';
import { EditorAPI, MouseInfo } from '../engine/bridge';

/**
 * FooterInfo Component
 * 
 * Displays low-level interaction info in the application footer.
 * 
 * Functions:
 * - Polls `api.getMouseInfo()` to show real-time mouse coordinates.
 * - Displays Screen coordinates (pixels) and World coordinates (game units).
 * - Shows a simple "Ready / Loading" status text.
 */
export const FooterInfo = ({ api }: { api: EditorAPI | null }) => {
  const [mouseInfo, setMouseInfo] = useState<MouseInfo | null>(null);
  const [statusName, setStatusName] = useState<string>("Initializing...");

  useEffect(() => {
    if (!api) return;
    let animationFrameId: number;

    const poll = () => {
        const info = api.getMouseInfo();
        if (info) setMouseInfo(info);
        
        // Also get basic status for the "Ready" text if needed, or we can just say Ready
        const st = api.getStatus?.();
        if (st) {
            setStatusName(st.loading ? "Loading..." : `Ready (${st.map_name})`);
        }

        animationFrameId = requestAnimationFrame(poll);
    };
    poll();
    
    return () => cancelAnimationFrame(animationFrameId);
  }, [api]);

  return (
    <Group justify="space-between" w="100%">
      <Text size="xs" c="dimmed">{statusName}</Text>
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
  );
};
