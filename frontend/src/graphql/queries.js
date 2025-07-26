import { gql } from '@apollo/client';

// Medicine Queries
export const GET_MEDICINES = gql`
  query GetMedicines($filter: MedicineFilter, $search: String, $limit: Int, $offset: Int) {
    medicines(filter: $filter, search: $search, limit: $limit, offset: $offset) {
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
      supplier {
        id
        name
      }
      createdAt
      updatedAt
    }
  }
`;

export const GET_MEDICINE = gql`
  query GetMedicine($id: ID!) {
    medicine(id: $id) {
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
      supplier {
        id
        name
        contactPerson
        email
        phone
      }
      createdAt
      updatedAt
    }
  }
`;

export const GET_MEDICINES_BY_SUPPLIER = gql`
  query GetMedicinesBySupplier($supplierId: ID!) {
    medicinesBySupplier(supplierId: $supplierId) {
      id
      name
      manufacturer
      category
      price
      stockQuantity
      isLowStock
    }
  }
`;

// Supplier Queries
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
      paymentTerms
      rating
      isActive
      createdAt
    }
  }
`;

export const GET_ACTIVE_SUPPLIERS = gql`
  query GetActiveSuppliers {
    activeSuppliers {
      id
      name
      contactPerson
      email
      phone
    }
  }
`;

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
      licenseNumber
      taxId
      paymentTerms
      rating
      isActive
      notes
      fullAddress
      createdAt
      updatedAt
    }
  }
`;

// Order Queries
export const GET_ORDERS = gql`
  query GetOrders($filter: OrderFilter, $limit: Int, $offset: Int) {
    orders(filter: $filter, limit: $limit, offset: $offset) {
      id
      orderNumber
      supplier {
        id
        name
      }
      orderDate
      expectedDeliveryDate
      actualDeliveryDate
      status
      totalAmount
      finalAmount
      paymentStatus
      paymentMethod
      orderAge
      isOverdue
      createdAt
    }
  }
`;

export const GET_ORDER = gql`
  query GetOrder($id: ID!) {
    order(id: $id) {
      id
      orderNumber
      supplier {
        id
        name
        contactPerson
        email
        phone
      }
      items {
        medicine {
          id
          name
          manufacturer
        }
        quantity
        unitPrice
        totalPrice
      }
      orderDate
      expectedDeliveryDate
      actualDeliveryDate
      status
      totalAmount
      tax
      discount
      finalAmount
      notes
      paymentStatus
      paymentMethod
      orderAge
      isOverdue
      createdAt
      updatedAt
    }
  }
`;

export const GET_ORDERS_BY_SUPPLIER = gql`
  query GetOrdersBySupplier($supplierId: ID!) {
    ordersBySupplier(supplierId: $supplierId) {
      id
      orderNumber
      orderDate
      status
      totalAmount
      paymentStatus
    }
  }
`;

// Dashboard Analytics
export const GET_DASHBOARD_STATS = gql`
  query GetDashboardStats {
    dashboardStats {
      totalMedicines
      lowStockMedicines
      expiredMedicines
      expiringSoonMedicines
      totalSuppliers
      activeSuppliers
      totalOrders
      pendingOrders
      totalRevenue
      monthlyRevenue
    }
  }
`;
