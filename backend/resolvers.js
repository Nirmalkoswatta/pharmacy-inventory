const { GraphQLScalarType, Kind } = require('graphql');
const Medicine = require('./models/Medicine');
const Supplier = require('./models/Supplier');
const Order = require('./models/Order');

// Custom Date scalar
const DateType = new GraphQLScalarType({
  name: 'Date',
  description: 'Custom Date scalar type',
  serialize: (value) => value.toISOString(),
  parseValue: (value) => new Date(value),
  parseLiteral: (ast) => {
    if (ast.kind === Kind.STRING) {
      return new Date(ast.value);
    }
    return null;
  }
});

const resolvers = {
  Date: DateType,

  // Type resolvers
  Medicine: {
    supplier: async (medicine) => {
      return await Supplier.findById(medicine.supplierId);
    },
    isLowStock: (medicine) => medicine.stockQuantity <= medicine.minStockLevel,
    isExpired: (medicine) => new Date() > medicine.expiryDate,
    isExpiringSoon: (medicine) => {
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      return medicine.expiryDate <= thirtyDaysFromNow && medicine.expiryDate > new Date();
    }
  },

  Supplier: {
    fullAddress: (supplier) => {
      const { address } = supplier;
      return `${address.street}, ${address.city}, ${address.state} ${address.zipCode}, ${address.country}`;
    }
  },

  Order: {
    supplier: async (order) => {
      return await Supplier.findById(order.supplierId);
    },
    items: async (order) => {
      const populatedItems = [];
      for (const item of order.items) {
        const medicine = await Medicine.findById(item.medicineId);
        populatedItems.push({
          medicine,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice
        });
      }
      return populatedItems;
    },
    orderAge: (order) => {
      return Math.floor((new Date() - order.orderDate) / (1000 * 60 * 60 * 24));
    },
    isOverdue: (order) => {
      return order.status !== 'Delivered' && new Date() > order.expectedDeliveryDate;
    }
  },

  Query: {
    // Medicine Queries
    medicines: async (_, { filter = {}, search, limit = 50, offset = 0 }) => {
      let query = {};
      
      if (filter.category) query.category = filter.category;
      if (filter.manufacturer) query.manufacturer = new RegExp(filter.manufacturer, 'i');
      if (filter.supplierId) query.supplierId = filter.supplierId;
      if (filter.isLowStock === true) {
        query.$expr = { $lte: ['$stockQuantity', '$minStockLevel'] };
      }
      if (filter.isExpired === true) {
        query.expiryDate = { $lt: new Date() };
      }
      if (filter.isExpiringSoon === true) {
        const thirtyDaysFromNow = new Date();
        thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
        query.expiryDate = { 
          $lte: thirtyDaysFromNow, 
          $gt: new Date() 
        };
      }

      if (search) {
        query.$or = [
          { name: new RegExp(search, 'i') },
          { manufacturer: new RegExp(search, 'i') },
          { batchNumber: new RegExp(search, 'i') }
        ];
      }

      return await Medicine.find(query)
        .sort({ createdAt: -1 })
        .limit(limit)
        .skip(offset);
    },

    medicine: async (_, { id }) => {
      return await Medicine.findById(id);
    },

    medicinesBySupplier: async (_, { supplierId }) => {
      return await Medicine.find({ supplierId, isActive: true });
    },

    // Supplier Queries
    suppliers: async (_, { search, limit = 50, offset = 0 }) => {
      let query = {};
      
      if (search) {
        query.$or = [
          { name: new RegExp(search, 'i') },
          { contactPerson: new RegExp(search, 'i') },
          { email: new RegExp(search, 'i') }
        ];
      }

      return await Supplier.find(query)
        .sort({ name: 1 })
        .limit(limit)
        .skip(offset);
    },

    supplier: async (_, { id }) => {
      return await Supplier.findById(id);
    },

    activeSuppliers: async () => {
      return await Supplier.find({ isActive: true }).sort({ name: 1 });
    },

    // Order Queries
    orders: async (_, { filter = {}, limit = 50, offset = 0 }) => {
      let query = {};
      
      if (filter.status) query.status = filter.status;
      if (filter.paymentStatus) query.paymentStatus = filter.paymentStatus;
      if (filter.supplierId) query.supplierId = filter.supplierId;
      
      if (filter.startDate || filter.endDate) {
        query.orderDate = {};
        if (filter.startDate) query.orderDate.$gte = filter.startDate;
        if (filter.endDate) query.orderDate.$lte = filter.endDate;
      }

      return await Order.find(query)
        .sort({ orderDate: -1 })
        .limit(limit)
        .skip(offset);
    },

    order: async (_, { id }) => {
      return await Order.findById(id);
    },

    ordersBySupplier: async (_, { supplierId }) => {
      return await Order.find({ supplierId }).sort({ orderDate: -1 });
    },

    // Analytics
    dashboardStats: async () => {
      const [
        totalMedicines,
        lowStockMedicines,
        expiredMedicines,
        expiringSoonMedicines,
        totalSuppliers,
        activeSuppliers,
        totalOrders,
        pendingOrders,
        revenueData
      ] = await Promise.all([
        Medicine.countDocuments({ isActive: true }),
        Medicine.countDocuments({ 
          isActive: true,
          $expr: { $lte: ['$stockQuantity', '$minStockLevel'] } 
        }),
        Medicine.countDocuments({ 
          isActive: true,
          expiryDate: { $lt: new Date() } 
        }),
        Medicine.countDocuments({ 
          isActive: true,
          expiryDate: { 
            $lte: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            $gt: new Date() 
          } 
        }),
        Supplier.countDocuments(),
        Supplier.countDocuments({ isActive: true }),
        Order.countDocuments(),
        Order.countDocuments({ status: 'Pending' }),
        Order.aggregate([
          {
            $group: {
              _id: null,
              totalRevenue: { $sum: '$finalAmount' },
              monthlyRevenue: {
                $sum: {
                  $cond: {
                    if: {
                      $gte: [
                        '$orderDate',
                        new Date(new Date().getFullYear(), new Date().getMonth(), 1)
                      ]
                    },
                    then: '$finalAmount',
                    else: 0
                  }
                }
              }
            }
          }
        ])
      ]);

      const revenue = revenueData[0] || { totalRevenue: 0, monthlyRevenue: 0 };

      return {
        totalMedicines,
        lowStockMedicines,
        expiredMedicines,
        expiringSoonMedicines,
        totalSuppliers,
        activeSuppliers,
        totalOrders,
        pendingOrders,
        totalRevenue: revenue.totalRevenue,
        monthlyRevenue: revenue.monthlyRevenue
      };
    }
  },

  Mutation: {
    // Medicine Mutations
    createMedicine: async (_, { input }) => {
      const medicine = new Medicine(input);
      return await medicine.save();
    },

    updateMedicine: async (_, { id, input }) => {
      return await Medicine.findByIdAndUpdate(id, input, { new: true });
    },

    deleteMedicine: async (_, { id }) => {
      await Medicine.findByIdAndUpdate(id, { isActive: false });
      return true;
    },

    updateStock: async (_, { id, quantity }) => {
      return await Medicine.findByIdAndUpdate(
        id,
        { $inc: { stockQuantity: quantity } },
        { new: true }
      );
    },

    // Supplier Mutations
    createSupplier: async (_, { input }) => {
      const supplier = new Supplier(input);
      return await supplier.save();
    },

    updateSupplier: async (_, { id, input }) => {
      return await Supplier.findByIdAndUpdate(id, input, { new: true });
    },

    deleteSupplier: async (_, { id }) => {
      await Supplier.findByIdAndUpdate(id, { isActive: false });
      return true;
    },

    // Order Mutations
    createOrder: async (_, { input }) => {
      // Calculate totals
      let totalAmount = 0;
      const processedItems = input.items.map(item => {
        const totalPrice = item.quantity * item.unitPrice;
        totalAmount += totalPrice;
        return {
          ...item,
          totalPrice
        };
      });

      const finalAmount = totalAmount + (input.tax || 0) - (input.discount || 0);

      const order = new Order({
        ...input,
        items: processedItems,
        totalAmount,
        finalAmount
      });

      return await order.save();
    },

    updateOrder: async (_, { id, input }) => {
      return await Order.findByIdAndUpdate(id, input, { new: true });
    },

    cancelOrder: async (_, { id }) => {
      return await Order.findByIdAndUpdate(
        id,
        { status: 'Cancelled' },
        { new: true }
      );
    },

    markOrderDelivered: async (_, { id, deliveryDate }) => {
      return await Order.findByIdAndUpdate(
        id,
        { 
          status: 'Delivered',
          actualDeliveryDate: deliveryDate
        },
        { new: true }
      );
    }
  }
};

module.exports = resolvers;
