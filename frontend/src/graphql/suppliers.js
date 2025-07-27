import { gql } from '@apollo/client';

// Get all suppliers
export const GET_SUPPLIERS = gql`
  query GetSuppliers($search: String, $limit: Int, $offset: Int) {
    suppliers(search: $search, limit: $limit, offset: $offset) {
      id
      name
      contactPerson
      email
      phone
      address {
        street
        city
        state
        zipCode
        country
      }
      licenseNumber
      taxId
      paymentTerms
      rating
      isActive
      notes
      createdAt
      updatedAt
    }
  }
`;

// Get single supplier by ID
export const GET_SUPPLIER = gql`
  query GetSupplier($id: ID!) {
    supplier(id: $id) {
      id
      name
      contactPerson
      email
      phone
      address {
        street
        city
        state
        zipCode
        country
      }
      fullAddress
      licenseNumber
      taxId
      paymentTerms
      rating
      isActive
      notes
      createdAt
      updatedAt
    }
  }
`;

// Create new supplier
export const CREATE_SUPPLIER = gql`
  mutation CreateSupplier($input: SupplierInput!) {
    createSupplier(input: $input) {
      id
      name
      contactPerson
      email
      phone
      address {
        street
        city
        state
        zipCode
        country
      }
      licenseNumber
      taxId
      paymentTerms
      rating
      isActive
      notes
      createdAt
    }
  }
`;

// Update existing supplier
export const UPDATE_SUPPLIER = gql`
  mutation UpdateSupplier($id: ID!, $input: SupplierUpdateInput!) {
    updateSupplier(id: $id, input: $input) {
      id
      name
      contactPerson
      email
      phone
      address {
        street
        city
        state
        zipCode
        country
      }
      licenseNumber
      taxId
      paymentTerms
      rating
      isActive
      notes
      updatedAt
    }
  }
`;

// Delete supplier (soft delete - sets isActive to false)
export const DELETE_SUPPLIER = gql`
  mutation DeleteSupplier($id: ID!) {
    deleteSupplier(id: $id)
  }
`;

// Get medicines by supplier
export const GET_MEDICINES_BY_SUPPLIER = gql`
  query GetMedicinesBySupplier($supplierId: ID!) {
    medicinesBySupplier(supplierId: $supplierId) {
      id
      name
      description
      manufacturer
      category
      price
      stockQuantity
      minStockLevel
      maxStockLevel
      batchNumber
      expiryDate
      isActive
      isLowStock
      isExpired
      isExpiringSoon
      daysUntilExpiry
      createdAt
      updatedAt
    }
  }
`;
