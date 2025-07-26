const Medicine = require('../models/Medicine');

describe('Medicine Model', () => {
  test('should create a medicine with valid data', () => {
    const medicineData = {
      name: 'Test Medicine',
      description: 'A test medicine',
      price: 10.99,
      stock: 100,
      category: 'Test Category',
      manufacturer: 'Test Manufacturer',
      expiryDate: new Date('2025-12-31'),
      batchNumber: 'BATCH001',
      dosage: '10mg',
      sideEffects: ['Nausea', 'Headache']
    };

    const medicine = new Medicine(medicineData);
    expect(medicine.name).toBe('Test Medicine');
    expect(medicine.price).toBe(10.99);
    expect(medicine.stock).toBe(100);
    expect(medicine.isLowStock).toBe(false);
  });

  test('should mark medicine as low stock when stock is below threshold', () => {
    const medicineData = {
      name: 'Low Stock Medicine',
      price: 5.99,
      stock: 5,
      lowStockThreshold: 10
    };

    const medicine = new Medicine(medicineData);
    expect(medicine.isLowStock).toBe(true);
  });

  test('should calculate days until expiry correctly', () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30); // 30 days from now

    const medicineData = {
      name: 'Expiring Medicine',
      price: 15.99,
      stock: 50,
      expiryDate: futureDate
    };

    const medicine = new Medicine(medicineData);
    const daysUntilExpiry = medicine.daysUntilExpiry;
    expect(daysUntilExpiry).toBeGreaterThan(25);
    expect(daysUntilExpiry).toBeLessThanOrEqual(30);
  });
});
