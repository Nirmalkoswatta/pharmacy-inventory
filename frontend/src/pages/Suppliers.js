import React, { useState, useEffect } from 'react';
import { 
  Box, 
  Typography, 
  Paper, 
  Button, 
  Grid, 
  Card, 
  CardContent,
  CardActions,
  IconButton,
  Chip,
  TextField,
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Rating,
  Alert,
  CircularProgress,
  Fab,
  Tooltip
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Business as BusinessIcon,
  LocationOn as LocationIcon
} from '@mui/icons-material';
import { useQuery, useMutation } from '@apollo/client';
import toast from 'react-hot-toast';
import AOS from 'aos';
import { GET_SUPPLIERS, CREATE_SUPPLIER, UPDATE_SUPPLIER, DELETE_SUPPLIER } from '../graphql/suppliers';

const Suppliers = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSupplier, setSelectedSupplier] = useState(null);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [supplierToDelete, setSupplierToDelete] = useState(null);

  // GraphQL queries and mutations
  const { loading, error, data, refetch } = useQuery(GET_SUPPLIERS, {
    variables: { search: searchTerm }
  });

  const [createSupplier, { loading: creating }] = useMutation(CREATE_SUPPLIER, {
    onCompleted: () => {
      toast.success('Supplier created successfully!');
      setIsAddDialogOpen(false);
      refetch();
    },
    onError: (error) => {
      toast.error(`Error creating supplier: ${error.message}`);
    }
  });

  const [updateSupplier, { loading: updating }] = useMutation(UPDATE_SUPPLIER, {
    onCompleted: () => {
      toast.success('Supplier updated successfully!');
      setIsEditDialogOpen(false);
      setSelectedSupplier(null);
      refetch();
    },
    onError: (error) => {
      toast.error(`Error updating supplier: ${error.message}`);
    }
  });

  const [deleteSupplier, { loading: deleting }] = useMutation(DELETE_SUPPLIER, {
    onCompleted: () => {
      toast.success('Supplier deleted successfully!');
      setIsDeleteDialogOpen(false);
      setSupplierToDelete(null);
      refetch();
    },
    onError: (error) => {
      toast.error(`Error deleting supplier: ${error.message}`);
    }
  });

  useEffect(() => {
    AOS.init({
      duration: 1000,
      once: true,
    });
  }, []);

  const handleSearch = (event) => {
    setSearchTerm(event.target.value);
  };

  const handleEditSupplier = (supplier) => {
    setSelectedSupplier(supplier);
    setIsEditDialogOpen(true);
  };

  const handleDeleteSupplier = (supplier) => {
    setSupplierToDelete(supplier);
    setIsDeleteDialogOpen(true);
  };

  const confirmDelete = () => {
    if (supplierToDelete) {
      deleteSupplier({
        variables: { id: supplierToDelete.id }
      });
    }
  };

  const suppliers = data?.suppliers || [];
  const filteredSuppliers = suppliers.filter(supplier =>
    supplier.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    supplier.contactPerson.toLowerCase().includes(searchTerm.toLowerCase()) ||
    supplier.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box>
        <Alert severity="error">
          Error loading suppliers: {error.message}
        </Alert>
      </Box>
    );
  }
  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          Suppliers Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setIsAddDialogOpen(true)}
          sx={{ borderRadius: 2 }}
        >
          Add Supplier
        </Button>
      </Box>

      {/* Search Bar */}
      <Paper sx={{ p: 2, mb: 3 }} data-aos="fade-up">
        <TextField
          fullWidth
          placeholder="Search suppliers by name, contact person, or email..."
          value={searchTerm}
          onChange={handleSearch}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ borderRadius: 2 }}
        />
      </Paper>

      {/* Suppliers Grid */}
      <Grid container spacing={3}>
        {filteredSuppliers.map((supplier, index) => (
          <Grid item xs={12} md={6} lg={4} key={supplier.id}>
            <Card 
              sx={{ 
                height: '100%', 
                display: 'flex', 
                flexDirection: 'column',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4
                }
              }}
              data-aos="fade-up"
              data-aos-delay={index * 100}
            >
              <CardContent sx={{ flexGrow: 1 }}>
                {/* Supplier Header */}
                <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                  <Box>
                    <Typography variant="h6" gutterBottom>
                      {supplier.name}
                    </Typography>
                    <Chip 
                      label={supplier.isActive ? 'Active' : 'Inactive'}
                      color={supplier.isActive ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                  <Rating value={supplier.rating} precision={0.5} size="small" readOnly />
                </Box>

                {/* Contact Information */}
                <Box display="flex" alignItems="center" mb={1}>
                  <BusinessIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 16 }} />
                  <Typography variant="body2" color="text.secondary">
                    {supplier.contactPerson}
                  </Typography>
                </Box>

                <Box display="flex" alignItems="center" mb={1}>
                  <EmailIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 16 }} />
                  <Typography variant="body2" color="text.secondary">
                    {supplier.email}
                  </Typography>
                </Box>

                <Box display="flex" alignItems="center" mb={1}>
                  <PhoneIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 16 }} />
                  <Typography variant="body2" color="text.secondary">
                    {supplier.phone}
                  </Typography>
                </Box>

                {supplier.address && (
                  <Box display="flex" alignItems="flex-start" mb={2}>
                    <LocationIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 16, mt: 0.5 }} />
                    <Typography variant="body2" color="text.secondary">
                      {supplier.address.city}, {supplier.address.state}
                    </Typography>
                  </Box>
                )}

                {/* License Information */}
                <Box>
                  <Typography variant="caption" color="text.secondary">
                    License: {supplier.licenseNumber}
                  </Typography>
                </Box>

                {/* Payment Terms */}
                <Box mt={1}>
                  <Chip 
                    label={supplier.paymentTerms?.replace('_', ' ')}
                    variant="outlined"
                    size="small"
                  />
                </Box>
              </CardContent>

              <CardActions sx={{ justifyContent: 'space-between', p: 2 }}>
                <Box>
                  <Tooltip title="Edit Supplier">
                    <IconButton 
                      color="primary" 
                      onClick={() => handleEditSupplier(supplier)}
                    >
                      <EditIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete Supplier">
                    <IconButton 
                      color="error" 
                      onClick={() => handleDeleteSupplier(supplier)}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Tooltip>
                </Box>
                <Typography variant="caption" color="text.secondary">
                  Added: {new Date(supplier.createdAt).toLocaleDateString()}
                </Typography>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* No Results */}
      {filteredSuppliers.length === 0 && !loading && (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="text.secondary">
            No suppliers found
          </Typography>
          <Typography variant="body2" color="text.secondary" mt={1}>
            Try adjusting your search terms or add a new supplier.
          </Typography>
        </Paper>
      )}

      {/* Floating Action Button for Mobile */}
      <Fab
        color="primary"
        aria-label="add supplier"
        sx={{
          position: 'fixed',
          bottom: 16,
          right: 16,
          display: { xs: 'flex', md: 'none' }
        }}
        onClick={() => setIsAddDialogOpen(true)}
      >
        <AddIcon />
      </Fab>

      {/* Add Supplier Dialog */}
      <SupplierDialog
        open={isAddDialogOpen}
        onClose={() => setIsAddDialogOpen(false)}
        onSubmit={(supplierData) => {
          createSupplier({ variables: { input: supplierData } });
        }}
        loading={creating}
        title="Add New Supplier"
      />

      {/* Edit Supplier Dialog */}
      <SupplierDialog
        open={isEditDialogOpen}
        onClose={() => {
          setIsEditDialogOpen(false);
          setSelectedSupplier(null);
        }}
        onSubmit={(supplierData) => {
          updateSupplier({ 
            variables: { 
              id: selectedSupplier.id, 
              input: supplierData 
            } 
          });
        }}
        loading={updating}
        title="Edit Supplier"
        initialData={selectedSupplier}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={isDeleteDialogOpen}
        onClose={() => setIsDeleteDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete the supplier "{supplierToDelete?.name}"? 
            This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIsDeleteDialogOpen(false)}>
            Cancel
          </Button>
          <Button 
            onClick={confirmDelete}
            color="error"
            disabled={deleting}
            startIcon={deleting ? <CircularProgress size={16} /> : null}
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

// Supplier Dialog Component for Add/Edit
const SupplierDialog = ({ open, onClose, onSubmit, loading, title, initialData }) => {
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
    notes: ''
  });

  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (initialData) {
      setFormData({
        name: initialData.name || '',
        contactPerson: initialData.contactPerson || '',
        email: initialData.email || '',
        phone: initialData.phone || '',
        address: {
          street: initialData.address?.street || '',
          city: initialData.address?.city || '',
          state: initialData.address?.state || '',
          zipCode: initialData.address?.zipCode || '',
          country: initialData.address?.country || 'Sri Lanka'
        },
        licenseNumber: initialData.licenseNumber || '',
        taxId: initialData.taxId || '',
        paymentTerms: initialData.paymentTerms || 'Net_30',
        rating: initialData.rating || 3,
        notes: initialData.notes || ''
      });
    } else {
      setFormData({
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
        notes: ''
      });
    }
    setErrors({});
  }, [initialData, open]);

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
      onSubmit(formData);
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
      <DialogTitle>{title}</DialogTitle>
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
          {loading ? 'Saving...' : (initialData ? 'Update' : 'Create')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default Suppliers;
