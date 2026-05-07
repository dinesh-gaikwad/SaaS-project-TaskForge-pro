# TaskForge Pro - Enterprise Task Management SaaS

> Microsoft-level full-stack project built with only 5 files. 
> A complete Jira/Asana alternative with Kanban, Calendar, Analytics, and Real-time Dashboard.

## 🚀 Live Demo
- **Frontend**: http://localhost:8080/website.html  
- **Backend API**: http://localhost:5000/api
- **Demo Login**: `dinesh@taskforge.com` / `admin123`

## 📦 Tech Stack - 5 Files Only
| File | Lines | Purpose |
| --- | --- | --- |
| `website.html` | 1500 | Complete responsive UI with 5 pages + modals |
| `website.css` | 1500 | Dark theme + glassmorphism + responsive design |
| `website.js` | 1500 | Vanilla JS SPA with drag-drop, charts, API calls |
| `website.py` | 2000 | Flask REST API with 20+ endpoints + business logic |
| `website.sql` | 1000 | MySQL schema + triggers + stored procedures + seed data |

## ✨ Features
### Core Functionality
- **Kanban Board** - Drag & drop tasks between columns with real-time updates
- **Calendar View** - Monthly calendar with task scheduling and due dates  
- **Dashboard Analytics** - Live stats: total, completed, pending, overdue tasks + Chart.js visualizations
- **Task Management** - CRUD operations with priority, assignee, due date, description
- **User Management** - Role-based access: Admin, Manager, Member
- **Real-time Activity Feed** - Track all user actions

### Enterprise Features
- **Search & Filter** - Global search across tasks, projects, users
- **Responsive Design** - Mobile-first, works on all devices
- **Toast Notifications** - Success/error feedback system
- **Data Persistence** - MySQL with foreign keys, indexes, and triggers

## 🛠️ One Command Setup
Run everything from 0 in a single command:

```bash
chmod +x run.sh && bash run.sh