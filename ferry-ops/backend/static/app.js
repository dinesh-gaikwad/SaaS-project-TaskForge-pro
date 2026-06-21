let routesCache = [];
let alertsCache = [];

async function fetchJson(url, options={}) {
  const res = await fetch(url, options);
  const data = await res.json();
  if (!res.ok) throw new Error(data.detail || data.message || 'Request failed');
  return data;
}

function badgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('on-time') || s.includes('active') || s.includes('confirmed')) return 'ok';
  if (s.includes('delay') || s.includes('warn') || s.includes('pending')) return 'warn';
  return 'bad';
}

function renderStats(data) {
  document.getElementById('activeRoutes').textContent = data.active_routes ?? 0;
  document.getElementById('activeFerries').textContent = data.active_ferries ?? 0;
  document.getElementById('confirmedBookings').textContent = data.confirmed_bookings ?? 0;
  document.getElementById('liveAlerts').textContent = data.live_alerts ?? 0;
  document.getElementById('summary').innerHTML =
    `Server time: <b>${data.server_time}</b> · Capacity safety enforced · Real-time refresh every 5 seconds`;
}

function renderRoutes() {
  const q = (document.getElementById('searchInput').value || '').toLowerCase();
  const list = document.getElementById('routesList');
  const filtered = routesCache.filter(r =>
    [r.route_name, r.origin, r.destination, r.status, String(r.id)].join(' ').toLowerCase().includes(q)
  );
  if (!filtered.length) {
    list.innerHTML = '<div class="item"><div class="meta">No routes found.</div></div>';
    return;
  }
  list.innerHTML = filtered.map(r => `
    <div class="item">
      <h3>#${r.id} ${r.route_name} <span class="badge ${badgeClass(r.status)}">${r.status}</span></h3>
      <div class="meta">
        ${r.origin} → ${r.destination}<br>
        Departure: <b>${r.departure_time}</b> · Capacity: <b>${r.capacity}</b><br>
        Current load: <b>${r.booked_seats}</b> seats booked
      </div>
    </div>
  `).join('');
}

function renderAlerts() {
  const list = document.getElementById('alertsList');
  if (!alertsCache.length) {
    list.innerHTML = '<div class="item"><div class="meta">No alerts available.</div></div>';
    return;
  }
  list.innerHTML = alertsCache.map(a => `
    <div class="item">
      <h3>${a.level} <span class="badge ${badgeClass(a.level)}">${a.level}</span></h3>
      <div class="meta">${a.message}</div>
      <div class="small">${a.created_at}</div>
    </div>
  `).join('');
}

async function refreshStats() {
  const data = await fetchJson('/api/status');
  renderStats(data);
}

async function refreshRoutes() {
  const data = await fetchJson('/api/routes');
  routesCache = data.routes || [];
  renderRoutes();
}

async function refreshAlerts() {
  const data = await fetchJson('/api/alerts');
  alertsCache = data.alerts || [];
  renderAlerts();
}

async function refreshAll() {
  await Promise.all([refreshStats(), refreshRoutes(), refreshAlerts()]);
}

async function createBooking() {
  const payload = {
    passenger_name: document.getElementById('passengerName').value.trim(),
    route_id: parseInt(document.getElementById('routeId').value),
    seats: parseInt(document.getElementById('seats').value || '1'),
    booking_status: document.getElementById('bookingType').value
  };
  const msg = document.getElementById('bookingMsg');
  msg.textContent = '';
  try {
    const data = await fetchJson('/api/bookings', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(payload)
    });
    msg.textContent = data.message;
    document.getElementById('passengerName').value = '';
    document.getElementById('routeId').value = '';
    document.getElementById('seats').value = '1';
    await refreshAll();
  } catch (e) {
    msg.textContent = e.message;
  }
}

async function addAlert() {
  const payload = {
    level: document.getElementById('alertLevel').value,
    message: document.getElementById('alertMessage').value.trim()
  };
  const msg = document.getElementById('alertMsg');
  msg.textContent = '';
  try {
    const data = await fetchJson('/api/alerts', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(payload)
    });
    msg.textContent = data.message;
    document.getElementById('alertMessage').value = '';
    await refreshAll();
  } catch (e) {
    msg.textContent = e.message;
  }
}

window.refreshAll = refreshAll;
window.createBooking = createBooking;
window.addAlert = addAlert;

refreshAll();
setInterval(refreshAll, 5000);
