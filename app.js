// app.js - Valós idejű frissítéssel
require('dotenv').config();
const mongoose = require("mongoose");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcrypt");


const jwt = require("jsonwebtoken");

const app = express();
const PORT = process.env.PORT || 3000;

// CORS middleware
app.use(cors({
  origin: ["http://localhost:3000", "http://192.168.0.162:3000", "http://127.0.0.1:3000", "http://localhost:3001"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

// Middleware
app.use(bodyParser.json());

// Memória adattárolás
let users = [];
let nextUserId = 1;
let lastActivity = {
  type: "Szerver indítva",
  username: "Rendszer",
  timestamp: new Date().toLocaleString("hu-HU")
};

console.log("🔧 MEMÓRIA ADATBÁZIS - MongoDB jelszó beállításáig");

// Regisztrációs végpont
app.post("/register", async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const existing = users.find(user => user.username === username);
    if (existing) {
      return res.status(400).json({ message: "Felhasználó már létezik" });
    }

    const hashedPw = await bcrypt.hash(password, 10);
    const newUser = {
      id: nextUserId++,
      username,
      password: hashedPw,
      email: email || "Nincs megadva",
      createdAt: new Date().toLocaleString("hu-HU"),
      lastLogin: null
    };
    users.push(newUser);

    // Tevékenység naplózása
    lastActivity = {
      type: "Regisztráció",
      username: username,
      timestamp: new Date().toLocaleString("hu-HU")
    };

    console.log(`✅ Új felhasználó regisztrálva: ${username}`);
    res.json({ message: "Sikeres regisztráció" });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// Bejelentkezési végpont
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  try {
    const user = users.find(u => u.username === username);
    if (!user) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const token = jwt.sign({ id: user.id }, process.env.SECRET || "titkoskulcs", { expiresIn: "1h" });

    // Frissítjük a bejelentkezési időt
    user.lastLogin = new Date().toLocaleString("hu-HU");

    // Tevékenység naplózása
    lastActivity = {
      type: "Bejelentkezés",
      username: username,
      timestamp: new Date().toLocaleString("hu-HU")
    };

    console.log(`🔐 Bejelentkezés: ${username}`);
    res.json({
      message: "Bejelentkezés sikeres!",
      token: token,
      username: user.username
    });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// CSS stílus
const styles = `
<style>
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    margin: 0;
    padding: 20px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
  }
  .container {
    max-width: 1200px;
    margin: 0 auto;
    background: white;
    border-radius: 15px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    overflow: hidden;
  }
  .header {
    background: linear-gradient(135deg, #2c3e50, #3498db);
    color: white;
    padding: 30px;
    text-align: center;
  }
  .header h1 {
    margin: 0;
    font-size: 2.5em;
  }
  .stats {
    display: flex;
    justify-content: space-around;
    background: #34495e;
    color: white;
    padding: 15px;
  }
  .stat-box {
    text-align: center;
  }
  .stat-number {
    font-size: 2em;
    font-weight: bold;
    color: #3498db;
  }
  .content {
    padding: 30px;
  }
  .users-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  }
  .users-table th {
    background: #3498db;
    color: white;
    padding: 15px;
    text-align: left;
    font-weight: 600;
  }
  .users-table td {
    padding: 12px 15px;
    border-bottom: 1px solid #ecf0f1;
  }
  .users-table tr:hover {
    background: #f8f9fa;
  }
  .users-table tr:nth-child(even) {
    background: #f8f9fa;
  }
  .no-data {
    text-align: center;
    padding: 40px;
    color: #7f8c8d;
    font-style: italic;
  }
  .nav {
    display: flex;
    gap: 10px;
    margin-bottom: 20px;
  }
  .nav a {
    padding: 10px 20px;
    background: #3498db;
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: background 0.3s;
  }
  .nav a:hover {
    background: #2980b9;
  }
  .status-badge {
    display: inline-block;
    padding: 5px 10px;
    border-radius: 20px;
    font-size: 0.8em;
    font-weight: bold;
  }
  .status-online {
    background: #2ecc71;
    color: white;
  }
  .status-offline {
    background: #e74c3c;
    color: white;
  }
  .activity-panel {
    background: #f8f9fa;
    padding: 15px;
    border-radius: 10px;
    margin-bottom: 20px;
    border-left: 4px solid #3498db;
  }
  .refresh-info {
    background: #d4edda;
    padding: 10px;
    border-radius: 5px;
    margin-bottom: 15px;
    border-left: 4px solid #28a745;
  }
  .auto-refresh {
    background: #fff3cd;
    padding: 10px;
    border-radius: 5px;
    margin-bottom: 15px;
    border-left: 4px solid #ffc107;
  }
</style>

<script>
// Auto-refresh funkció
let autoRefreshEnabled = true;
let refreshInterval;

function startAutoRefresh() {
  refreshInterval = setInterval(() => {
    if (autoRefreshEnabled) {
      console.log('🔄 Automatikus frissítés...');
      location.reload();
    }
  }, 3000); // 3 másodpercenként
}

function toggleAutoRefresh() {
  autoRefreshEnabled = !autoRefreshEnabled;
  const button = document.getElementById('refreshToggle');
  const status = document.getElementById('refreshStatus');
  
  if (autoRefreshEnabled) {
    button.textContent = '⏸️ Auto Frissítés Kikapcsolása';
    button.style.background = '#dc3545';
    status.textContent = 'BE';
    status.className = 'status-badge status-online';
    startAutoRefresh();
  } else {
    button.textContent = '▶️ Auto Frissítés Bekapcsolása';
    button.style.background = '#28a745';
    status.textContent = 'KI';
    status.className = 'status-badge status-offline';
    clearInterval(refreshInterval);
  }
}

// Oldal betöltésekor indul az auto-refresh
document.addEventListener('DOMContentLoaded', function() {
  startAutoRefresh();
  
  // Frissítés gomb
  document.getElementById('manualRefresh').addEventListener('click', function() {
    location.reload();
  });
});
</script>
`;

// Főoldal - valós idejű frissítéssel
app.get("/", (req, res) => {
  const html = `
  <!DOCTYPE html>
  <html lang="hu">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SocialM Admin - Valós Idejű</title>
    ${styles}
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>🚀 SocialM Szerver</h1>
        <p>Valós idejű adminisztrációs felület</p>
      </div>
      
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">${users.length}</div>
          <div>Regisztrált felhasználó</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">🔄</div>
          <div>Auto Frissítés: <span id="refreshStatus" class="status-badge status-online">BE</span></div>
        </div>
        <div class="stat-box">
          <div class="stat-number">💾</div>
          <div>Memória adatbázis</div>
        </div>
      </div>
      
      <div class="content">
        <div class="nav">
          <a href="/">Főoldal</a>
          <a href="/admin/users">JSON adatok</a>
          <a href="/status">Részletes állapot</a>
          <button id="manualRefresh" style="padding: 10px 20px; background: #17a2b8; color: white; border: none; border-radius: 5px; cursor: pointer;">🔄 Kézi Frissítés</button>
          <button id="refreshToggle" onclick="toggleAutoRefresh()" style="padding: 10px 20px; background: #dc3545; color: white; border: none; border-radius: 5px; cursor: pointer;">⏸️ Auto Frissítés Kikapcsolása</button>
        </div>
        
        <div class="auto-refresh">
          <strong>🔄 Automatikus frissítés aktív</strong> - Az oldal 3 másodpercenként frissül
        </div>
        
        <div class="activity-panel">
          <h3>📝 Utolsó tevékenység</h3>
          <p><strong>Típus:</strong> ${lastActivity.type}</p>
          <p><strong>Felhasználó:</strong> ${lastActivity.username}</p>
          <p><strong>Időpont:</strong> ${lastActivity.timestamp}</p>
        </div>
        
        <h2>📊 Regisztrált felhasználók</h2>
        
        ${users.length > 0 ? `
        <table class="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Felhasználónév</th>
              <th>E-mail</th>
              <th>Regisztráció dátuma</th>
              <th>Utolsó bejelentkezés</th>
              <th>Állapot</th>
            </tr>
          </thead>
          <tbody>
            ${users.map(user => `
              <tr>
                <td><strong>#${user.id}</strong></td>
                <td>${user.username}</td>
                <td>${user.email}</td>
                <td>${user.createdAt}</td>
                <td>${user.lastLogin || 'Még nem jelentkezett be'}</td>
                <td><span class="status-badge ${user.lastLogin ? 'status-online' : 'status-offline'}">${user.lastLogin ? 'Aktív' : 'Inaktív'}</span></td>
              </tr>
            `).join('')}
          </tbody>
        </table>
        ` : `
        <div class="no-data">
          <h3>🤷‍♂️ Még nincsenek regisztrált felhasználók</h3>
          <p>Az első felhasználó regisztrálása után itt fognak megjelenni az adatok.</p>
        </div>
        `}
        
        <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
          <h3>ℹ️ Valós idejű információk</h3>
          <p><strong>Auto frissítés:</strong> 3 másodpercenként</p>
          <p><strong>Utolsó frissítés:</strong> ${new Date().toLocaleString("hu-HU")}</p>
          <p><strong>Következő frissítés:</strong> <span id="nextRefresh">3 másodperc múlva</span></p>
        </div>
      </div>
    </div>
    
    <script>
      // Következő frissítés számláló
      let countdown = 3;
      function updateCountdown() {
        document.getElementById('nextRefresh').textContent = countdown + ' másodperc múlva';
        countdown--;
        if (countdown < 0) countdown = 3;
      }
      setInterval(updateCountdown, 1000);
      updateCountdown();
    </script>
  </body>
  </html>
  `;
  
  res.send(html);
});

// Felhasználók listázása JSON formátumban
app.get("/admin/users", (req, res) => {
  res.json({
    database: "Memória (MongoDB jelszó beállításáig)",
    totalUsers: users.length,
    lastActivity: lastActivity,
    users: users.map(u => ({
      id: u.id,
      username: u.username,
      email: u.email,
      createdAt: u.createdAt,
      lastLogin: u.lastLogin
    }))
  });
});

// Részletes állapot oldal
app.get("/status", (req, res) => {
  const html = `
  <!DOCTYPE html>
  <html lang="hu">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Szerver Állapot - SocialM</title>
    ${styles}
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>🔧 Szerver Állapot</h1>
        <p>Részletes technikai információk</p>
      </div>
      
      <div class="content">
        <div class="nav">
          <a href="/">Főoldal</a>
          <a href="/admin/users">JSON adatok</a>
          <a href="/status">Részletes állapot</a>
          <button onclick="location.reload()" style="padding: 10px 20px; background: #17a2b8; color: white; border: none; border-radius: 5px; cursor: pointer;">🔄 Frissítés</button>
        </div>
        
        <h2>📈 Statisztikák</h2>
        <table class="users-table">
          <tr>
            <td><strong>Regisztrált felhasználók</strong></td>
            <td>${users.length} fő</td>
          </tr>
          <tr>
            <td><strong>Aktív felhasználók</strong></td>
            <td>${users.filter(u => u.lastLogin).length} fő</td>
          </tr>
          <tr>
            <td><strong>Utolsó tevékenység</strong></td>
            <td>${lastActivity.type} - ${lastActivity.username}</td>
          </tr>
          <tr>
            <td><strong>Szerver port</strong></td>
            <td>${PORT}</td>
          </tr>
          <tr>
            <td><strong>Adatbázis típus</strong></td>
            <td>Memória (MongoDB jelszó beállításáig)</td>
          </tr>
          <tr>
            <td><strong>Utolsó frissítés</strong></td>
            <td>${new Date().toLocaleString("hu-HU")}</td>
          </tr>
        </table>
        
        <h2 style="margin-top: 30px;">🔔 MongoDB Beállítás</h2>
        <div style="background: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;">
          <p><strong>Jelenleg memória adatbázist használsz.</strong> Az adatok elvesznek a szerver újraindításakor.</p>
          <p>Állítsd be a MongoDB Atlas jelszót az adatok tartós tárolásához!</p>
        </div>
      </div>
    </div>
  </body>
  </html>
  `;
  
  res.send(html);
});

// Health check (JSON)
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    database: "memory",
    users: {
      total: users.length,
      active: users.filter(u => u.lastLogin).length
    },
    lastActivity: lastActivity,
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Szerver fut a http://localhost:${PORT} címen`);
  console.log(`📊 Valós idejű felület elérhető: http://localhost:${PORT}`);
  console.log(`🔄 Auto frissítés: 3 másodpercenként`);
  console.log(`👥 Regisztrált felhasználók: ${users.length}`);
});
