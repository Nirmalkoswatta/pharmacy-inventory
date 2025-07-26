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
  Tooltip
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
import { DELETE_MEDICINE } from '../graphql/mutations';
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

  const handleAdd = (medicineData) => {
    // TODO: Implement add functionality
    setNotification({ message: 'Add functionality coming soon!', type: 'info' });
    setIsAddDialogOpen(false);
  };

  const handleUpdate = (medicineData) => {
    // TODO: Implement update functionality
    setNotification({ message: 'Edit functionality coming soon!', type: 'info' });
    setIsEditDialogOpen(false);
  };

  // Render medicine card component
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
      className={styles.medicineCard}
      data-aos="fade-up"
      data-aos-delay={index * 100}
    >
      {/* Favorite Star */}
      <motion.div 
        className={styles.favoriteButton}
        whileHover={{ scale: 1.2 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => toggleFavorite(medicine.id)}
      >
        {favorites.has(medicine.id) ? (
          <StarIcon className={styles.favoriteActive} />
        ) : (
          <StarBorderIcon className={styles.favoriteInactive} />
        )}
      </motion.div>

      {/* Status Badge */}
      <div className={`${styles.statusBadge} ${styles[getStatusInfo(medicine).status]}`}>
        {getStatusInfo(medicine).icon}
        <span>{getStatusInfo(medicine).label}</span>
      </div>

      {/* Medicine Icon */}
      <div className={styles.medicineIcon}>
        <PharmacyIcon className={styles.icon} />
      </div>

      {/* Medicine Name */}
      <motion.div 
        className={styles.medicineName}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 + index * 0.1 }}
      >
        {medicine.name}
      </motion.div>
      
      {/* Medicine Details */}
      <div className={styles.medicineDetails}>
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.4 + index * 0.1 }}
        >
          <span className={styles.label}>Category:</span>
          <Chip 
            label={medicine.category} 
            size="small" 
            variant="outlined"
            className={styles.categoryChip}
          />
        </motion.div>
        
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.5 + index * 0.1 }}
        >
          <span className={styles.label}>Manufacturer:</span>
          <span className={styles.value}>{medicine.manufacturer}</span>
        </motion.div>
        
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.6 + index * 0.1 }}
        >
          <span className={styles.label}>Price:</span>
          <span className={styles.priceValue}>₹{medicine.price}</span>
        </motion.div>
        
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.7 + index * 0.1 }}
        >
          <span className={styles.label}>Stock:</span>
          <div className={`${styles.stockIndicator} ${styles[getStockStatus(medicine)]}`}>
            <span className={styles.stockNumber}>{medicine.stockQuantity}</span>
            <span className={styles.stockUnit}>units</span>
            {medicine.stockQuantity <= medicine.minStockLevel && (
              <TrendingDownIcon className={styles.trendIcon} />
            )}
          </div>
        </motion.div>
        
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.8 + index * 0.1 }}
        >
          <span className={styles.label}>Expiry:</span>
          <span className={`${styles.expiryDate} ${medicine.isExpired || medicine.isExpiringSoon ? styles.urgent : ''}`}>
            {new Date(medicine.expiryDate).toLocaleDateString()}
          </span>
        </motion.div>
        
        <motion.div 
          className={styles.detailItem}
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.9 + index * 0.1 }}
        >
          <span className={styles.label}>Supplier:</span>
          <span className={styles.supplierName}>{medicine.supplier?.name || 'N/A'}</span>
        </motion.div>
      </div>

      {/* Progress Bar for Stock Level */}
      <div className={styles.stockProgress}>
        <div className={styles.progressLabel}>Stock Level</div>
        <div className={styles.progressBar}>
          <motion.div 
            className={`${styles.progressFill} ${styles[getStockStatus(medicine)]}`}
            initial={{ width: 0 }}
            animate={{ width: `${(medicine.stockQuantity / (medicine.maxStockLevel || 100)) * 100}%` }}
            transition={{ duration: 1, delay: 1 + index * 0.1 }}
          />
        </div>
        <div className={styles.progressText}>
          {medicine.stockQuantity} / {medicine.maxStockLevel || 100}
        </div>
      </div>

      {/* Action Buttons */}
      <motion.div 
        className={styles.medicineActions}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.1 + index * 0.1 }}
      >
        <motion.button 
          className={`${styles.actionBtn} ${styles.editBtn}`}
          onClick={() => handleEdit(medicine)}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <EditIcon fontSize="small" />
          <span>Edit</span>
        </motion.button>
        <motion.button 
          className={`${styles.actionBtn} ${styles.deleteBtn}`}
          onClick={() => {
            setSelectedMedicine(medicine);
            setDeleteDialogOpen(true);
          }}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <DeleteIcon fontSize="small" />
          <span>Delete</span>
        </motion.button>
      </motion.div>
    </motion.div>
  );

  // Render Empty State
  const renderEmptyState = () => (
    <motion.div 
      className={styles.emptyState}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
    >
      <PharmacyIcon className={styles.emptyIcon} />
      <h3>No Medicines Found</h3>
      <p>Start by adding your first medicine to the inventory</p>
      <motion.button 
        className={styles.addFirstBtn}
        onClick={() => setIsAddDialogOpen(true)}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
      >
        <AddIcon />
        Add First Medicine
      </motion.button>
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

      {/* Medicines Grid */}
      {!loading && !error && (
        <motion.div 
          className={styles.medicinesGrid}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
        >
          <AnimatePresence mode="wait">
            {filteredMedicines.length === 0 ? (
              renderEmptyState()
            ) : (
              filteredMedicines.map((medicine, index) => 
                renderMedicineCard(medicine, index)
              )
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
    </div>
  );
};

export default Medicines;
