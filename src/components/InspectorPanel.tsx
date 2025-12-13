import { ScrollArea, Text } from '@mantine/core';

interface InspectorPanelProps {
  selectedObj: any;
}

/**
 * InspectorPanel Component
 * 
 * Displays detailed properties of the currently selected object.
 * 
 * Functions:
 * - Visualizes all key-value pairs of the selected object.
 * - Handles different object types (Backgrounds vs generic Objects).
 * - Shows asset reference paths for debugging.
 * - Renders a placeholder message if no object is selected.
 */
export const InspectorPanel = ({ selectedObj }: InspectorPanelProps) => {
  return (
    <div className="flex flex-col h-full border-t border-gray-300 dark:border-gray-700">
       <div className="px-3 py-2 border-b border-gray-300 dark:border-gray-700 bg-gray-100 dark:bg-gray-900/50">
          <Text size="xs" fw={700} c="dimmed" style={{ textTransform: 'uppercase' }}>Inspector</Text>
       </div>
       <ScrollArea className="flex-1" p="md">
          {selectedObj ? (
            <div className="space-y-3">
               <div>
                 <Text size="sm" fw={700} className="border-b border-gray-200 dark:border-gray-700 pb-1 mb-2">
                   {selectedObj.type_ ? 'Background' : 'Object'} Properties
                 </Text>
                 <div className="space-y-1">
                   {Object.entries(selectedObj).map(([key, value]) => (
                     <div key={key} className="grid grid-cols-[80px_1fr] gap-2 text-xs hover:bg-gray-50 dark:hover:bg-gray-800/50 p-1 rounded">
                        <span className="font-mono text-gray-500 truncate" title={key}>{key}</span>
                        <span className="font-mono break-all" title={String(value)}>{String(value)}</span>
                     </div>
                   ))}
                 </div>
               </div>
               
               {selectedObj.type_ && (
                 <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                   <Text size="xs" c="dimmed" mb="xs">Asset Reference</Text>
                   <div className="text-xs font-mono bg-gray-100 dark:bg-gray-900 p-2 rounded select-all">
                     assets/map/back/{selectedObj.bS}.img.json
                     <br/>
                     (Index: {selectedObj.no})
                   </div>
                 </div>
               )}
            </div>
          ) : (
            <Text size="sm" c="dimmed">选择一个对象查看属性</Text>
          )}
       </ScrollArea>
    </div>
  );
};
