import React, { useState, useEffect, useMemo } from 'react';
import { useQuery, useMutation } from '@apollo/client';
import { motion, AnimatePresence } from 'framer-motion';
import { useSpring, animated } from 'react-spring';
import AOS from 'aos';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Fade,
  Alert,
  Chip,
  Snackbar,
  IconButton,
  Tooltip,
  Fab,
  Card,
  CardContent,
  CardHeader,
  CardActions,
  Avatar,
  Box
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Close as CloseIcon,
  Warning as WarningIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Sort as SortIcon,
  Refresh as RefreshIcon,
  Star as StarIcon,
  StarBorder as StarBorderIcon,
  LocalPharmacy as PharmacyIcon
} from '@mui/icons-material';
import { GET_MEDICINES } from '../graphql/queries';
import { CREATE_MEDICINE, UPDATE_MEDICINE, DELETE_MEDICINE } from '../graphql/mutations';
import MedicineForm from '../components/MedicineForm';
import styles from '../styles/medicines.module.scss';
import 'aos/dist/aos.css';

const Medicines = () => {
  // Initialize AOS
  useEffect(() => {
    AOS.init({
      duration: 800,
      easing: 'ease-in-out',
      once: true,
      mirror: false
    });
  }, []);

  // State management
  const [searchTerm, setSearchTerm] = useState('');
  const [activeFilter, setActiveFilter] = useState('All');
  const [sortBy, setSortBy] = useState('name');
  const [selectedMedicine, setSelectedMedicine] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [favorites, setFavorites] = useState(new Set());
  const [notification, setNotification] = useState({ message: '', type: '' });

  // GraphQL queries and mutations
  const { data, loading, error, refetch } = useQuery(GET_MEDICINES);
  
  const [deleteMedicine] = useMutation(DELETE_MEDICINE, {
    refetchQueries: [{ query: GET_MEDICINES }],
    onCompleted: () => {
      setNotification({ message: 'Medicine deleted successfully!', type: 'success' });
      setDeleteDialogOpen(false);
      setSelectedMedicine(null);
    },
    onError: (error) => {
      setNotification({ message: `Error deleting medicine: ${error.message}`, type: 'error' });
    }
  });

  const [createMedicine] = useMutation(CREATE_MEDICINE, {
    refetchQueries: [{ query: GET_MEDICINES }],
    onCompleted: () => {
      setNotification({ message: 'Medicine added successfully!', type: 'success' });
      setIsAddDialogOpen(false);
    },
    onError: (error) => {
      setNotification({ message: `Error adding medicine: ${error.message}`, type: 'error' });
    }
  });

  const [updateMedicine] = useMutation(UPDATE_MEDICINE, {
    refetchQueries: [{ query: GET_MEDICINES }],
    onCompleted: () => {
      setNotification({ message: 'Medicine updated successfully!', type: 'success' });
      setIsEditDialogOpen(false);
      setSelectedMedicine(null);
    },
    onError: (error) => {
      setNotification({ message: `Error updating medicine: ${error.message}`, type: 'error' });
    }
  });

  // Helper functions
  const getStockStatus = (medicine) => {
    if (medicine.stockQuantity <= medicine.minStockLevel) return 'critical';
    if (medicine.stockQuantity <= medicine.minStockLevel * 2) return 'low';
    if (medicine.stockQuantity <= (medicine.maxStockLevel || 100) * 0.7) return 'medium';
    return 'high';
  };

  const getStatusInfo = (medicine) => {
    if (medicine.isExpired) {
      return { status: 'expired', label: 'Expired', icon: <WarningIcon /> };
    }
    if (medicine.isExpiringSoon) {
      return { status: 'expiring', label: 'Expiring Soon', icon: <TrendingDownIcon /> };
    }
    if (medicine.stockQuantity <= medicine.minStockLevel) {
      return { status: 'lowStock', label: 'Low Stock', icon: <TrendingDownIcon /> };
    }
    return { status: 'good', label: 'In Stock', icon: <TrendingUpIcon /> };
  };

  const toggleFavorite = (medicineId) => {
    setFavorites(prev => {
      const newFavorites = new Set(prev);
      if (newFavorites.has(medicineId)) {
        newFavorites.delete(medicineId);
      } else {
        newFavorites.add(medicineId);
      }
      return newFavorites;
    });
  };

  // Filter and sort medicines
  const filteredMedicines = useMemo(() => {
    if (!data?.medicines) return [];

    let filtered = data.medicines.filter(medicine => {
      const matchesSearch = medicine.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           medicine.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           medicine.manufacturer.toLowerCase().includes(searchTerm.toLowerCase());

      const matchesFilter = activeFilter === 'All' ||
                           (activeFilter === 'Low Stock' && medicine.stockQuantity <= medicine.minStockLevel) ||
                           (activeFilter === 'Expiring Soon' && medicine.isExpiringSoon) ||
                           (activeFilter === 'Expired' && medicine.isExpired) ||
                           medicine.category === activeFilter;

      return matchesSearch && matchesFilter;
    });

    // Sort medicines
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'price':
          return a.price - b.price;
        case 'stock':
          return a.stockQuantity - b.stockQuantity;
        case 'expiry':
          return new Date(a.expiryDate) - new Date(b.expiryDate);
        case 'name':
        default:
          return a.name.localeCompare(b.name);
      }
    });

    return filtered;
  }, [data?.medicines, searchTerm, activeFilter, sortBy]);

  // Event handlers
  const handleEdit = (medicine) => {
    setSelectedMedicine(medicine);
    setIsEditDialogOpen(true);
  };

  const handleDelete = async () => {
    if (selectedMedicine) {
      try {
        await deleteMedicine({ variables: { id: selectedMedicine.id } });
      } catch (error) {
        console.error('Error deleting medicine:', error);
      }
    }
  };

  const handleAdd = async (medicineData) => {
    try {
      await createMedicine({ 
        variables: { 
          input: {
            name: medicineData.name,
            description: medicineData.description,
            manufacturer: medicineData.manufacturer,
            category: medicineData.category,
            price: medicineData.price,
            stockQuantity: medicineData.stockQuantity,
            minStockLevel: medicineData.minStockLevel,
            maxStockLevel: medicineData.maxStockLevel,
            batchNumber: medicineData.batchNumber,
            expiryDate: medicineData.expiryDate,
            supplierId: medicineData.supplierId
          }
        } 
      });
    } catch (error) {
      console.error('Error adding medicine:', error);
    }
  };

  const handleUpdate = async (medicineData) => {
    try {
      await updateMedicine({ 
        variables: { 
          id: selectedMedicine.id,
          input: {
            name: medicineData.name,
            description: medicineData.description,
            manufacturer: medicineData.manufacturer,
            category: medicineData.category,
            price: medicineData.price,
            stockQuantity: medicineData.stockQuantity,
            minStockLevel: medicineData.minStockLevel,
            maxStockLevel: medicineData.maxStockLevel,
            batchNumber: medicineData.batchNumber,
            expiryDate: medicineData.expiryDate,
            supplierId: medicineData.supplierId
          }
        } 
      });
    } catch (error) {
      console.error('Error updating medicine:', error);
    }
  };

  // Render medicine card component with enhanced Card design
  const renderMedicineCard = (medicine, index) => (
    <motion.div
      key={medicine.id}
      initial={{ opacity: 0, y: 50, scale: 0.9 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -50, scale: 0.9 }}
      transition={{ 
        duration: 0.6, 
        delay: index * 0.1,
        type: "spring",
        stiffness: 300,
        damping: 30
      }}
      whileHover={{ 
        y: -10,
        scale: 1.02,
        transition: { duration: 0.2 }
      }}
      data-aos="fade-up"
      data-aos-delay={index * 100}
    >
      <Card 
        className={`${styles.medicineCard} ${styles[getStockStatus(medicine)]}`}
        elevation={3}
        sx={{
          position: 'relative',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          background: 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
          border: '1px solid #e3f2fd',
          borderRadius: '16px',
          overflow: 'visible',
          '&:hover': {
            elevation: 8,
            boxShadow: '0 12px 24px rgba(0,0,0,0.15)',
            borderColor: '#2196f3'
          }
        }}
      >
        {/* Favorite Star - Floating */}
        <motion.div 
          className={styles.favoriteButton}
          whileHover={{ scale: 1.2 }}
          whileTap={{ scale: 0.9 }}
          onClick={() => toggleFavorite(medicine.id)}
          style={{
            position: 'absolute',
            top: -8,
            right: -8,
            zIndex: 10,
            background: favorites.has(medicine.id) ? '#ff6b6b' : '#fff',
            borderRadius: '50%',
            width: '32px',
            height: '32px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
            cursor: 'pointer'
          }}
        >
          {favorites.has(medicine.id) ? (
            <StarIcon sx={{ color: 'white', fontSize: '1.2rem' }} />
          ) : (
            <StarBorderIcon sx={{ color: '#666', fontSize: '1.2rem' }} />
          )}
        </motion.div>

        {/* Status Badge - Floating */}
        <Box
          className={`${styles.statusBadge} ${styles[getStatusInfo(medicine).status]}`}
          sx={{
            position: 'absolute',
            top: 12,
            left: 12,
            zIndex: 5,
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: '4px 8px',
            borderRadius: '12px',
            fontSize: '0.75rem',
            fontWeight: 600,
            color: 'white',
            background: getStatusInfo(medicine).status === 'good' ? '#4caf50' :
                       getStatusInfo(medicine).status === 'lowStock' ? '#ff9800' :
                       getStatusInfo(medicine).status === 'expiring' ? '#f44336' : '#9e9e9e',
            boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
          }}
        >
          {getStatusInfo(medicine).icon}
          <span>{getStatusInfo(medicine).label}</span>
        </Box>

        {/* Card Header with Medicine Icon */}
        <CardHeader
          avatar={
            <Avatar 
              sx={{ 
                bgcolor: '#e3f2fd', 
                color: '#1976d2',
                width: 56,
                height: 56
              }}
            >
              <PharmacyIcon sx={{ fontSize: '2rem' }} />
            </Avatar>
          }
          title={
            <Typography 
              variant="h6" 
              sx={{ 
                fontWeight: 600, 
                color: '#1a237e',
                fontSize: '1.1rem',
                lineHeight: 1.2
              }}
            >
              {medicine.name}
            </Typography>
          }
          subheader={
            <Chip 
              label={medicine.category} 
              size="small" 
              variant="outlined"
              sx={{ 
                mt: 1,
                borderColor: '#2196f3',
                color: '#1976d2',
                fontSize: '0.75rem'
              }}
            />
          }
          sx={{ paddingBottom: 1 }}
        />

        {/* Card Content - Medicine Details */}
        <CardContent sx={{ flexGrow: 1, paddingTop: 0 }}>
          {/* Manufacturer */}
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
            <Typography variant="body2" color="textSecondary" sx={{ minWidth: '80px', fontWeight: 500 }}>
              Manufacturer:
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 600, color: '#424242' }}>
              {medicine.manufacturer}
            </Typography>
          </Box>

          {/* Price with enhanced styling */}
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
            <Typography variant="body2" color="textSecondary" sx={{ minWidth: '80px', fontWeight: 500 }}>
              Price:
            </Typography>
            <Typography 
              variant="h6" 
              sx={{ 
                fontWeight: 700, 
                color: '#2e7d32',
                fontSize: '1.1rem'
              }}
            >
              ${medicine.price}
            </Typography>
          </Box>

          {/* Stock with visual indicator */}
          <Box sx={{ mb: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
              <Typography variant="body2" color="textSecondary" sx={{ minWidth: '80px', fontWeight: 500 }}>
                Stock:
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography 
                  variant="body1" 
                  sx={{ 
                    fontWeight: 600,
                    color: medicine.stockQuantity <= medicine.minStockLevel ? '#d32f2f' : '#424242'
                  }}
                >
                  {medicine.stockQuantity} units
                </Typography>
                {medicine.stockQuantity <= medicine.minStockLevel && (
                  <TrendingDownIcon sx={{ color: '#d32f2f', fontSize: '1rem' }} />
                )}
              </Box>
            </Box>

            {/* Stock Progress Bar */}
            <Box sx={{ width: '100%', bgcolor: '#e0e0e0', borderRadius: 1, height: 6 }}>
              <motion.div
                style={{
                  width: `${Math.min((medicine.stockQuantity / (medicine.maxStockLevel || 100)) * 100, 100)}%`,
                  height: '100%',
                  borderRadius: '4px',
                  background: medicine.stockQuantity <= medicine.minStockLevel ? 
                    'linear-gradient(90deg, #f44336, #ff5722)' :
                    medicine.stockQuantity <= medicine.minStockLevel * 2 ?
                    'linear-gradient(90deg, #ff9800, #ffc107)' :
                    'linear-gradient(90deg, #4caf50, #8bc34a)'
                }}
                initial={{ width: 0 }}
                animate={{ width: `${Math.min((medicine.stockQuantity / (medicine.maxStockLevel || 100)) * 100, 100)}%` }}
                transition={{ duration: 1, delay: 0.5 + index * 0.1 }}
              />
            </Box>
            <Typography variant="caption" color="textSecondary" sx={{ fontSize: '0.7rem', mt: 0.5 }}>
              {medicine.stockQuantity} / {medicine.maxStockLevel || 100} (Min: {medicine.minStockLevel})
            </Typography>
          </Box>

          {/* Expiry Date */}
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
            <Typography variant="body2" color="textSecondary" sx={{ minWidth: '80px', fontWeight: 500 }}>
              Expiry:
            </Typography>
            <Typography 
              variant="body2" 
              sx={{ 
                fontWeight: 600,
                color: (medicine.isExpired || medicine.isExpiringSoon) ? '#d32f2f' : '#424242'
              }}
            >
              {new Date(medicine.expiryDate).toLocaleDateString()}
            </Typography>
          </Box>

          {/* Supplier */}
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Typography variant="body2" color="textSecondary" sx={{ minWidth: '80px', fontWeight: 500 }}>
              Supplier:
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 600, color: '#424242' }}>
              {medicine.supplier?.name || 'N/A'}
            </Typography>
          </Box>
        </CardContent>

        {/* Card Actions - Edit and Delete buttons */}
        <CardActions sx={{ padding: 2, paddingTop: 0, gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<EditIcon />}
            onClick={() => handleEdit(medicine)}
            sx={{
              flex: 1,
              borderColor: '#2196f3',
              color: '#1976d2',
              '&:hover': {
                backgroundColor: '#e3f2fd',
                borderColor: '#1976d2'
              }
            }}
          >
            Edit
          </Button>
          <Button
            variant="outlined"
            startIcon={<DeleteIcon />}
            onClick={() => {
              setSelectedMedicine(medicine);
              setDeleteDialogOpen(true);
            }}
            sx={{
              flex: 1,
              borderColor: '#f44336',
              color: '#d32f2f',
              '&:hover': {
                backgroundColor: '#ffebee',
                borderColor: '#d32f2f'
              }
            }}
          >
            Delete
          </Button>
        </CardActions>
      </Card>
    </motion.div>
  );

  // Render Add Medicine Card for better visibility
  const renderAddMedicineCard = () => (
    <motion.div
      initial={{ opacity: 0, y: 50, scale: 0.9 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ 
        duration: 0.6, 
        type: "spring",
        stiffness: 300,
        damping: 30
      }}
      whileHover={{ 
        y: -10,
        scale: 1.02,
        transition: { duration: 0.2 }
      }}
      data-aos="fade-up"
    >
      <Card 
        className={styles.addMedicineCard}
        elevation={2}
        sx={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)',
          border: '2px dashed #2196f3',
          borderRadius: '16px',
          cursor: 'pointer',
          minHeight: '300px',
          '&:hover': {
            background: 'linear-gradient(135deg, #bbdefb 0%, #90caf9 100%)',
            borderColor: '#1976d2',
            elevation: 4,
            boxShadow: '0 8px 16px rgba(33, 150, 243, 0.2)'
          },
          transition: 'all 0.3s ease-in-out'
        }}
        onClick={() => setIsAddDialogOpen(true)}
      >
        <motion.div
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '16px',
            padding: '24px'
          }}
        >
          <Avatar 
            sx={{ 
              bgcolor: '#2196f3', 
              width: 80,
              height: 80,
              boxShadow: '0 4px 12px rgba(33, 150, 243, 0.3)'
            }}
          >
            <AddIcon sx={{ fontSize: '3rem', color: 'white' }} />
          </Avatar>
          
          <Typography 
            variant="h5" 
            sx={{ 
              fontWeight: 600, 
              color: '#1976d2',
              textAlign: 'center'
            }}
          >
            Add New Medicine
          </Typography>
          
          <Typography 
            variant="body1" 
            color="textSecondary"
            sx={{ 
              textAlign: 'center',
              maxWidth: '200px',
              lineHeight: 1.5
            }}
          >
            Click here to add a new medicine to your inventory
          </Typography>

          <Button
            variant="contained"
            startIcon={<PharmacyIcon />}
            sx={{
              mt: 2,
              background: 'linear-gradient(135deg, #2196f3, #1976d2)',
              borderRadius: '20px',
              padding: '8px 24px',
              '&:hover': {
                background: 'linear-gradient(135deg, #1976d2, #1565c0)',
              }
            }}
          >
            Get Started
          </Button>
        </motion.div>
      </Card>
    </motion.div>
  );

  return (
    <div className={styles.medicinesContainer}>
      {/* Animated Header */}
      <motion.div 
        className={styles.header}
        initial={{ opacity: 0, y: -30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className={styles.headerLeft}>
          <motion.h1 
            className={styles.title}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
          >
            <PharmacyIcon className={styles.titleIcon} />
            Medicine Inventory
          </motion.h1>
          <motion.p 
            className={styles.subtitle}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
          >
            Manage your pharmaceutical inventory with ease
          </motion.p>
        </div>
        
        <motion.div 
          className={styles.headerActions}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
        >
          <motion.button 
            className={styles.addButton}
            onClick={() => setIsAddDialogOpen(true)}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <AddIcon />
            Add Medicine
          </motion.button>
        </motion.div>
      </motion.div>

      {/* Enhanced Search and Filter Section */}
      <motion.div 
        className={styles.searchFilterSection}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        <div className={styles.searchContainer}>
          <SearchIcon className={styles.searchIcon} />
          <input
            type="text"
            placeholder="Search medicines by name, category, or manufacturer..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className={styles.searchInput}
          />
          {searchTerm && (
            <motion.button 
              className={styles.clearSearch}
              onClick={() => setSearchTerm('')}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
            >
              <CloseIcon />
            </motion.button>
          )}
        </div>

        <div className={styles.filterChips}>
          {['All', 'Low Stock', 'Expiring Soon', 'Expired', 'Antibiotics', 'Painkillers', 'Vitamins'].map((filter) => (
            <motion.div
              key={filter}
              className={`${styles.filterChip} ${activeFilter === filter ? styles.active : ''}`}
              onClick={() => setActiveFilter(filter)}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {filter}
            </motion.div>
          ))}
        </div>

        <div className={styles.sortSection}>
          <SortIcon className={styles.sortIcon} />
          <select 
            value={sortBy} 
            onChange={(e) => setSortBy(e.target.value)}
            className={styles.sortSelect}
          >
            <option value="name">Sort by Name</option>
            <option value="price">Sort by Price</option>
            <option value="stock">Sort by Stock</option>
            <option value="expiry">Sort by Expiry Date</option>
          </select>
        </div>
      </motion.div>

      {/* Quick Stats */}
      <motion.div 
        className={styles.quickStats}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        <div className={styles.statCard}>
          <TrendingUpIcon className={styles.statIcon} />
          <div className={styles.statInfo}>
            <span className={styles.statNumber}>{filteredMedicines.length}</span>
            <span className={styles.statLabel}>Total Medicines</span>
          </div>
        </div>
        <div className={styles.statCard}>
          <WarningIcon className={styles.statIcon} />
          <div className={styles.statInfo}>
            <span className={styles.statNumber}>{filteredMedicines.filter(m => m.stockQuantity <= m.minStockLevel).length}</span>
            <span className={styles.statLabel}>Low Stock</span>
          </div>
        </div>
        <div className={styles.statCard}>
          <TrendingDownIcon className={styles.statIcon} />
          <div className={styles.statInfo}>
            <span className={styles.statNumber}>{filteredMedicines.filter(m => m.isExpiringSoon || m.isExpired).length}</span>
            <span className={styles.statLabel}>Expiring Soon</span>
          </div>
        </div>
      </motion.div>

      {/* Loading State */}
      {loading && (
        <motion.div 
          className={styles.loadingContainer}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        >
          <div className={styles.loadingSpinner}>
            <PharmacyIcon className={styles.spinningIcon} />
          </div>
          <p>Loading medicines...</p>
        </motion.div>
      )}

      {/* Error State */}
      {error && (
        <motion.div 
          className={styles.errorContainer}
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
        >
          <WarningIcon className={styles.errorIcon} />
          <h3>Error Loading Medicines</h3>
          <p>{error.message}</p>
          <button onClick={refetch} className={styles.retryButton}>
            <RefreshIcon />
            Retry
          </button>
        </motion.div>
      )}

      {/* Medicines Grid with enhanced layout */}
      {!loading && !error && (
        <motion.div 
          className={styles.medicinesGrid}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))',
            gap: '24px',
            padding: '20px 0',
            marginBottom: '100px' // Space for floating action button
          }}
        >
          <AnimatePresence mode="wait">
            {filteredMedicines.length === 0 ? (
              renderAddMedicineCard()
            ) : (
              [
                // Add Medicine Card as first item
                <div key="add-medicine-card" style={{ gridColumn: filteredMedicines.length === 0 ? 'span 1' : 'span 1' }}>
                  {renderAddMedicineCard()}
                </div>,
                // Medicine Cards
                ...filteredMedicines.map((medicine, index) => 
                  renderMedicineCard(medicine, index + 1)
                )
              ]
            )}
          </AnimatePresence>
        </motion.div>
      )}

      {/* Enhanced Delete Confirmation Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        className={styles.deleteDialog}
      >
        <DialogTitle className={styles.dialogTitle}>
          <DeleteIcon className={styles.dialogIcon} />
          Confirm Deletion
        </DialogTitle>
        <DialogContent className={styles.dialogContent}>
          <motion.div 
            className={styles.deleteConfirmation}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
          >
            <WarningIcon className={styles.warningIcon} />
            <p>Are you sure you want to delete <strong>{selectedMedicine?.name}</strong>?</p>
            <p className={styles.warningText}>This action cannot be undone.</p>
          </motion.div>
        </DialogContent>
        <DialogActions className={styles.dialogActions}>
          <motion.button 
            onClick={() => setDeleteDialogOpen(false)}
            className={styles.cancelButton}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            Cancel
          </motion.button>
          <motion.button 
            onClick={handleDelete}
            className={styles.confirmDeleteButton}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <DeleteIcon />
            Delete Medicine
          </motion.button>
        </DialogActions>
      </Dialog>

      {/* Add Medicine Dialog */}
      <Dialog 
        open={isAddDialogOpen} 
        onClose={() => setIsAddDialogOpen(false)}
        maxWidth="md"
        fullWidth
        className={styles.formDialog}
      >
        <DialogTitle className={styles.dialogTitle}>
          <AddIcon className={styles.dialogIcon} />
          Add New Medicine
        </DialogTitle>
        <DialogContent className={styles.dialogContent}>
          <MedicineForm
            medicine={null}
            onSubmit={handleAdd}
            onCancel={() => setIsAddDialogOpen(false)}
          />
        </DialogContent>
      </Dialog>

      {/* Edit Medicine Dialog */}
      <Dialog 
        open={isEditDialogOpen} 
        onClose={() => setIsEditDialogOpen(false)}
        maxWidth="md"
        fullWidth
        className={styles.formDialog}
      >
        <DialogTitle className={styles.dialogTitle}>
          <EditIcon className={styles.dialogIcon} />
          Edit Medicine
        </DialogTitle>
        <DialogContent className={styles.dialogContent}>
          <MedicineForm
            medicine={selectedMedicine}
            onSubmit={handleUpdate}
            onCancel={() => setIsEditDialogOpen(false)}
          />
        </DialogContent>
      </Dialog>

      {/* Success/Error Snackbar */}
      <Snackbar
        open={!!notification.message}
        autoHideDuration={4000}
        onClose={() => setNotification({ message: '', type: '' })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={() => setNotification({ message: '', type: '' })} 
          severity={notification.type}
          className={styles.alert}
        >
          {notification.message}
        </Alert>
      </Snackbar>

      {/* Floating Action Button for Add Medicine */}
      <Tooltip title="Add New Medicine" placement="left">
        <Fab
          color="primary"
          aria-label="add medicine"
          onClick={() => setIsAddDialogOpen(true)}
          sx={{
            position: 'fixed',
            bottom: 24,
            right: 24,
            zIndex: 1000,
            background: 'linear-gradient(135deg, #2196f3, #1976d2)',
            width: 64,
            height: 64,
            '&:hover': {
              background: 'linear-gradient(135deg, #1976d2, #1565c0)',
              transform: 'scale(1.1)',
              boxShadow: '0 8px 20px rgba(33, 150, 243, 0.4)'
            },
            '&:active': {
              transform: 'scale(0.95)'
            },
            transition: 'all 0.2s ease-in-out',
            boxShadow: '0 4px 12px rgba(33, 150, 243, 0.3)'
          }}
        >
          <AddIcon sx={{ fontSize: '2rem', color: 'white' }} />
        </Fab>
      </Tooltip>
    </div>
  );
};

export default Medicines;
