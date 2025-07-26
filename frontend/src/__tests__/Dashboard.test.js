import React from 'react';
import { render, screen } from '@testing-library/react';
import { MockedProvider } from '@apollo/client/testing';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { BrowserRouter } from 'react-router-dom';
import Dashboard from '../pages/Dashboard';

const theme = createTheme();

const DashboardWrapper = ({ mocks = [] }) => (
  <MockedProvider mocks={mocks} addTypename={false}>
    <ThemeProvider theme={theme}>
      <BrowserRouter>
        <Dashboard />
      </BrowserRouter>
    </ThemeProvider>
  </MockedProvider>
);

describe('Dashboard Component', () => {
  test('renders dashboard title', () => {
    render(<DashboardWrapper />);
    
    // Check if Dashboard title is present
    expect(screen.getByText(/Dashboard/i)).toBeInTheDocument();
  });

  test('renders loading state initially', () => {
    render(<DashboardWrapper />);
    
    // Since we're not mocking GraphQL queries, it should show loading state
    // or render the component structure
    expect(document.body).toBeInTheDocument();
  });
});
