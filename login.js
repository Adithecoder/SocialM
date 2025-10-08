//
//  login.js
//  SocialM
//
//  Created by Czeglédi Ádi on 9/27/25.
//

const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const mysql = require('mysql2/promise');
const SECRET = process.env.SECRET || "titkoskulcs";

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'socialm'
};

app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Felhasználó keresése
    const [users] = await connection.execute(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (users.length === 0) {
      await connection.end();
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password);
    
    if (!isMatch) {
      await connection.end();
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const token = jwt.sign({ id: user.id }, SECRET, { expiresIn: "1h" });

    // Frissítjük a bejelentkezési időt
    await connection.execute(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );

    // Tevékenység naplózása
    await connection.execute(
      'INSERT INTO activities (type, username) VALUES (?, ?)',
      ["Bejelentkezés", username]
    );

    await connection.end();

    res.json({
      message: "Sikeres belépés",
      token,
      username: user.username
    });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});
