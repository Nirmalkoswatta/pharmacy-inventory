import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const OrderDetail = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Order Details
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>
          Order detail view will be implemented here.
        </Typography>
      </Paper>
    </Box>
  );
};

export default OrderDetail;
