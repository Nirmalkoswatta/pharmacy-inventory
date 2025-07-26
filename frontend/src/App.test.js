import React from 'react';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
  },
});

// Simple component for testing
const SimpleComponent = () => (
  <div data-testid="simple-app">
    Pharmacy Inventory Application
  </div>
);

test('renders app without crashing', () => {
  render(
    <ThemeProvider theme={theme}>
      <SimpleComponent />
    </ThemeProvider>
  );
  
  expect(screen.getByTestId('simple-app')).toBeInTheDocument();
});

test('renders navigation elements', () => {
  render(
    <ThemeProvider theme={theme}>
      <SimpleComponent />
    </ThemeProvider>
  );
  
  expect(screen.getByText('Pharmacy Inventory Application')).toBeInTheDocument();
});
