import React from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import AppNavbar from './components/AppNavbar'
import Home from './pages/Home'
import Tasks from './pages/Tasks'
import TaskDetail from './pages/TaskDetail'
import CreateTask from './pages/CreateTask'
import Team from './pages/Team'
import Settings from './pages/Settings'
import Admin from './pages/Admin'
function App() {
  return (
    <BrowserRouter>
      <AppNavbar />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/tasks" element={<Tasks />} />
        <Route path="/tasks/:id" element={<TaskDetail />} />
        <Route path="/tasks/create" element={<CreateTask />} />
        <Route path="/team" element={<Team />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/admin" element={<Admin />} />
      </Routes>
    </BrowserRouter>
  )
}
export default App
