import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Button,
  Grid,
  Box,
  Typography,
  InputAdornment
} from '@mui/material';
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  LocalPharmacy as PharmacyIcon,
  AttachMoney as MoneyIcon,
  Inventory as InventoryIcon
} from '@mui/icons-material';
import { useQuery } from '@apollo/client';
import { GET_SUPPLIERS } from '../graphql/queries';
import styles from '../styles/medicineForm.module.scss';

const MedicineForm = ({ medicine, onSubmit, onCancel }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    manufacturer: '',
    category: 'Tablet',
    price: '',
    stockQuantity: '',
    minStockLevel: '',
    maxStockLevel: '',
    batchNumber: '',
    expiryDate: '',
    supplierId: ''
  });

  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { data: suppliersData } = useQuery(GET_SUPPLIERS);

  // Populate form when editing
  useEffect(() => {
    if (medicine) {
      setFormData({
        name: medicine.name || '',
        description: medicine.description || '',
        manufacturer: medicine.manufacturer || '',
        category: medicine.category || 'Tablet',
        price: medicine.price?.toString() || '',
        stockQuantity: medicine.stockQuantity?.toString() || '',
        minStockLevel: medicine.minStockLevel?.toString() || '',
        maxStockLevel: medicine.maxStockLevel?.toString() || '',
        batchNumber: medicine.batchNumber || '',
        expiryDate: medicine.expiryDate ? new Date(medicine.expiryDate).toISOString().split('T')[0] : '',
        supplierId: medicine.supplier?.id || ''
      });
    }
  }, [medicine]);

  const categories = [
    'Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Ointment', 
    'Drops', 'Spray', 'Powder', 'Gel', 'Lotion', 'Inhaler', 'Other'
  ];

  const validateForm = () => {
    const newErrors = {};

    if (!formData.name.trim()) newErrors.name = 'Medicine name is required';
    if (!formData.manufacturer.trim()) newErrors.manufacturer = 'Manufacturer is required';
    if (!formData.category) newErrors.category = 'Category is required';
    if (!formData.price || parseFloat(formData.price) <= 0) newErrors.price = 'Valid price is required';
    if (!formData.stockQuantity || parseInt(formData.stockQuantity) < 0) newErrors.stockQuantity = 'Valid stock quantity is required';
    if (!formData.minStockLevel || parseInt(formData.minStockLevel) < 0) newErrors.minStockLevel = 'Valid minimum stock level is required';
    if (!formData.maxStockLevel || parseInt(formData.maxStockLevel) <= 0) newErrors.maxStockLevel = 'Valid maximum stock level is required';
    if (!formData.batchNumber.trim()) newErrors.batchNumber = 'Batch number is required';
    if (!formData.expiryDate) newErrors.expiryDate = 'Expiry date is required';
    if (!formData.supplierId) newErrors.supplierId = 'Supplier selection is required';

    // Additional validations
    if (formData.minStockLevel && formData.maxStockLevel && 
        parseInt(formData.minStockLevel) >= parseInt(formData.maxStockLevel)) {
      newErrors.minStockLevel = 'Minimum stock must be less than maximum stock';
    }

    if (formData.expiryDate && new Date(formData.expiryDate) <= new Date()) {
      newErrors.expiryDate = 'Expiry date must be in the future';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (field) => (event) => {
    const value = event.target.value;
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));

    // Clear error for this field when user starts typing
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: ''
      }));
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    
    try {
      const submissionData = {
        ...formData,
        price: parseFloat(formData.price),
        stockQuantity: parseInt(formData.stockQuantity),
        minStockLevel: parseInt(formData.minStockLevel),
        maxStockLevel: parseInt(formData.maxStockLevel),
        expiryDate: new Date(formData.expiryDate).toISOString()
      };

      await onSubmit(submissionData);
    } catch (error) {
      console.error('Error submitting form:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
      className={styles.medicineForm}
    >
      <Box component="form" onSubmit={handleSubmit} noValidate>
        <Typography variant="h6" className={styles.sectionTitle} gutterBottom>
          <PharmacyIcon className={styles.sectionIcon} />
          {medicine ? 'Edit Medicine' : 'Add New Medicine'}
        </Typography>

        <Grid container spacing={3}>
          {/* Basic Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" className={styles.sectionSubtitle}>
              Basic Information
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Medicine Name *"
              value={formData.name}
              onChange={handleChange('name')}
              error={!!errors.name}
              helperText={errors.name}
              variant="outlined"
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Manufacturer *"
              value={formData.manufacturer}
              onChange={handleChange('manufacturer')}
              error={!!errors.manufacturer}
              helperText={errors.manufacturer}
              variant="outlined"
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={handleChange('description')}
              variant="outlined"
              multiline
              rows={3}
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <FormControl fullWidth error={!!errors.category}>
              <InputLabel>Category *</InputLabel>
              <Select
                value={formData.category}
                onChange={handleChange('category')}
                label="Category *"
                className={styles.formField}
              >
                {categories.map((category) => (
                  <MenuItem key={category} value={category}>
                    {category}
                  </MenuItem>
                ))}
              </Select>
              {errors.category && (
                <Typography variant="caption" color="error" className={styles.errorText}>
                  {errors.category}
                </Typography>
              )}
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Batch Number *"
              value={formData.batchNumber}
              onChange={handleChange('batchNumber')}
              error={!!errors.batchNumber}
              helperText={errors.batchNumber}
              variant="outlined"
              className={styles.formField}
            />
          </Grid>

          {/* Pricing & Stock Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" className={styles.sectionSubtitle}>
              <MoneyIcon className={styles.sectionIcon} />
              Pricing & Stock Information
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Price *"
              type="number"
              value={formData.price}
              onChange={handleChange('price')}
              error={!!errors.price}
              helperText={errors.price}
              variant="outlined"
              inputProps={{ min: 0, step: 0.01 }}
              InputProps={{
                startAdornment: <InputAdornment position="start">$</InputAdornment>
              }}
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Current Stock Quantity *"
              type="number"
              value={formData.stockQuantity}
              onChange={handleChange('stockQuantity')}
              error={!!errors.stockQuantity}
              helperText={errors.stockQuantity}
              variant="outlined"
              inputProps={{ min: 0 }}
              InputProps={{
                startAdornment: <InputAdornment position="start"><InventoryIcon /></InputAdornment>
              }}
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Minimum Stock Level *"
              type="number"
              value={formData.minStockLevel}
              onChange={handleChange('minStockLevel')}
              error={!!errors.minStockLevel}
              helperText={errors.minStockLevel}
              variant="outlined"
              inputProps={{ min: 0 }}
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Maximum Stock Level *"
              type="number"
              value={formData.maxStockLevel}
              onChange={handleChange('maxStockLevel')}
              error={!!errors.maxStockLevel}
              helperText={errors.maxStockLevel}
              variant="outlined"
              inputProps={{ min: 1 }}
              className={styles.formField}
            />
          </Grid>

          {/* Expiry & Supplier Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" className={styles.sectionSubtitle}>
              Expiry & Supplier Information
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Expiry Date *"
              type="date"
              value={formData.expiryDate}
              onChange={handleChange('expiryDate')}
              error={!!errors.expiryDate}
              helperText={errors.expiryDate}
              variant="outlined"
              InputLabelProps={{ shrink: true }}
              className={styles.formField}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <FormControl fullWidth error={!!errors.supplierId}>
              <InputLabel>Supplier *</InputLabel>
              <Select
                value={formData.supplierId}
                onChange={handleChange('supplierId')}
                label="Supplier *"
                className={styles.formField}
              >
                <MenuItem value="">Select a supplier</MenuItem>
                {suppliersData?.suppliers?.map((supplier) => (
                  <MenuItem key={supplier.id} value={supplier.id}>
                    {supplier.name}
                  </MenuItem>
                ))}
              </Select>
              {errors.supplierId && (
                <Typography variant="caption" color="error" className={styles.errorText}>
                  {errors.supplierId}
                </Typography>
              )}
            </FormControl>
          </Grid>

          {/* Action Buttons */}
          <Grid item xs={12}>
            <Box className={styles.actionButtons}>
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Button
                  type="button"
                  variant="outlined"
                  onClick={onCancel}
                  startIcon={<CancelIcon />}
                  className={styles.cancelButton}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
              </motion.div>
              
              <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                <Button
                  type="submit"
                  variant="contained"
                  startIcon={<SaveIcon />}
                  className={styles.saveButton}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? 'Saving...' : (medicine ? 'Update Medicine' : 'Add Medicine')}
                </Button>
              </motion.div>
            </Box>
          </Grid>
        </Grid>
      </Box>
    </motion.div>
  );
};

export default MedicineForm;
