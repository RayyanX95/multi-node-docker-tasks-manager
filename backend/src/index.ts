import express from "express";
import cors from "cors";

import pool from "./db";

const app = express();

app.use(cors()); // allow FE to call BE
app.use(express.json()); // parse JSON request bodies

// Initialize database schema
async function initializeDatabase() {
  try {
    console.log("🔄 Initializing database schema...");
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log("✅ Database schema initialized successfully");
  } catch (err) {
    console.error("❌ Database initialization failed:", err);
    throw err; // Let the startup fail if DB init fails
  }
}

app.get("/", (req, res) => {
  res.json({ message: "High five ✋" });
});


// GET all tasks
app.get("/api/tasks", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM tasks");
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

// POST a new task
app.post("/api/tasks", async (req, res) => {
  const { title } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO tasks(title) VALUES($1) RETURNING *",
      [title]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" })
  }
});


// Start server with database initialization
async function startServer() {
  try {
    // Initialize database first
    await initializeDatabase();
    
    // Then start the server
    app.listen(4000, () => {
      console.log("🚀 Backend server running on http://localhost:4000");
    });
  } catch (err) {
    console.error("💥 Failed to start server:", err);
    process.exit(1); // Exit with error code
  }
}

// Start the application
startServer();
