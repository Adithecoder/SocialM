//
//  register.js
//  SocialM
//
//  Created by Czeglédi Ádi on 9/27/25.
//

const bcrypt = require("bcrypt");
const mysql = require('mysql2/promise');

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'socialm'
};

app.post("/register", async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Ellenőrizzük, hogy létezik-e már a felhasználó
    const [existing] = await connection.execute(
      'SELECT id FROM users WHERE username = ?',
      [username]
    );

    if (existing.length > 0) {
      await connection.end();
      return res.status(400).json({ message: "Felhasználó már létezik" });
    }

    const hashedPw = await bcrypt.hash(password, 10);
    
    // Új felhasználó beszúrása
    await connection.execute(
      'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
      [username, hashedPw, email || "Nincs megadva"]
    );

    // Tevékenység naplózása
    await connection.execute(
      'INSERT INTO activities (type, username) VALUES (?, ?)',
      ["Regisztráció", username]
    );

    await connection.end();

    res.json({ message: "Sikeres regisztráció" });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});
