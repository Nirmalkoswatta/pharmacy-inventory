import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const SupplierDetail = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Supplier Details
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>
          Supplier detail view will be implemented here.
        </Typography>
      </Paper>
    </Box>
  );
};

export default SupplierDetail;
