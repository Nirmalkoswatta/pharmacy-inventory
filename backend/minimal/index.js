const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Pharmacy Backend API",
    status: "running",
    version: "1.0.0",
    timestamp: new Date().toISOString()
  });
});

// Health endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Sample data endpoints
app.get("/medicines", (req, res) => {
  res.json({
    data: [
      { id: 1, name: "Aspirin", price: 9.99, quantity: 100 },
      { id: 2, name: "Ibuprofen", price: 12.50, quantity: 75 }
    ]
  });
});

app.get("/suppliers", (req, res) => {
  res.json({
    data: [
      { id: 1, name: "MediSupply Corp", contact: "contact@medisupply.com" }
    ]
  });
});

app.get("/orders", (req, res) => {
  res.json({
    data: [
      { id: 1, medicine: "Aspirin", quantity: 50, status: "pending" }
    ]
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Backend running on port ${port}`);
});
