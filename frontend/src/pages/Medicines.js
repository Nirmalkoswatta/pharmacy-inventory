import React, { useState, useEffect } from 'react';
import { useQuery, useMutation } from '@apollo/client';
import {
  Box,
  Typography,
  Button,
  Paper,
  CircularProgress,
  Alert,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Card,
  CardContent,
  Grid,
  Fade,
} from '@mui/material';
import { motion, AnimatePresence } from 'framer-motion';
import { DataGrid } from '@mui/x-data-grid';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { toast } from 'react-hot-toast';
import AOS from 'aos';

import { GET_MEDICINES, GET_ACTIVE_SUPPLIERS } from '../graphql/queries';
import { DELETE_MEDICINE } from '../graphql/mutations';
import styles from '../styles/medicines.module.scss';

const Medicines = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedMedicine, setSelectedMedicine] = useState(null);
  const [viewMode, setViewMode] = useState('grid'); // 'grid' or 'table'

  // Initialize AOS animations
  useEffect(() => {
    AOS.init({
      duration: 600,
      easing: 'ease-out-cubic',
      once: true,
    });
  }, []);

  const { loading, error, data, refetch } = useQuery(GET_MEDICINES, {
    variables: {
      search: searchTerm || undefined,
      filter: categoryFilter ? { category: categoryFilter } : undefined,
    },
    fetchPolicy: 'cache-and-network',
  });

  const { data: suppliersData } = useQuery(GET_ACTIVE_SUPPLIERS);

  const [deleteMedicine] = useMutation(DELETE_MEDICINE, {
    onCompleted: () => {
      toast.success('Medicine deleted successfully');
      refetch();
      setDeleteDialogOpen(false);
      setSelectedMedicine(null);
    },
    onError: (error) => {
      toast.error(`Error deleting medicine: ${error.message}`);
    },
  });

  const handleDelete = async () => {
    if (selectedMedicine) {
      await deleteMedicine({ variables: { id: selectedMedicine.id } });
    }
  };

  const getStatusChip = (medicine) => {
    if (medicine.isExpired) {
      return <Chip label="Expired" color="error" size="small" icon={<ErrorIcon />} />;
    }
    if (medicine.isExpiringSoon) {
      return <Chip label="Expiring Soon" color="warning" size="small" icon={<WarningIcon />} />;
    }
    if (medicine.isLowStock) {
      return <Chip label="Low Stock" color="warning" size="small" icon={<WarningIcon />} />;
    }
    return <Chip label="Normal" color="success" size="small" />;
  };

  const columns = [
    {
      field: 'name',
      headerName: 'Medicine Name',
      width: 200,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="bold">
            {params.value}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {params.row.manufacturer}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'category',
      headerName: 'Category',
      width: 120,
    },
    {
      field: 'stockQuantity',
      headerName: 'Stock',
      width: 100,
      type: 'number',
      renderCell: (params) => (
        <Typography
          color={params.row.isLowStock ? 'error' : 'text.primary'}
          fontWeight={params.row.isLowStock ? 'bold' : 'normal'}
        >
          {params.value}
        </Typography>
      ),
    },
    {
      field: 'price',
      headerName: 'Price (₹)',
      width: 100,
      type: 'number',
      valueFormatter: (params) => `₹${params.value}`,
    },
    {
      field: 'expiryDate',
      headerName: 'Expiry Date',
      width: 120,
      valueFormatter: (params) => new Date(params.value).toLocaleDateString(),
    },
    {
      field: 'supplier',
      headerName: 'Supplier',
      width: 150,
      valueGetter: (params) => params.row.supplier?.name || 'N/A',
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 130,
      renderCell: (params) => getStatusChip(params.row),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      sortable: false,
      renderCell: (params) => (
        <Box>
          <IconButton size="small" onClick={() => handleEdit(params.row)}>
            <EditIcon />
          </IconButton>
          <IconButton
            size="small"
            onClick={() => {
              setSelectedMedicine(params.row);
              setDeleteDialogOpen(true);
            }}
          >
            <DeleteIcon />
          </IconButton>
        </Box>
      ),
    },
  ];

  const handleEdit = (medicine) => {
    // TODO: Implement edit functionality
    toast.info('Edit functionality coming soon!');
  };

  const getStockStatus = (medicine) => {
    if (medicine.stockQuantity <= 10) return 'low-stock';
    if (medicine.stockQuantity <= 50) return 'medium-stock';
    return 'high-stock';
  };

  const getExpiryStatus = (medicine) => {
    if (medicine.isExpired) return 'expired';
    if (medicine.isExpiringSoon) return 'expires-soon';
    return 'fresh';
  };

  const renderMedicineCard = (medicine) => (
    <motion.div
      key={medicine.id}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
      className={styles.medicineCard}
      data-aos="fade-up"
    >
      <div className={styles.medicineName}>{medicine.name}</div>
      
      <div className={styles.medicineDetails}>
        <div className={styles.detailItem}>
          <span className={styles.label}>Category:</span>
          <span className={styles.value}>{medicine.category}</span>
        </div>
        <div className={styles.detailItem}>
          <span className={styles.label}>Manufacturer:</span>
          <span className={styles.value}>{medicine.manufacturer}</span>
        </div>
        <div className={styles.detailItem}>
          <span className={styles.label}>Price:</span>
          <span className={styles.value}>₹{medicine.price}</span>
        </div>
        <div className={styles.detailItem}>
          <span className={styles.label}>Stock:</span>
          <span className={`${styles.stockIndicator} ${styles[getStockStatus(medicine)]}`}>
            {medicine.stockQuantity} units
          </span>
        </div>
        <div className={styles.detailItem}>
          <span className={styles.label}>Expiry:</span>
          <span className={`${styles.expiryIndicator} ${styles[getExpiryStatus(medicine)]}`}>
            {new Date(medicine.expiryDate).toLocaleDateString()}
          </span>
        </div>
        <div className={styles.detailItem}>
          <span className={styles.label}>Supplier:</span>
          <span className={styles.value}>{medicine.supplier?.name || 'N/A'}</span>
        </div>
      </div>

      <div className={styles.medicineActions}>
        <button 
          className={`${styles.actionBtn} ${styles.editBtn}`}
          onClick={() => handleEdit(medicine)}
        >
          <EditIcon fontSize="small" />
          Edit
        </button>
        <button 
          className={`${styles.actionBtn} ${styles.deleteBtn}`}
          onClick={() => {
            setSelectedMedicine(medicine);
            setDeleteDialogOpen(true);
          }}
        >
          <DeleteIcon fontSize="small" />
          Delete
        </button>
      </div>
    </motion.div>
  );

  if (loading) {
    return (
      <div className={styles.medicinesContainer}>
        <div className="loading-skeleton">
          {[...Array(6)].map((_, index) => (
            <div key={index} className={styles.loadingSkeleton}>
              <div className="skeleton-line title"></div>
              <div className="skeleton-line subtitle"></div>
              <div className="skeleton-line content"></div>
              <div className="skeleton-line content"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.medicinesContainer}>
        <Alert severity="error" sx={{ mt: 2 }}>
          Error loading medicines: {error.message}
        </Alert>
      </div>
    );
  }

  return (
    <div className={styles.medicinesContainer}>
      {/* Header */}
      <motion.div 
        className={styles.medicinesHeader}
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <h1>Medicines Inventory</h1>
        <motion.button
          className={styles.addMedicineBtn}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => toast.info('Add medicine functionality coming soon!')}
        >
          <AddIcon />
          Add New Medicine
        </motion.button>
      </motion.div>

      {/* Filters */}
      <motion.div 
        className={styles.medicineFilters}
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Search:</label>
          <input
            type="text"
            className={styles.searchBox}
            placeholder="Search medicines..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Category:</label>
          <select
            className={styles.filterSelect}
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="">All Categories</option>
            <option value="Tablet">Tablet</option>
            <option value="Capsule">Capsule</option>
            <option value="Syrup">Syrup</option>
            <option value="Injection">Injection</option>
            <option value="Cream">Cream</option>
            <option value="Ointment">Ointment</option>
            <option value="Other">Other</option>
          </select>
        </div>

        <button
          className="btn btn-outline"
          onClick={() => {
            setSearchTerm('');
            setCategoryFilter('');
            refetch();
          }}
        >
          Clear Filters
        </button>
      </motion.div>

      {/* Medicines Grid */}
      {data?.medicines?.length === 0 ? (
        <motion.div 
          className={styles.emptyState}
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.6 }}
        >
          <div className={styles.emptyIcon}>💊</div>
          <h2 className={styles.emptyTitle}>No Medicines Found</h2>
          <p className={styles.emptyDescription}>
            No medicines match your current filters. Try adjusting your search criteria or add a new medicine to get started.
          </p>
          <button 
            className={styles.emptyAction}
            onClick={() => toast.info('Add medicine functionality coming soon!')}
          >
            Add Your First Medicine
          </button>
        </motion.div>
      ) : (
        <AnimatePresence>
          <motion.div 
            className={`${styles.medicinesGrid} ${styles.staggerAnimation}`}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            {data?.medicines?.map((medicine) => renderMedicineCard(medicine))}
          </motion.div>
        </AnimatePresence>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        TransitionComponent={Fade}
        TransitionProps={{ timeout: 300 }}
      >
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete "{selectedMedicine?.name}"? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDelete} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default Medicines;
