import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Suppliers = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Suppliers
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>
          Suppliers management functionality will be implemented here.
        </Typography>
      </Paper>
    </Box>
  );
};

export default Suppliers;
