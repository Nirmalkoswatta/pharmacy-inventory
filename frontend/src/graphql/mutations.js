import { gql } from '@apollo/client';

// Medicine Mutations
export const CREATE_MEDICINE = gql`
  mutation CreateMedicine($input: MedicineInput!) {
    createMedicine(input: $input) {
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
      supplier {
        id
        name
      }
      isActive
      createdAt
    }
  }
`;

export const UPDATE_MEDICINE = gql`
  mutation UpdateMedicine($id: ID!, $input: MedicineUpdateInput!) {
    updateMedicine(id: $id, input: $input) {
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
      supplier {
        id
        name
      }
      isActive
      updatedAt
    }
  }
`;

export const DELETE_MEDICINE = gql`
  mutation DeleteMedicine($id: ID!) {
    deleteMedicine(id: $id)
  }
`;

export const UPDATE_STOCK = gql`
  mutation UpdateStock($id: ID!, $quantity: Int!) {
    updateStock(id: $id, quantity: $quantity) {
      id
      stockQuantity
      isLowStock
      updatedAt
    }
  }
`;

// Supplier Mutations
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
      paymentTerms
      rating
      isActive
      createdAt
    }
  }
`;

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

export const DELETE_SUPPLIER = gql`
  mutation DeleteSupplier($id: ID!) {
    deleteSupplier(id: $id)
  }
`;

// Order Mutations
export const CREATE_ORDER = gql`
  mutation CreateOrder($input: OrderInput!) {
    createOrder(input: $input) {
      id
      orderNumber
      supplier {
        id
        name
      }
      items {
        medicine {
          id
          name
        }
        quantity
        unitPrice
        totalPrice
      }
      orderDate
      expectedDeliveryDate
      status
      totalAmount
      tax
      discount
      finalAmount
      paymentMethod
      createdAt
    }
  }
`;

export const UPDATE_ORDER = gql`
  mutation UpdateOrder($id: ID!, $input: OrderUpdateInput!) {
    updateOrder(id: $id, input: $input) {
      id
      orderNumber
      expectedDeliveryDate
      actualDeliveryDate
      status
      notes
      paymentStatus
      paymentMethod
      updatedAt
    }
  }
`;

export const CANCEL_ORDER = gql`
  mutation CancelOrder($id: ID!) {
    cancelOrder(id: $id) {
      id
      orderNumber
      status
      updatedAt
    }
  }
`;

export const MARK_ORDER_DELIVERED = gql`
  mutation MarkOrderDelivered($id: ID!, $deliveryDate: Date!) {
    markOrderDelivered(id: $id, deliveryDate: $deliveryDate) {
      id
      orderNumber
      status
      actualDeliveryDate
      updatedAt
    }
  }
`;
