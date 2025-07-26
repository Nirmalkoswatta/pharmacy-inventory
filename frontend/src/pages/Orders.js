import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Orders = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Orders
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>
          Orders management functionality will be implemented here.
        </Typography>
      </Paper>
    </Box>
  );
};

export default Orders;
