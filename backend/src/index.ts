import express from "express";
import cors from "cors";

const app = express();

app.use(cors()); // allow FE to call BE

app.get("/", (req, res) => {
  res.json({ message: "High five ✋" });
});

app.get("/api/tasks", (req, res) => {
  const tasks = [
    { id: 1, title: "Learn Docker" },
    { id: 2, title: "Build multi-service app" },
  ];
  res.json(tasks);
});

app.listen(4000, () => console.log("BE running on http://localhost:4000"));
