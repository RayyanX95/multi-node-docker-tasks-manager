import { useEffect, useState } from "react";
import "./App.css";
import { API_BASE_URL } from "./constants";

function App() {
  const [tasks, setTasks] = useState([]);
  const [newTask, setNewTask] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  // Fetch tasks on component mount
  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const response = await fetch(`${API_BASE_URL}/api/tasks`);
      if (!response.ok) throw new Error("Failed to fetch tasks");
      const data = await response.json();
      setTasks(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newTask.trim()) return;

    try {
      setIsLoading(true);
      setError(null);
      const response = await fetch(`${API_BASE_URL}/api/tasks`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ title: newTask }),
      });

      if (!response.ok) throw new Error("Failed to create task");

      const createdTask = await response.json();
      setTasks([...tasks, createdTask]);
      setNewTask("");
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="app-container">
      <div className="content-wrapper">
        <header className="app-header">
          <div className="header-content">
            <h1 className="app-title">
              <span className="title-icon">✓</span>
              Task Manager
            </h1>
            <p className="app-subtitle">Organize your work, achieve your goals</p>
          </div>
        </header>

        <div className="main-content">
          {/* Task Creation Form */}
          <div className="task-form-card">
            <h2 className="card-title">Create New Task</h2>
            <form onSubmit={handleSubmit} className="task-form">
              <div className="input-group">
                <input
                  type="text"
                  value={newTask}
                  onChange={(e) => setNewTask(e.target.value)}
                  placeholder="What needs to be done?"
                  className="task-input"
                  disabled={isLoading}
                />
                <button
                  type="submit"
                  className="submit-button"
                  disabled={isLoading || !newTask.trim()}
                >
                  {isLoading ? (
                    <span className="loading-spinner"></span>
                  ) : (
                    <>
                      <span className="button-icon">+</span>
                      Add Task
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>

          {/* Error Message */}
          {error && (
            <div className="error-message">
              <span className="error-icon">⚠️</span>
              {error}
            </div>
          )}

          {/* Tasks List */}
          <div className="tasks-card">
            <div className="card-header">
              <h2 className="card-title">Your Tasks</h2>
              <span className="task-count">{tasks.length} {tasks.length === 1 ? 'task' : 'tasks'}</span>
            </div>

            {isLoading && tasks.length === 0 ? (
              <div className="loading-state">
                <div className="loading-spinner large"></div>
                <p>Loading tasks...</p>
              </div>
            ) : tasks.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">📝</div>
                <h3>No tasks yet</h3>
                <p>Create your first task to get started!</p>
              </div>
            ) : (
              <ul className="tasks-list">
                {tasks.map((task, index) => (
                  <li
                    key={task.id}
                    className="task-item"
                    style={{ animationDelay: `${index * 0.05}s` }}
                  >
                    <div className="task-checkbox">
                      <div className="checkbox-inner"></div>
                    </div>
                    <div className="task-content">
                      <span className="task-title">{task.title}</span>
                      {task.created_at && (
                        <span className="task-date">
                          {new Date(task.created_at).toLocaleDateString()}
                        </span>
                      )}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
