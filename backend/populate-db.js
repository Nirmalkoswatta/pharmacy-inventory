const mongoose = require('mongoose');
require('dotenv').config();

const Medicine = require('./models/Medicine');
const Supplier = require('./models/Supplier');
const Order = require('./models/Order');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/pharmacy';

async function populateDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connected to MongoDB');

    // Clear existing data
    await Promise.all([
      Medicine.deleteMany({}),
      Supplier.deleteMany({}),
      Order.deleteMany({})
    ]);
    console.log('🧹 Cleared existing data');

    // Create sample suppliers
    const suppliers = await Supplier.create([
      {
        name: 'MediSupply Inc.',
        contactPerson: 'John Smith',
        email: 'john@medisupply.com',
        phone: '+1-555-0101',
        address: {
          street: '123 Medical District',
          city: 'Healthcare City',
          state: 'California',
          zipCode: '12345',
          country: 'USA'
        },
        licenseNumber: 'LIC001',
        taxId: 'TAX001',
        paymentTerms: 'Net 30',
        rating: 4,
        isActive: true
      },
      {
        name: 'PharmaCorp',
        contactPerson: 'Sarah Johnson',
        email: 'sarah@pharmacorp.com',
        phone: '+1-555-0202',
        address: {
          street: '456 Pharma Street',
          city: 'Medicine Town',
          state: 'New York',
          zipCode: '67890',
          country: 'USA'
        },
        licenseNumber: 'LIC002',
        taxId: 'TAX002',
        paymentTerms: 'Net 60',
        rating: 5,
        isActive: true
      },
      {
        name: 'Global Health Solutions',
        contactPerson: 'Dr. Michael Brown',
        email: 'michael@globalhealthsolutions.com',
        phone: '+1-555-0303',
        address: {
          street: '789 Health Avenue',
          city: 'Wellness City',
          state: 'Texas',
          zipCode: '54321',
          country: 'USA'
        },
        licenseNumber: 'LIC003',
        taxId: 'TAX003',
        paymentTerms: 'Cash',
        rating: 4,
        isActive: true
      }
    ]);
    console.log('✅ Created sample suppliers');

    // Create sample medicines
    const medicines = await Medicine.create([
      {
        name: 'Paracetamol 500mg',
        description: 'Pain reliever and fever reducer',
        manufacturer: 'HealthPharma Ltd.',
        category: 'Tablet',
        price: 0.25,
        stockQuantity: 500,
        minStockLevel: 50,
        maxStockLevel: 1000,
        batchNumber: 'PAR001',
        expiryDate: new Date('2025-12-31'),
        supplierId: suppliers[0]._id
      },
      {
        name: 'Amoxicillin 250mg',
        description: 'Antibiotic for bacterial infections',
        manufacturer: 'BioPharma Inc.',
        category: 'Capsule',
        price: 0.85,
        stockQuantity: 15, // Low stock
        minStockLevel: 25,
        maxStockLevel: 500,
        batchNumber: 'AMX001',
        expiryDate: new Date('2025-08-15'),
        supplierId: suppliers[1]._id
      },
      {
        name: 'Cough Syrup',
        description: 'Relief for cough and cold symptoms',
        manufacturer: 'NaturalMeds Co.',
        category: 'Syrup',
        price: 4.50,
        stockQuantity: 75,
        minStockLevel: 20,
        maxStockLevel: 200,
        batchNumber: 'SYR001',
        expiryDate: new Date('2024-03-15'), // Expired
        supplierId: suppliers[2]._id
      },
      {
        name: 'Insulin Injection',
        description: 'Diabetes management medication',
        manufacturer: 'DiabetesCare Pharma',
        category: 'Injection',
        price: 25.00,
        stockQuantity: 30,
        minStockLevel: 10,
        maxStockLevel: 100,
        batchNumber: 'INS001',
        expiryDate: new Date('2025-09-30'),
        supplierId: suppliers[0]._id
      },
      {
        name: 'Antiseptic Cream',
        description: 'Topical antibacterial cream',
        manufacturer: 'SkinCare Solutions',
        category: 'Cream',
        price: 3.25,
        stockQuantity: 8, // Low stock
        minStockLevel: 15,
        maxStockLevel: 150,
        batchNumber: 'CRM001',
        expiryDate: new Date('2025-06-20'),
        supplierId: suppliers[1]._id
      },
      {
        name: 'Vitamin C Tablets',
        description: 'Immune system support supplement',
        manufacturer: 'VitaLife Corp.',
        category: 'Tablet',
        price: 12.99,
        stockQuantity: 120,
        minStockLevel: 30,
        maxStockLevel: 300,
        batchNumber: 'VIT001',
        expiryDate: new Date('2026-02-28'),
        supplierId: suppliers[2]._id
      }
    ]);
    console.log('✅ Created sample medicines');

    // Create sample orders
    const orders = await Order.create([
      {
        orderNumber: 'ORD001',
        supplierId: suppliers[0]._id,
        items: [
          {
            medicineId: medicines[0]._id,
            quantity: 100,
            unitPrice: 0.25,
            totalPrice: 25.00
          },
          {
            medicineId: medicines[3]._id,
            quantity: 20,
            unitPrice: 25.00,
            totalPrice: 500.00
          }
        ],
        totalAmount: 525.00,
        tax: 52.50,
        discount: 0,
        finalAmount: 577.50,
        status: 'Delivered',
        orderDate: new Date('2025-07-01'),
        expectedDeliveryDate: new Date('2025-07-10'),
        actualDeliveryDate: new Date('2025-07-08'),
        paymentStatus: 'Paid',
        paymentMethod: 'Bank Transfer'
      },
      {
        orderNumber: 'ORD002',
        supplierId: suppliers[1]._id,
        items: [
          {
            medicineId: medicines[1]._id,
            quantity: 50,
            unitPrice: 0.85,
            totalPrice: 42.50
          }
        ],
        totalAmount: 42.50,
        tax: 4.25,
        discount: 0,
        finalAmount: 46.75,
        status: 'Pending',
        orderDate: new Date('2025-07-20'),
        expectedDeliveryDate: new Date('2025-07-30'),
        paymentStatus: 'Pending',
        paymentMethod: 'Credit Card'
      },
      {
        orderNumber: 'ORD003',
        supplierId: suppliers[2]._id,
        items: [
          {
            medicineId: medicines[5]._id,
            quantity: 25,
            unitPrice: 12.99,
            totalPrice: 324.75
          }
        ],
        totalAmount: 324.75,
        tax: 32.48,
        discount: 10.00,
        finalAmount: 347.23,
        status: 'Confirmed',
        orderDate: new Date('2025-07-25'),
        expectedDeliveryDate: new Date('2025-08-05'),
        paymentStatus: 'Partial',
        paymentMethod: 'Bank Transfer'
      }
    ]);
    console.log('✅ Created sample orders');

    console.log('🎉 Database populated successfully!');
    console.log(`📊 Summary:
    - Suppliers: ${suppliers.length}
    - Medicines: ${medicines.length} (${medicines.filter(m => m.stockQuantity <= m.minStockLevel).length} low stock)
    - Orders: ${orders.length}
    `);

    await mongoose.connection.close();
    console.log('✅ Database connection closed');

  } catch (error) {
    console.error('❌ Error populating database:', error);
    process.exit(1);
  }
}

// Run the population script
if (require.main === module) {
  populateDatabase();
}

module.exports = populateDatabase;
