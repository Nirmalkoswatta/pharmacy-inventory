// MongoDB initialization script for Pharmacy Database

// Switch to pharmacy database
db = db.getSiblingDB('pharmacy');

// Create collections with indexes
db.createCollection('suppliers');
db.createCollection('medicines');
db.createCollection('orders');

// Create indexes for better performance
db.suppliers.createIndex({ "name": 1 });
db.suppliers.createIndex({ "email": 1 }, { unique: true });
db.suppliers.createIndex({ "licenseNumber": 1 }, { unique: true });

db.medicines.createIndex({ "name": 1, "manufacturer": 1 });
db.medicines.createIndex({ "category": 1 });
db.medicines.createIndex({ "supplierId": 1 });
db.medicines.createIndex({ "expiryDate": 1 });

db.orders.createIndex({ "orderNumber": 1 }, { unique: true });
db.orders.createIndex({ "supplierId": 1 });
db.orders.createIndex({ "orderDate": -1 });
db.orders.createIndex({ "status": 1 });

// Insert sample data
print('Inserting sample suppliers...');
const sampleSuppliers = [
  {
    name: "MediCorp Pharmaceuticals",
    contactPerson: "John Smith",
    email: "john@medicorp.com",
    phone: "+91-9876543210",
    address: {
      street: "123 Medical Street",
      city: "Mumbai",
      state: "Maharashtra",
      zipCode: "400001",
      country: "India"
    },
    licenseNumber: "MH-PHARM-001",
    taxId: "GST123456789",
    paymentTerms: "Net_30",
    rating: 4.5,
    isActive: true,
    notes: "Reliable supplier for general medicines",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "HealthPlus Distributors",
    contactPerson: "Sarah Johnson",
    email: "sarah@healthplus.com",
    phone: "+91-9876543211",
    address: {
      street: "456 Wellness Avenue",
      city: "Delhi",
      state: "Delhi",
      zipCode: "110001",
      country: "India"
    },
    licenseNumber: "DL-PHARM-002",
    taxId: "GST987654321",
    paymentTerms: "Net_30",
    rating: 4.2,
    isActive: true,
    notes: "Specializes in emergency medicines",
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

const supplierResults = db.suppliers.insertMany(sampleSuppliers);
const supplierIds = Object.values(supplierResults.insertedIds);

print('Inserting sample medicines...');
const sampleMedicines = [
  {
    name: "Paracetamol 500mg",
    description: "Pain reliever and fever reducer",
    manufacturer: "ABC Pharma",
    category: "Tablet",
    price: 25.50,
    stockQuantity: 100,
    minStockLevel: 20,
    maxStockLevel: 500,
    batchNumber: "PAR001",
    expiryDate: new Date('2025-12-31'),
    supplierId: supplierIds[0],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Amoxicillin 250mg",
    description: "Antibiotic for bacterial infections",
    manufacturer: "XYZ Medicines",
    category: "Capsule",
    price: 45.00,
    stockQuantity: 15,
    minStockLevel: 25,
    maxStockLevel: 200,
    batchNumber: "AMX001",
    expiryDate: new Date('2024-08-15'),
    supplierId: supplierIds[1],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Cough Syrup",
    description: "Relief from cough and cold",
    manufacturer: "PQR Pharmaceuticals",
    category: "Syrup",
    price: 85.75,
    stockQuantity: 50,
    minStockLevel: 10,
    maxStockLevel: 100,
    batchNumber: "CS001",
    expiryDate: new Date('2025-03-20'),
    supplierId: supplierIds[0],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

const medicineResults = db.medicines.insertMany(sampleMedicines);
const medicineIds = Object.values(medicineResults.insertedIds);

print('Inserting sample orders...');
const sampleOrders = [
  {
    orderNumber: "ORD-20250127-0001",
    supplierId: supplierIds[0],
    items: [
      {
        medicineId: medicineIds[0],
        quantity: 50,
        unitPrice: 25.50,
        totalPrice: 1275.00
      },
      {
        medicineId: medicineIds[2],
        quantity: 20,
        unitPrice: 85.75,
        totalPrice: 1715.00
      }
    ],
    orderDate: new Date(),
    expectedDeliveryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
    status: "Confirmed",
    totalAmount: 2990.00,
    tax: 538.20,
    discount: 0,
    finalAmount: 3528.20,
    notes: "Urgent order for stock replenishment",
    paymentStatus: "Pending",
    paymentMethod: "Bank_Transfer",
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

db.orders.insertMany(sampleOrders);

print('Sample data inserted successfully!');
print('Database initialization completed.');
