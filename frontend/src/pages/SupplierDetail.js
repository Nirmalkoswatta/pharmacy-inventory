import React, { useState, useEffect } from 'react';
import { 
  Box, 
  Typography, 
  Paper, 
  Grid, 
  Card, 
  CardContent,
  Button,
  Chip,
  Rating,
  IconButton,
  Avatar,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Alert,
  CircularProgress,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField
} from '@mui/material';
import {
  ArrowBack as ArrowBackIcon,
  Edit as EditIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  LocationOn as LocationIcon,
  Business as BusinessIcon,
  Star as StarIcon,
  Inventory as InventoryIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon
} from '@mui/icons-material';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation } from '@apollo/client';
import toast from 'react-hot-toast';
import AOS from 'aos';
import { 
  GET_SUPPLIER, 
  GET_MEDICINES_BY_SUPPLIER, 
  UPDATE_SUPPLIER 
} from '../graphql/suppliers';

const SupplierDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);

  // GraphQL queries
  const { loading: loadingSupplier, error: errorSupplier, data: supplierData, refetch: refetchSupplier } = useQuery(GET_SUPPLIER, {
    variables: { id },
    skip: !id
  });

  const { loading: loadingMedicines, error: errorMedicines, data: medicinesData } = useQuery(GET_MEDICINES_BY_SUPPLIER, {
    variables: { supplierId: id },
    skip: !id
  });

  const [updateSupplier, { loading: updating }] = useMutation(UPDATE_SUPPLIER, {
    onCompleted: () => {
      toast.success('Supplier updated successfully!');
      setIsEditDialogOpen(false);
      refetchSupplier();
    },
    onError: (error) => {
      toast.error(`Error updating supplier: ${error.message}`);
    }
  });

  useEffect(() => {
    AOS.init({
      duration: 1000,
      once: true,
    });
  }, []);

  const supplier = supplierData?.supplier;
  const medicines = medicinesData?.medicinesBySupplier || [];

  // Calculate statistics
  const totalMedicines = medicines.length;
  const lowStockMedicines = medicines.filter(med => med.isLowStock).length;
  const expiredMedicines = medicines.filter(med => med.isExpired).length;
  const expiringSoonMedicines = medicines.filter(med => med.isExpiringSoon).length;
  const totalValue = medicines.reduce((sum, med) => sum + (med.price * med.stockQuantity), 0);

  if (loadingSupplier) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  if (errorSupplier) {
    return (
      <Box>
        <Alert severity="error">
          Error loading supplier: {errorSupplier.message}
        </Alert>
      </Box>
    );
  }

  if (!supplier) {
    return (
      <Box>
        <Alert severity="error">
          Supplier not found
        </Alert>
      </Box>
    );
  }
  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center">
          <IconButton onClick={() => navigate('/suppliers')} sx={{ mr: 2 }}>
            <ArrowBackIcon />
          </IconButton>
          <Typography variant="h4">
            {supplier.name}
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<EditIcon />}
          onClick={() => setIsEditDialogOpen(true)}
        >
          Edit Supplier
        </Button>
      </Box>

      <Grid container spacing={3}>
        {/* Supplier Information Card */}
        <Grid item xs={12} md={8}>
          <Card data-aos="fade-up">
            <CardContent>
              <Box display="flex" alignItems="center" mb={3}>
                <Avatar 
                  sx={{ 
                    width: 80, 
                    height: 80, 
                    bgcolor: 'primary.main',
                    fontSize: '2rem',
                    mr: 3
                  }}
                >
                  {supplier.name.charAt(0)}
                </Avatar>
                <Box>
                  <Typography variant="h5" gutterBottom>
                    {supplier.name}
                  </Typography>
                  <Box display="flex" alignItems="center" gap={2}>
                    <Chip 
                      label={supplier.isActive ? 'Active' : 'Inactive'}
                      color={supplier.isActive ? 'success' : 'default'}
                    />
                    <Rating value={supplier.rating} precision={0.5} readOnly />
                    <Typography variant="body2" color="text.secondary">
                      ({supplier.rating}/5)
                    </Typography>
                  </Box>
                </Box>
              </Box>

              <Divider sx={{ mb: 3 }} />

              {/* Contact Information */}
              <Typography variant="h6" gutterBottom>
                Contact Information
              </Typography>
              <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <BusinessIcon sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Contact Person
                      </Typography>
                      <Typography variant="body1">
                        {supplier.contactPerson}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <EmailIcon sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Email
                      </Typography>
                      <Typography variant="body1">
                        {supplier.email}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" mb={2}>
                    <PhoneIcon sx={{ mr: 2, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Phone
                      </Typography>
                      <Typography variant="body1">
                        {supplier.phone}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="flex-start" mb={2}>
                    <LocationIcon sx={{ mr: 2, color: 'text.secondary', mt: 0.5 }} />
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Address
                      </Typography>
                      <Typography variant="body1">
                        {supplier.fullAddress}
                      </Typography>
                    </Box>
                  </Box>
                </Grid>
              </Grid>

              <Divider sx={{ mb: 3 }} />

              {/* Business Information */}
              <Typography variant="h6" gutterBottom>
                Business Information
              </Typography>
              <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    License Number
                  </Typography>
                  <Typography variant="body1" gutterBottom>
                    {supplier.licenseNumber}
                  </Typography>
                </Grid>
                {supplier.taxId && (
                  <Grid item xs={12} sm={6}>
                    <Typography variant="body2" color="text.secondary">
                      Tax ID
                    </Typography>
                    <Typography variant="body1" gutterBottom>
                      {supplier.taxId}
                    </Typography>
                  </Grid>
                )}
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    Payment Terms
                  </Typography>
                  <Typography variant="body1" gutterBottom>
                    {supplier.paymentTerms?.replace('_', ' ')}
                  </Typography>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    Member Since
                  </Typography>
                  <Typography variant="body1" gutterBottom>
                    {new Date(supplier.createdAt).toLocaleDateString()}
                  </Typography>
                </Grid>
              </Grid>

              {supplier.notes && (
                <>
                  <Divider sx={{ mb: 3 }} />
                  <Typography variant="h6" gutterBottom>
                    Notes
                  </Typography>
                  <Typography variant="body1">
                    {supplier.notes}
                  </Typography>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Statistics Card */}
        <Grid item xs={12} md={4}>
          <Card data-aos="fade-up" data-aos-delay="100">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Inventory Summary
              </Typography>
              
              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Box display="flex" alignItems="center">
                  <InventoryIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="body1">Total Medicines</Typography>
                </Box>
                <Typography variant="h6" color="primary.main">
                  {totalMedicines}
                </Typography>
              </Box>

              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Box display="flex" alignItems="center">
                  <WarningIcon sx={{ mr: 1, color: 'warning.main' }} />
                  <Typography variant="body1">Low Stock</Typography>
                </Box>
                <Typography variant="h6" color="warning.main">
                  {lowStockMedicines}
                </Typography>
              </Box>

              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Box display="flex" alignItems="center">
                  <ErrorIcon sx={{ mr: 1, color: 'error.main' }} />
                  <Typography variant="body1">Expired</Typography>
                </Box>
                <Typography variant="h6" color="error.main">
                  {expiredMedicines}
                </Typography>
              </Box>

              <Box display="flex" alignItems="center" justifyContent="space-between" mb={3}>
                <Box display="flex" alignItems="center">
                  <WarningIcon sx={{ mr: 1, color: 'orange' }} />
                  <Typography variant="body1">Expiring Soon</Typography>
                </Box>
                <Typography variant="h6" sx={{ color: 'orange' }}>
                  {expiringSoonMedicines}
                </Typography>
              </Box>

              <Divider sx={{ mb: 2 }} />

              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Typography variant="body1" fontWeight="bold">
                  Total Inventory Value
                </Typography>
                <Typography variant="h6" color="success.main">
                  ₹{totalValue.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Medicines Table */}
        <Grid item xs={12}>
          <Card data-aos="fade-up" data-aos-delay="200">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Medicines Supplied ({totalMedicines})
              </Typography>
              
              {loadingMedicines ? (
                <Box display="flex" justifyContent="center" p={3}>
                  <CircularProgress />
                </Box>
              ) : errorMedicines ? (
                <Alert severity="error">
                  Error loading medicines: {errorMedicines.message}
                </Alert>
              ) : medicines.length === 0 ? (
                <Typography variant="body1" color="text.secondary" textAlign="center" p={3}>
                  No medicines found for this supplier.
                </Typography>
              ) : (
                <TableContainer>
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Medicine Name</TableCell>
                        <TableCell>Category</TableCell>
                        <TableCell>Stock</TableCell>
                        <TableCell>Price</TableCell>
                        <TableCell>Expiry Date</TableCell>
                        <TableCell>Status</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {medicines.map((medicine) => (
                        <TableRow key={medicine.id}>
                          <TableCell>
                            <Box>
                              <Typography variant="body1">
                                {medicine.name}
                              </Typography>
                              <Typography variant="body2" color="text.secondary">
                                {medicine.manufacturer}
                              </Typography>
                            </Box>
                          </TableCell>
                          <TableCell>
                            <Chip label={medicine.category} size="small" />
                          </TableCell>
                          <TableCell>
                            <Typography 
                              variant="body1" 
                              color={medicine.isLowStock ? 'error.main' : 'text.primary'}
                            >
                              {medicine.stockQuantity}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            ₹{medicine.price.toFixed(2)}
                          </TableCell>
                          <TableCell>
                            <Typography 
                              variant="body2"
                              color={
                                medicine.isExpired ? 'error.main' : 
                                medicine.isExpiringSoon ? 'warning.main' : 
                                'text.primary'
                              }
                            >
                              {new Date(medicine.expiryDate).toLocaleDateString()}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Box display="flex" gap={0.5}>
                              {medicine.isExpired && (
                                <Tooltip title="Expired">
                                  <ErrorIcon color="error" fontSize="small" />
                                </Tooltip>
                              )}
                              {medicine.isExpiringSoon && !medicine.isExpired && (
                                <Tooltip title="Expiring Soon">
                                  <WarningIcon color="warning" fontSize="small" />
                                </Tooltip>
                              )}
                              {medicine.isLowStock && (
                                <Tooltip title="Low Stock">
                                  <WarningIcon color="error" fontSize="small" />
                                </Tooltip>
                              )}
                              {!medicine.isExpired && !medicine.isExpiringSoon && !medicine.isLowStock && (
                                <Tooltip title="Good">
                                  <CheckCircleIcon color="success" fontSize="small" />
                                </Tooltip>
                              )}
                            </Box>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Edit Supplier Dialog */}
      <SupplierEditDialog
        open={isEditDialogOpen}
        onClose={() => setIsEditDialogOpen(false)}
        supplier={supplier}
        onUpdate={(supplierData) => {
          updateSupplier({ 
            variables: { 
              id: supplier.id, 
              input: supplierData 
            } 
          });
        }}
        loading={updating}
      />
    </Box>
  );
};

// Supplier Edit Dialog Component
const SupplierEditDialog = ({ open, onClose, supplier, onUpdate, loading }) => {
  const [formData, setFormData] = useState({
    name: '',
    contactPerson: '',
    email: '',
    phone: '',
    address: {
      street: '',
      city: '',
      state: '',
      zipCode: '',
      country: 'Sri Lanka'
    },
    licenseNumber: '',
    taxId: '',
    paymentTerms: 'Net_30',
    rating: 3,
    notes: '',
    isActive: true
  });

  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (supplier && open) {
      setFormData({
        name: supplier.name || '',
        contactPerson: supplier.contactPerson || '',
        email: supplier.email || '',
        phone: supplier.phone || '',
        address: {
          street: supplier.address?.street || '',
          city: supplier.address?.city || '',
          state: supplier.address?.state || '',
          zipCode: supplier.address?.zipCode || '',
          country: supplier.address?.country || 'Sri Lanka'
        },
        licenseNumber: supplier.licenseNumber || '',
        taxId: supplier.taxId || '',
        paymentTerms: supplier.paymentTerms || 'Net_30',
        rating: supplier.rating || 3,
        notes: supplier.notes || '',
        isActive: supplier.isActive !== undefined ? supplier.isActive : true
      });
    }
    setErrors({});
  }, [supplier, open]);

  const validateForm = () => {
    const newErrors = {};

    if (!formData.name.trim()) newErrors.name = 'Name is required';
    if (!formData.contactPerson.trim()) newErrors.contactPerson = 'Contact person is required';
    if (!formData.email.trim()) newErrors.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = 'Invalid email format';
    if (!formData.phone.trim()) newErrors.phone = 'Phone is required';
    if (!formData.address.street.trim()) newErrors.street = 'Street address is required';
    if (!formData.address.city.trim()) newErrors.city = 'City is required';
    if (!formData.address.state.trim()) newErrors.state = 'State is required';
    if (!formData.address.zipCode.trim()) newErrors.zipCode = 'ZIP code is required';
    if (!formData.licenseNumber.trim()) newErrors.licenseNumber = 'License number is required';

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (validateForm()) {
      onUpdate(formData);
    }
  };

  const handleInputChange = (field, value) => {
    if (field.includes('.')) {
      const [parent, child] = field.split('.');
      setFormData(prev => ({
        ...prev,
        [parent]: {
          ...prev[parent],
          [child]: value
        }
      }));
    } else {
      setFormData(prev => ({
        ...prev,
        [field]: value
      }));
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Edit Supplier</DialogTitle>
      <DialogContent>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          {/* Basic Information */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom>
              Basic Information
            </Typography>
          </Grid>
          
          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Company Name"
              value={formData.name}
              onChange={(e) => handleInputChange('name', e.target.value)}
              error={!!errors.name}
              helperText={errors.name}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Contact Person"
              value={formData.contactPerson}
              onChange={(e) => handleInputChange('contactPerson', e.target.value)}
              error={!!errors.contactPerson}
              helperText={errors.contactPerson}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={formData.email}
              onChange={(e) => handleInputChange('email', e.target.value)}
              error={!!errors.email}
              helperText={errors.email}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Phone"
              value={formData.phone}
              onChange={(e) => handleInputChange('phone', e.target.value)}
              error={!!errors.phone}
              helperText={errors.phone}
              required
            />
          </Grid>

          {/* Address Information */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>
              Address Information
            </Typography>
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Street Address"
              value={formData.address.street}
              onChange={(e) => handleInputChange('address.street', e.target.value)}
              error={!!errors.street}
              helperText={errors.street}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="City"
              value={formData.address.city}
              onChange={(e) => handleInputChange('address.city', e.target.value)}
              error={!!errors.city}
              helperText={errors.city}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="State"
              value={formData.address.state}
              onChange={(e) => handleInputChange('address.state', e.target.value)}
              error={!!errors.state}
              helperText={errors.state}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="ZIP Code"
              value={formData.address.zipCode}
              onChange={(e) => handleInputChange('address.zipCode', e.target.value)}
              error={!!errors.zipCode}
              helperText={errors.zipCode}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Country"
              value={formData.address.country}
              onChange={(e) => handleInputChange('address.country', e.target.value)}
              required
            />
          </Grid>

          {/* Business Information */}
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>
              Business Information
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="License Number"
              value={formData.licenseNumber}
              onChange={(e) => handleInputChange('licenseNumber', e.target.value)}
              error={!!errors.licenseNumber}
              helperText={errors.licenseNumber}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="Tax ID"
              value={formData.taxId}
              onChange={(e) => handleInputChange('taxId', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              select
              label="Payment Terms"
              value={formData.paymentTerms}
              onChange={(e) => handleInputChange('paymentTerms', e.target.value)}
              SelectProps={{
                native: true,
              }}
            >
              <option value="Cash">Cash</option>
              <option value="Net_30">Net 30</option>
              <option value="Net_60">Net 60</option>
              <option value="Net_90">Net 90</option>
            </TextField>
          </Grid>

          <Grid item xs={12} sm={6}>
            <Box>
              <Typography component="legend">Rating</Typography>
              <Rating
                value={formData.rating}
                onChange={(event, newValue) => {
                  handleInputChange('rating', newValue);
                }}
                precision={0.5}
              />
            </Box>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              select
              label="Status"
              value={formData.isActive}
              onChange={(e) => handleInputChange('isActive', e.target.value === 'true')}
              SelectProps={{
                native: true,
              }}
            >
              <option value={true}>Active</option>
              <option value={false}>Inactive</option>
            </TextField>
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Notes"
              multiline
              rows={3}
              value={formData.notes}
              onChange={(e) => handleInputChange('notes', e.target.value)}
              placeholder="Additional notes about the supplier..."
            />
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button 
          onClick={handleSubmit}
          variant="contained"
          disabled={loading}
          startIcon={loading ? <CircularProgress size={16} /> : null}
        >
          {loading ? 'Updating...' : 'Update Supplier'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default SupplierDetail;
