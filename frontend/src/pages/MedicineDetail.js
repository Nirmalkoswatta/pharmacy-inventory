import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const MedicineDetail = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Medicine Details
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>
          Medicine detail view will be implemented here.
        </Typography>
      </Paper>
    </Box>
  );
};

export default MedicineDetail;
