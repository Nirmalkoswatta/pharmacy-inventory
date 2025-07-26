const { gql } = require('apollo-server-express');

const typeDefs = gql`
  scalar Date

  type Medicine {
    id: ID!
    name: String!
    description: String
    manufacturer: String!
    category: Category!
    price: Float!
    stockQuantity: Int!
    minStockLevel: Int!
    maxStockLevel: Int!
    batchNumber: String!
    expiryDate: Date!
    supplier: Supplier!
    isActive: Boolean!
    isLowStock: Boolean!
    isExpired: Boolean!
    isExpiringSoon: Boolean!
    createdAt: Date!
    updatedAt: Date!
  }

  type Supplier {
    id: ID!
    name: String!
    contactPerson: String!
    email: String!
    phone: String!
    address: Address!
    licenseNumber: String!
    taxId: String
    paymentTerms: PaymentTerms!
    rating: Float!
    isActive: Boolean!
    notes: String
    fullAddress: String!
    createdAt: Date!
    updatedAt: Date!
  }

  type Order {
    id: ID!
    orderNumber: String!
    supplier: Supplier!
    items: [OrderItem!]!
    orderDate: Date!
    expectedDeliveryDate: Date!
    actualDeliveryDate: Date
    status: OrderStatus!
    totalAmount: Float!
    tax: Float!
    discount: Float!
    finalAmount: Float!
    notes: String
    paymentStatus: PaymentStatus!
    paymentMethod: PaymentMethod!
    orderAge: Int!
    isOverdue: Boolean!
    createdAt: Date!
    updatedAt: Date!
  }

  type OrderItem {
    medicine: Medicine!
    quantity: Int!
    unitPrice: Float!
    totalPrice: Float!
  }

  type Address {
    street: String!
    city: String!
    state: String!
    zipCode: String!
    country: String!
  }

  enum Category {
    Tablet
    Capsule
    Syrup
    Injection
    Cream
    Ointment
    Other
  }

  enum PaymentTerms {
    Cash
    Net_30
    Net_60
    Net_90
  }

  enum OrderStatus {
    Pending
    Confirmed
    Shipped
    Delivered
    Cancelled
  }

  enum PaymentStatus {
    Pending
    Partial
    Paid
  }

  enum PaymentMethod {
    Cash
    Credit_Card
    Bank_Transfer
    Check
  }

  # Input Types
  input MedicineInput {
    name: String!
    description: String
    manufacturer: String!
    category: Category!
    price: Float!
    stockQuantity: Int!
    minStockLevel: Int!
    maxStockLevel: Int!
    batchNumber: String!
    expiryDate: Date!
    supplierId: ID!
  }

  input MedicineUpdateInput {
    name: String
    description: String
    manufacturer: String
    category: Category
    price: Float
    stockQuantity: Int
    minStockLevel: Int
    maxStockLevel: Int
    batchNumber: String
    expiryDate: Date
    supplierId: ID
    isActive: Boolean
  }

  input SupplierInput {
    name: String!
    contactPerson: String!
    email: String!
    phone: String!
    address: AddressInput!
    licenseNumber: String!
    taxId: String
    paymentTerms: PaymentTerms!
    rating: Float
    notes: String
  }

  input SupplierUpdateInput {
    name: String
    contactPerson: String
    email: String
    phone: String
    address: AddressInput
    licenseNumber: String
    taxId: String
    paymentTerms: PaymentTerms
    rating: Float
    isActive: Boolean
    notes: String
  }

  input AddressInput {
    street: String!
    city: String!
    state: String!
    zipCode: String!
    country: String!
  }

  input OrderInput {
    supplierId: ID!
    items: [OrderItemInput!]!
    expectedDeliveryDate: Date!
    tax: Float
    discount: Float
    notes: String
    paymentMethod: PaymentMethod!
  }

  input OrderItemInput {
    medicineId: ID!
    quantity: Int!
    unitPrice: Float!
  }

  input OrderUpdateInput {
    expectedDeliveryDate: Date
    actualDeliveryDate: Date
    status: OrderStatus
    notes: String
    paymentStatus: PaymentStatus
    paymentMethod: PaymentMethod
  }

  # Filter Types
  input MedicineFilter {
    category: Category
    manufacturer: String
    isLowStock: Boolean
    isExpired: Boolean
    isExpiringSoon: Boolean
    supplierId: ID
  }

  input OrderFilter {
    status: OrderStatus
    paymentStatus: PaymentStatus
    supplierId: ID
    startDate: Date
    endDate: Date
  }

  # Dashboard Analytics
  type DashboardStats {
    totalMedicines: Int!
    lowStockMedicines: Int!
    expiredMedicines: Int!
    expiringSoonMedicines: Int!
    totalSuppliers: Int!
    activeSuppliers: Int!
    totalOrders: Int!
    pendingOrders: Int!
    totalRevenue: Float!
    monthlyRevenue: Float!
  }

  type Query {
    # Medicine Queries
    medicines(filter: MedicineFilter, search: String, limit: Int, offset: Int): [Medicine!]!
    medicine(id: ID!): Medicine
    medicinesBySupplier(supplierId: ID!): [Medicine!]!
    
    # Supplier Queries
    suppliers(search: String, limit: Int, offset: Int): [Supplier!]!
    supplier(id: ID!): Supplier
    activeSuppliers: [Supplier!]!
    
    # Order Queries
    orders(filter: OrderFilter, limit: Int, offset: Int): [Order!]!
    order(id: ID!): Order
    ordersBySupplier(supplierId: ID!): [Order!]!
    
    # Analytics
    dashboardStats: DashboardStats!
  }

  type Mutation {
    # Medicine Mutations
    createMedicine(input: MedicineInput!): Medicine!
    updateMedicine(id: ID!, input: MedicineUpdateInput!): Medicine!
    deleteMedicine(id: ID!): Boolean!
    updateStock(id: ID!, quantity: Int!): Medicine!
    
    # Supplier Mutations
    createSupplier(input: SupplierInput!): Supplier!
    updateSupplier(id: ID!, input: SupplierUpdateInput!): Supplier!
    deleteSupplier(id: ID!): Boolean!
    
    # Order Mutations
    createOrder(input: OrderInput!): Order!
    updateOrder(id: ID!, input: OrderUpdateInput!): Order!
    cancelOrder(id: ID!): Order!
    markOrderDelivered(id: ID!, deliveryDate: Date!): Order!
  }
`;

module.exports = typeDefs;
