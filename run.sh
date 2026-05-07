#!/bin/bash
cd /workspaces/interactive-calender-with-events

echo "🚀 TaskForge Pro - One Command Setup Starting..."

# 1. Install dependencies
echo "📦 Installing Python packages..."
pip install flask-cors mysql-connector-python --quiet

# 2. Start MySQL if not running
echo "🗄️ Starting MySQL..."
sudo service mysql start 2>/dev/null || true
sleep 2

# 3. Create database + tables from website.sql
echo "📊 Creating database schema..."
mysql -u root -e "DROP DATABASE IF EXISTS taskforge; CREATE DATABASE taskforge CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root taskforge < website.sql

# 4. Kill old Flask process if running
pkill -f "python3 website.py" 2>/dev/null || true

# 5. Start Flask backend in background
echo "⚡ Starting Flask API on port 5000..."
python3 website.py > flask.log 2>&1 &
FLASK_PID=$!
sleep 3

# 6. Start simple HTTP server for frontend
echo "🌐 Starting Frontend on port 8080..."
python3 -m http.server 8080 > server.log 2>&1 &
SERVER_PID=$!
sleep 2

echo "✅ TaskForge Pro is LIVE!"
echo "📱 Frontend: http://localhost:8080/website.html"
echo "🔌 Backend API: http://localhost:5000/api"
echo "👤 Login: dinesh@taskforge.com / admin123"
echo ""
echo "Press CTRL+C to stop all services"

# 7. Cleanup on exit
trap "kill $FLASK_PID $SERVER_PID 2>/dev/null; echo '🛑 Services stopped'" EXIT
wait