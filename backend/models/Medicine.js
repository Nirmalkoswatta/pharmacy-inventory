const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  manufacturer: {
    type: String,
    required: true,
    trim: true
  },
  category: {
    type: String,
    required: true,
    enum: ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Ointment', 'Other']
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  stockQuantity: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  minStockLevel: {
    type: Number,
    required: true,
    min: 0,
    default: 10
  },
  maxStockLevel: {
    type: Number,
    required: true,
    min: 0,
    default: 1000
  },
  batchNumber: {
    type: String,
    required: true,
    trim: true
  },
  expiryDate: {
    type: Date,
    required: true
  },
  supplierId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Supplier',
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Index for better query performance
medicineSchema.index({ name: 1, manufacturer: 1 });
medicineSchema.index({ category: 1 });
medicineSchema.index({ supplierId: 1 });
medicineSchema.index({ expiryDate: 1 });

// Virtual for low stock alert
medicineSchema.virtual('isLowStock').get(function() {
  return this.stockQuantity <= this.minStockLevel;
});

// Virtual for expired status
medicineSchema.virtual('isExpired').get(function() {
  return new Date() > this.expiryDate;
});

// Virtual for expiring soon (within 30 days)
medicineSchema.virtual('isExpiringSoon').get(function() {
  const thirtyDaysFromNow = new Date();
  thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
  return this.expiryDate <= thirtyDaysFromNow && this.expiryDate > new Date();
});

// Virtual for days until expiry
medicineSchema.virtual('daysUntilExpiry').get(function() {
  const today = new Date();
  const expiry = new Date(this.expiryDate);
  const timeDiff = expiry.getTime() - today.getTime();
  const daysDiff = Math.ceil(timeDiff / (1000 * 3600 * 24));
  return daysDiff;
});

module.exports = mongoose.model('Medicine', medicineSchema);
