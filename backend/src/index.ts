import express from "express";
import cors from "cors";

import pool from "./db";

const app = express();

app.use(cors()); // allow FE to call BE
app.use(express.json()); // parse JSON request bodies

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



app.listen(4000, () => console.log("BE running on http://localhost:4000"));
