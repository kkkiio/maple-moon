import { MantineProvider } from '@mantine/core';
import '@mantine/core/styles.css';
import 'allotment/dist/style.css';
import React from 'react';
import ReactDOM from 'react-dom/client';
import EditorApp from './EditorApp';
import './style.css';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(
  <React.StrictMode>
    <MantineProvider defaultColorScheme="dark">
      <EditorApp />
    </MantineProvider>
  </React.StrictMode>
);

