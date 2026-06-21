from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.db.init_db import init_db
from app.api.v1.routes.routes import router as routes_router
from app.api.v1.routes.bookings import router as bookings_router
from app.api.v1.routes.alerts import router as alerts_router
from app.api.v1.routes.auth import router as auth_router
from app.api.v1.routes.users import router as users_router
from app.api.v1.routes.admin import router as admin_router
from app.api.v1.routes.analytics import router as analytics_router
from app.api.v1.routes.dashboard import router as dashboard_router
from app.api.v1.routes.reports import router as reports_router
from app.api.v1.routes.seed import router as seed_router
from app.api.v1.routes.health import router as health_router
from app.api.v1.routes.meta import router as meta_router

app = FastAPI(title=settings.APP_NAME, version=settings.APP_VERSION)
app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(routes_router)
app.include_router(bookings_router)
app.include_router(alerts_router)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(admin_router)
app.include_router(analytics_router)
app.include_router(dashboard_router)
app.include_router(reports_router)
app.include_router(seed_router)
app.include_router(health_router)
app.include_router(meta_router)

@app.on_event("startup")
def startup():
    init_db()

@app.get("/", response_class=HTMLResponse)
def home():
    return """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ferry Ops Dashboard</title>
<link rel="stylesheet" href="/static/style.css">
</head>
<body>
<header>
  <div class="wrap top">
    <div>
      <h1>Real-Time Ferry Operations & Passenger Management</h1>
      <p class="sub">Responsive dashboard for routes, schedules, alerts, bookings and analytics</p>
    </div>
    <div class="toolbar" style="min-width:280px;max-width:360px;width:100%">
      <button onclick="refreshAll()">Refresh Live Data</button>
    </div>
  </div>
</header>
<div class="grid">
  <div class="card col-12">
    <div class="stats">
      <div class="stat"><div class="label">Active Routes</div><div class="value" id="activeRoutes">0</div></div>
      <div class="stat"><div class="label">Active Ferries</div><div class="value" id="activeFerries">0</div></div>
      <div class="stat"><div class="label">Confirmed Bookings</div><div class="value" id="confirmedBookings">0</div></div>
      <div class="stat"><div class="label">Live Alerts</div><div class="value" id="liveAlerts">0</div></div>
    </div>
  </div>
  <div class="card col-8">
    <div class="searchbox">
      <input id="searchInput" placeholder="Search route, terminal, or destination..." oninput="renderRoutes()" />
      <button onclick="refreshRoutes()">Search</button>
    </div>
    <div style="margin-top:12px">
      <div class="pill">Ferry Routes</div>
      <div class="list" id="routesList" style="margin-top:12px"></div>
    </div>
  </div>
  <div class="card col-4">
    <div class="pill">Alerts & Announcements</div>
    <div class="list" id="alertsList" style="margin-top:12px"></div>
  </div>
  <div class="card col-6">
    <div class="pill">Create Booking</div>
    <div class="two" style="margin-top:12px">
      <input id="passengerName" placeholder="Passenger name" />
      <input id="routeId" type="number" placeholder="Route ID" />
      <input id="seats" type="number" min="1" value="1" placeholder="Seats" />
      <select id="bookingType">
        <option value="confirmed">Confirmed</option>
        <option value="pending">Pending</option>
      </select>
    </div>
    <button style="margin-top:12px" onclick="createBooking()">Book Seat</button>
    <div class="small" id="bookingMsg" style="margin-top:10px"></div>
  </div>
  <div class="card col-6">
    <div class="pill">Add Alert</div>
    <div class="two" style="margin-top:12px">
      <select id="alertLevel">
        <option value="Info">Info</option>
        <option value="Warning">Warning</option>
        <option value="Critical">Critical</option>
      </select>
      <input id="alertMessage" placeholder="Alert message" />
    </div>
    <button style="margin-top:12px" onclick="addAlert()">Publish Alert</button>
    <div class="small" id="alertMsg" style="margin-top:10px"></div>
  </div>
  <div class="card col-12">
    <div class="pill">System Summary</div>
    <div class="meta" id="summary" style="margin-top:10px"></div>
  </div>
</div>
<div class="footer">Ferry Operations Dashboard • Single-file FastAPI project</div>
<script src="/static/app.js"></script>
</body>
</html>
"""
