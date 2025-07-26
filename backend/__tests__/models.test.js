const Medicine = require('../models/Medicine');
const mongoose = require('mongoose');

describe('Medicine Model', () => {
  test('should create a medicine with valid data', () => {
    const medicineData = {
      name: 'Test Medicine',
      description: 'A test medicine',
      manufacturer: 'Test Manufacturer',
      category: 'Tablet',
      price: 10.99,
      stockQuantity: 100,
      minStockLevel: 10,
      maxStockLevel: 1000,
      batchNumber: 'BATCH001',
      expiryDate: new Date('2025-12-31'),
      supplierId: new mongoose.Types.ObjectId()
    };

    const medicine = new Medicine(medicineData);
    expect(medicine.name).toBe('Test Medicine');
    expect(medicine.price).toBe(10.99);
    expect(medicine.stockQuantity).toBe(100);
    expect(medicine.isLowStock).toBe(false);
  });

  test('should mark medicine as low stock when stock is below threshold', () => {
    const medicineData = {
      name: 'Low Stock Medicine',
      manufacturer: 'Test Manufacturer',
      category: 'Capsule',
      price: 5.99,
      stockQuantity: 5,
      minStockLevel: 10,
      maxStockLevel: 1000,
      batchNumber: 'BATCH002',
      expiryDate: new Date('2025-12-31'),
      supplierId: new mongoose.Types.ObjectId()
    };

    const medicine = new Medicine(medicineData);
    expect(medicine.isLowStock).toBe(true);
  });

  test('should calculate days until expiry correctly', () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30); // 30 days from now

    const medicineData = {
      name: 'Expiring Medicine',
      manufacturer: 'Test Manufacturer',
      category: 'Syrup',
      price: 15.99,
      stockQuantity: 50,
      minStockLevel: 10,
      maxStockLevel: 1000,
      batchNumber: 'BATCH003',
      expiryDate: futureDate,
      supplierId: new mongoose.Types.ObjectId()
    };

    const medicine = new Medicine(medicineData);
    const daysUntilExpiry = medicine.daysUntilExpiry;
    expect(daysUntilExpiry).toBeGreaterThan(25);
    expect(daysUntilExpiry).toBeLessThanOrEqual(30);
  });
});
