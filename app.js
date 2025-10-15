// app.js - JAVÍTOTT VERZIÓ
//require('dotenv').config();
//const express = require("express");
//const bodyParser = require("body-parser");
//const cors = require("cors");
//const bcrypt = require("bcrypt");
//const jwt = require("jsonwebtoken");
//const path = require('path');
//const { initializeDatabase, dbAll, dbRun, dbGet } = require('./database');
//
//const app = express();
//const PORT = process.env.PORT || 3000;
//
//// Middleware
//app.use(cors({
//  origin: "*",
//  credentials: true,
//  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
//  allowedHeaders: ["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"]
//}));
//app.options('*', cors());
//app.use(bodyParser.json({ limit: '50mb' }));
//app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));
//app.use(express.static(path.join(__dirname, 'public')));
//
//let lastActivity = {
//  type: "Szerver indítva",
//  username: "Rendszer",
//  timestamp: new Date().toLocaleString("hu-HU")
//};
//
//// ✅ REGISZTRÁCIÓ
//app.post("/register", async (req, res) => {
//  const { username, password, email } = req.body;
//
//  if (!username || !password) {
//    return res.status(400).json({ message: "Hiányzó adatok" });
//  }
//
//  try {
//    const existing = await dbGet('SELECT id FROM users WHERE username = ?', [username]);
//
//    if (existing) {
//      return res.status(400).json({ message: "Felhasználó már létezik" });
//    }
//
//    const hashedPw = await bcrypt.hash(password, 10);
//
//    const result = await dbRun(
//      'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
//      [username, hashedPw, email || 'Nincs megadva']
//    );
//
//    lastActivity = {
//      type: "Regisztráció",
//      username: username,
//      timestamp: new Date().toLocaleString("hu-HU")
//    };
//
//    console.log(`✅ Új felhasználó regisztrálva: ${username}`);
//    res.json({ message: "Sikeres regisztráció" });
//  } catch (err) {
//    console.error('Regisztrációs hiba:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ BEJELENTKEZÉS
//app.post("/login", async (req, res) => {
//  const { username, password } = req.body;
//
//  try {
//    const user = await dbGet('SELECT * FROM users WHERE username = ?', [username]);
//
//    if (!user) {
//      return res.status(401).json({ message: "Hibás belépési adatok" });
//    }
//
//    const isMatch = await bcrypt.compare(password, user.password);
//
//    if (!isMatch) {
//      return res.status(401).json({ message: "Hibás belépési adatok" });
//    }
//
//    const token = jwt.sign({ id: user.id }, process.env.SECRET || "titkoskulcs", { expiresIn: "24h" });
//
//    await dbRun('UPDATE users SET last_login = datetime("now") WHERE id = ?', [user.id]);
//
//    lastActivity = {
//      type: "Bejelentkezés",
//      username: username,
//      timestamp: new Date().toLocaleString("hu-HU")
//    };
//
//    console.log(`🔐 Bejelentkezés: ${username}`);
//    res.json({
//      message: "Bejelentkezés sikeres!",
//      token: token,
//      username: user.username,
//      user_id: user.id
//    });
//  } catch (err) {
//    console.error('Bejelentkezési hiba:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ BEJEGYZÉS LÉTREHOZÁSA
//app.post("/posts", async (req, res) => {
//  const { user_id, content, image_url, video_url } = req.body;
//
//  if (!user_id) {
//    return res.status(400).json({ message: "Hiányzó user_id" });
//  }
//
//  try {
//    const result = await dbRun(
//      'INSERT INTO posts (user_id, content, image_url, video_url) VALUES (?, ?, ?, ?)',
//      [user_id, content || '', image_url || '', video_url || '']
//    );
//
//    lastActivity = {
//      type: "Bejegyzés létrehozva",
//      username: "Felhasználó",
//      timestamp: new Date().toLocaleString("hu-HU")
//    };
//
//    res.json({
//      message: "Bejegyzés létrehozva",
//      post_id: result.id
//    });
//  } catch (err) {
//    console.error('Hiba a bejegyzés létrehozásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ BEJEGYZÉSEK LEKÉRÉSE
//app.get("/posts", async (req, res) => {
//  try {
//    const posts = await dbAll(`
//      SELECT p.*, u.username
//      FROM posts p
//      LEFT JOIN users u ON p.user_id = u.id
//      ORDER BY p.created_at DESC
//    `);
//
//    // Kommentek és like információk lekérése
//    for (let post of posts) {
//      const comments = await dbAll(`
//        SELECT c.*, u.username
//        FROM comments c
//        LEFT JOIN users u ON c.user_id = u.id
//        WHERE c.post_id = ?
//        ORDER BY c.created_at ASC
//      `, [post.id]);
//      post.comments = comments;
//
//      // Like információk
//      const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [post.id]);
//      post.likes = likeCount.count;
//    }
//
//    res.json(posts);
//  } catch (err) {
//    console.error('Hiba a bejegyzések lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ KOMMENT HOZZÁADÁSA
//app.post("/posts/:id/comments", async (req, res) => {
//  const postId = req.params.id;
//  const { user_id, content } = req.body;
//
//  if (!user_id || !content) {
//    return res.status(400).json({ message: "Hiányzó adatok" });
//  }
//
//  try {
//    const result = await dbRun(
//      'INSERT INTO comments (post_id, user_id, content) VALUES (?, ?, ?)',
//      [postId, user_id, content]
//    );
//
//    res.json({
//      message: "Komment hozzáadva",
//      comment_id: result.id
//    });
//  } catch (err) {
//    console.error('Hiba a komment hozzáadásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ LIKE/UNLIKE
//app.post("/posts/:id/like", async (req, res) => {
//  const postId = req.params.id;
//  const { user_id } = req.body;
//
//  if (!user_id) {
//    return res.status(400).json({ message: "Hiányzó user_id" });
//  }
//
//  try {
//    // Ellenőrizzük, hogy likeolta-e már
//    const existingLike = await dbGet(
//      'SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?',
//      [postId, user_id]
//    );
//
//    if (existingLike) {
//      // Ha már likeolta, akkor unlike
//      await dbRun('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, user_id]);
//
//      const updatedPost = await dbGet('SELECT COUNT(*) as likes FROM post_likes WHERE post_id = ?', [postId]);
//
//      res.json({
//        message: "Like eltávolítva",
//        liked: false,
//        likes: updatedPost.likes
//      });
//    } else {
//      // Ha még nem likeolta, akkor like
//      await dbRun('INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)', [postId, user_id]);
//
//      const updatedPost = await dbGet('SELECT COUNT(*) as likes FROM post_likes WHERE post_id = ?', [postId]);
//
//      res.json({
//        message: "Like hozzáadva",
//        liked: true,
//        likes: updatedPost.likes
//      });
//    }
//  } catch (err) {
//    console.error('Hiba a like műveletnél:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ LIKE STÁTUSZ LEKÉRÉSE
//app.get("/posts/:id/like-status", async (req, res) => {
//  const postId = req.params.id;
//  const user_id = req.query.user_id;
//
//  if (!user_id) {
//    return res.status(400).json({ message: "Hiányzó user_id" });
//  }
//
//  try {
//    const like = await dbGet(
//      'SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?',
//      [postId, user_id]
//    );
//
//    const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [postId]);
//
//    res.json({
//      liked: !!like,
//      likes: likeCount.count
//    });
//  } catch (err) {
//    console.error('Hiba a like státusz lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ FELHASZNÁLÓ ADATAI
//app.get("/users/:id", async (req, res) => {
//  const userId = req.params.id;
//
//  try {
//    const user = await dbGet(
//      'SELECT id, username, email, created_at, last_login FROM users WHERE id = ?',
//      [userId]
//    );
//
//    if (!user) {
//      return res.status(404).json({ message: "Felhasználó nem található" });
//    }
//
//    res.json(user);
//  } catch (err) {
//    console.error('Hiba a felhasználó lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ FELHASZNÁLÓ KERESÉS - JAVÍTOTT VERZIÓ
//app.get("/users/search", async (req, res) => {
//  const { query } = req.query;
//
//  console.log(`🎯 KERESÉS: "${query}"`);
//
//  if (!query || query.trim().length === 0) {
//    return res.json([]);
//  }
//
//  const searchQuery = `%${query.trim()}%`;
//
//  try {
//    // Először debugoljuk, hogy mit keresünk pontosan
//    console.log(`🔍 Keresési paraméter: ${searchQuery}`);
//
//    // Ellenőrizzük, hogy vannak-e egyáltalán felhasználók
//    const allUsers = await dbAll('SELECT id, username, email FROM users');
//    console.log(`📊 Összes felhasználó az adatbázisban:`, allUsers);
//
//    // Most a keresés - SQLite-ban máshogy kell a LIKE
//    const users = await dbAll(
//      `SELECT id, username, email, created_at, last_login
//       FROM users
//       WHERE username LIKE ? OR email LIKE ?
//       ORDER BY username
//       LIMIT 20`,
//      [searchQuery, searchQuery]
//    );
//
//    console.log(`✅ Találatok: ${users.length} felhasználó`);
//
//    if (users.length === 0) {
//      // Ha nincs találat, üres array-t küldünk, nem hibaüzenetet
//      return res.json([]);
//    }
//
//    res.json(users);
//  } catch (err) {
//    console.error('❌ Keresési hiba:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ DEBUG - ÖSSZES FELHASZNÁLÓ
//app.get("/debug/all-users", async (req, res) => {
//  try {
//    const users = await dbAll('SELECT id, username, email FROM users ORDER BY username');
//    console.log('📊 Összes felhasználó:', users);
//    res.json({
//      total: users.length,
//      users: users
//    });
//  } catch (err) {
//    console.error('Hiba a felhasználók lekérésekor:', err);
//    res.status(500).json({ error: err.message });
//  }
//});
//
//// ✅ MENTÉS/VISSZAVONÁS
//app.post("/posts/:id/save", async (req, res) => {
//  const postId = req.params.id;
//  const { user_id } = req.body;
//
//  if (!user_id) {
//    return res.status(400).json({ message: "Hiányzó user_id" });
//  }
//
//  try {
//    const existingSave = await dbGet(
//      'SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?',
//      [postId, user_id]
//    );
//
//    if (existingSave) {
//      await dbRun('DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?', [postId, user_id]);
//      res.json({ saved: false, message: "Mentés visszavonva" });
//    } else {
//      await dbRun('INSERT INTO saved_posts (post_id, user_id) VALUES (?, ?)', [postId, user_id]);
//      res.json({ saved: true, message: "Poszt mentve" });
//    }
//  } catch (err) {
//    console.error('Hiba a mentés váltásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ MENTETT POSZTOK
//app.get("/users/:id/saved-posts", async (req, res) => {
//  const userId = req.params.id;
//
//  try {
//    const savedPosts = await dbAll(`
//      SELECT p.*, u.username, sp.saved_at
//      FROM saved_posts sp
//      JOIN posts p ON sp.post_id = p.id
//      LEFT JOIN users u ON p.user_id = u.id
//      WHERE sp.user_id = ?
//      ORDER BY sp.saved_at DESC
//    `, [userId]);
//
//    // Kommentek lekérése
//    for (let post of savedPosts) {
//      const comments = await dbAll(`
//        SELECT c.*, u.username
//        FROM comments c
//        LEFT JOIN users u ON c.user_id = u.id
//        WHERE c.post_id = ?
//        ORDER BY c.created_at ASC
//      `, [post.id]);
//      post.comments = comments;
//
//      // Like információk
//      const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [post.id]);
//      post.likes = likeCount.count;
//    }
//
//    res.json(savedPosts);
//  } catch (err) {
//    console.error('Hiba a mentett posztok lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ MENTÉSI STÁTUSZ
//app.get("/posts/:id/save-status", async (req, res) => {
//  const postId = req.params.id;
//  const user_id = req.query.user_id;
//
//  if (!user_id) {
//    return res.status(400).json({ message: "Hiányzó user_id" });
//  }
//
//  try {
//    const save = await dbGet(
//      'SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?',
//      [postId, user_id]
//    );
//
//    res.json({ saved: !!save });
//  } catch (err) {
//    console.error('Hiba a mentési státusz lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ CHAT SZOBA LÉTREHOZÁSA
//app.post("/chat/rooms", async (req, res) => {
//  const { user1_id, user2_id } = req.body;
//
//  if (!user1_id || !user2_id) {
//    return res.status(400).json({ message: "Hiányzó user_id-k" });
//  }
//
//  try {
//    let room = await dbGet(
//      `SELECT * FROM chat_rooms
//       WHERE (user1_id = ? AND user2_id = ?)
//       OR (user1_id = ? AND user2_id = ?)`,
//      [user1_id, user2_id, user2_id, user1_id]
//    );
//
//    if (!room) {
//      const [minId, maxId] = [user1_id, user2_id].sort((a, b) => a - b);
//      const result = await dbRun(
//        'INSERT INTO chat_rooms (user1_id, user2_id) VALUES (?, ?)',
//        [minId, maxId]
//      );
//      room = await dbGet('SELECT * FROM chat_rooms WHERE id = ?', [result.id]);
//    }
//
//    res.json(room);
//  } catch (err) {
//    console.error('Hiba a chat szoba létrehozásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ ÜZENET KÜLDÉSE
//app.post("/chat/messages", async (req, res) => {
//  const { room_id, sender_id, message } = req.body;
//
//  if (!room_id || !sender_id || !message) {
//    return res.status(400).json({ message: "Hiányzó adatok" });
//  }
//
//  try {
//    const result = await dbRun(
//      'INSERT INTO messages (room_id, sender_id, message) VALUES (?, ?, ?)',
//      [room_id, sender_id, message]
//    );
//
//    await dbRun(
//      'UPDATE chat_rooms SET last_message_at = CURRENT_TIMESTAMP WHERE id = ?',
//      [room_id]
//    );
//
//    const newMessage = await dbGet(
//      `SELECT m.*, u.username as sender_username
//       FROM messages m
//       LEFT JOIN users u ON m.sender_id = u.id
//       WHERE m.id = ?`,
//      [result.id]
//    );
//
//    res.json(newMessage);
//  } catch (err) {
//    console.error('Hiba az üzenet küldésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ ÜZENETEK LEKÉRÉSE
//app.get("/chat/rooms/:roomId/messages", async (req, res) => {
//  const roomId = req.params.roomId;
//
//  try {
//    const messages = await dbAll(
//      `SELECT m.*, u.username as sender_username
//       FROM messages m
//       LEFT JOIN users u ON m.sender_id = u.id
//       WHERE m.room_id = ?
//       ORDER BY m.created_at ASC`,
//      [roomId]
//    );
//
//    res.json(messages);
//  } catch (err) {
//    console.error('Hiba az üzenetek lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ CHAT SZOBÁK LEKÉRÉSE
//app.get("/users/:userId/chat-rooms", async (req, res) => {
//  const userId = req.params.userId;
//
//  try {
//    const rooms = await dbAll(
//      `SELECT cr.*,
//              u1.username as user1_username,
//              u2.username as user2_username,
//              (SELECT message FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message,
//              (SELECT created_at FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_time
//       FROM chat_rooms cr
//       LEFT JOIN users u1 ON cr.user1_id = u1.id
//       LEFT JOIN users u2 ON cr.user2_id = u2.id
//       WHERE cr.user1_id = ? OR cr.user2_id = ?
//       ORDER BY cr.last_message_at DESC`,
//      [userId, userId]
//    );
//
//    res.json(rooms);
//  } catch (err) {
//    console.error('Hiba a chat szobák lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ OLVASATLAN ÜZENETEK
//app.get("/users/:userId/unread-messages", async (req, res) => {
//  const userId = req.params.userId;
//
//  try {
//    const unreadCount = await dbGet(
//      `SELECT COUNT(*) as count
//       FROM messages m
//       JOIN chat_rooms cr ON m.room_id = cr.id
//       WHERE m.is_read = 0
//       AND m.sender_id != ?
//       AND (cr.user1_id = ? OR cr.user2_id = ?)`,
//      [userId, userId, userId]
//    );
//
//    res.json({ unread_count: unreadCount.count });
//  } catch (err) {
//    console.error('Hiba az olvasatlan üzenetek lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ ÜZENETEK OLVASOTTNAK JELÖLÉSE
//app.post("/chat/rooms/:roomId/mark-read", async (req, res) => {
//  const roomId = req.params.roomId;
//  const { user_id } = req.body;
//
//  try {
//    await dbRun(
//      `UPDATE messages
//       SET is_read = 1
//       WHERE room_id = ? AND sender_id != ? AND is_read = 0`,
//      [roomId, user_id]
//    );
//
//    res.json({ message: "Üzenetek olvasottnak jelölve" });
//  } catch (err) {
//    console.error('Hiba az üzenetek olvasottnak jelölésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//
//// ✅ SZAVAZÁS LÉTREHOZÁSA
//app.post("/posts/:id/poll", async (req, res) => {
//  const postId = req.params.id;
//  const { user_id, question, options } = req.body;
//
//  if (!user_id || !question || !options || options.length < 2) {
//    return res.status(400).json({
//      message: "Hiányzó adatok: kérdés és legalább 2 opció szükséges"
//    });
//  }
//
//  try {
//    // Szavazás létrehozása
//    const result = await dbRun(
//      'INSERT INTO polls (post_id, user_id, question) VALUES (?, ?, ?)',
//      [postId, user_id, question]
//    );
//
//    const pollId = result.id;
//
//    // Opciók hozzáadása
//    for (let option of options) {
//      await dbRun(
//        'INSERT INTO poll_options (poll_id, option_text) VALUES (?, ?)',
//        [pollId, option.text]
//      );
//    }
//
//    res.json({
//      message: "Szavazás létrehozva",
//      poll_id: pollId
//    });
//  } catch (err) {
//    console.error('Hiba a szavazás létrehozásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ SZAVAZÁS LEADÁSA
//app.post("/polls/:id/vote", async (req, res) => {
//  const pollId = req.params.id;
//  const { user_id, option_id } = req.body;
//
//  if (!user_id || !option_id) {
//    return res.status(400).json({ message: "Hiányzó adatok" });
//  }
//
//  try {
//    // Ellenőrizzük, hogy szavazott-e már
//    const existingVote = await dbGet(
//      'SELECT id FROM poll_votes WHERE poll_id = ? AND user_id = ?',
//      [pollId, user_id]
//    );
//
//    if (existingVote) {
//      return res.status(400).json({ message: "Már szavaztál erre a szavazásra" });
//    }
//
//    // Szavazat rögzítése
//    await dbRun(
//      'INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES (?, ?, ?)',
//      [pollId, option_id, user_id]
//    );
//
//    // Frissítjük az opció szavazatszámát
//    await dbRun(
//      'UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = ?',
//      [option_id]
//    );
//
//    res.json({ message: "Szavazat leadva" });
//  } catch (err) {
//    console.error('Hiba a szavazás leadásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ SZAVAZÁS ADATAI
//app.get("/polls/:id", async (req, res) => {
//  const pollId = req.params.id;
//  const user_id = req.query.user_id;
//
//  try {
//    // Szavazás alapadatok
//    const poll = await dbGet(`
//      SELECT p.*, u.username
//      FROM polls p
//      LEFT JOIN users u ON p.user_id = u.id
//      WHERE p.id = ?
//    `, [pollId]);
//
//    if (!poll) {
//      return res.status(404).json({ message: "Szavazás nem található" });
//    }
//
//    // Opciók lekérése
//    const options = await dbAll(`
//      SELECT po.*,
//             EXISTS(SELECT 1 FROM poll_votes pv WHERE pv.option_id = po.id AND pv.user_id = ?) as user_voted
//      FROM poll_options po
//      WHERE po.poll_id = ?
//    `, [user_id, pollId]);
//
//    // Összes szavazat számának kiszámítása
//    const totalVotes = options.reduce((sum, option) => sum + option.votes_count, 0);
//
//    // Százalékos arányok hozzáadása
//    const optionsWithPercent = options.map(option => ({
//      ...option,
//      percentage: totalVotes > 0 ? Math.round((option.votes_count / totalVotes) * 100) : 0
//    }));
//
//    res.json({
//      ...poll,
//      options: optionsWithPercent,
//      total_votes: totalVotes,
//      user_has_voted: options.some(option => option.user_voted)
//    });
//  } catch (err) {
//    console.error('Hiba a szavazás lekérésekor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//
//// ✅ EGYSZERŰ TESZT VÉGPONT
//app.get("/test", (req, res) => {
//  res.json({
//    status: "ok",
//    message: "Szerver működik!",
//    timestamp: new Date().toISOString()
//  });
//});
//
//// ✅ HEALTH CHECK
//app.get("/health", async (req, res) => {
//  try {
//    const users = await dbGet('SELECT COUNT(*) as total FROM users');
//    const posts = await dbGet('SELECT COUNT(*) as total FROM posts');
//    const comments = await dbGet('SELECT COUNT(*) as total FROM comments');
//
//    res.json({
//      status: "ok",
//      database: "sqlite",
//      stats: {
//        users: users.total,
//        posts: posts.total,
//        comments: comments.total
//      },
//      lastActivity: lastActivity,
//      timestamp: new Date().toISOString(),
//      uptime: process.uptime()
//    });
//  } catch (error) {
//    res.json({
//      status: "error",
//      database: "sqlite",
//      error: error.message,
//      timestamp: new Date().toISOString()
//    });
//  }
//});
//
//// ✅ DEBUG VÉGPONTOK
//app.get("/debug/users", async (req, res) => {
//  try {
//    const users = await dbAll('SELECT id, username, email FROM users');
//    console.log('📊 Összes felhasználó:', users);
//    res.json({
//      total: users.length,
//      users: users
//    });
//  } catch (err) {
//    console.error('Hiba a felhasználók lekérésekor:', err);
//    res.status(500).json({ error: err.message });
//  }
//});
//
//app.post("/debug/create-test-user", async (req, res) => {
//  try {
//    const hashedPw = await bcrypt.hash("test123", 10);
//
//    const result = await dbRun(
//      'INSERT OR IGNORE INTO users (username, password, email) VALUES (?, ?, ?)',
//      ["adam", hashedPw, "adam@test.com"]
//    );
//
//    const users = await dbAll('SELECT * FROM users WHERE username = "adam"');
//
//    res.json({
//      message: "Teszt felhasználó létrehozva",
//      userId: result.id,
//      users: users
//    });
//  } catch (err) {
//    console.error('Hiba a teszt felhasználó létrehozásakor:', err);
//    res.status(500).json({ message: "Szerver hiba", error: err.message });
//  }
//});
//
//// ✅ FŐOLDAL
//app.get("/", async (req, res) => {
//  try {
//    const usersCount = await dbGet('SELECT COUNT(*) as count FROM users');
//    const users = await dbAll('SELECT username, email, created_at, last_login FROM users ORDER BY created_at DESC');
//
//    const html = `
//    <!DOCTYPE html>
//    <html lang="hu">
//    <head>
//      <meta charset="UTF-8">
//      <meta name="viewport" content="width=device-width, initial-scale=1.0">
//      <title>SocialM Szerver - JAVÍTOTT</title>
//      <style>
//        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
//        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
//        .header { text-align: center; margin-bottom: 30px; }
//        .stats { display: flex; justify-content: space-around; margin-bottom: 30px; }
//        .stat-box { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 8px; }
//        .users-table { width: 100%; border-collapse: collapse; }
//        .users-table th, .users-table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
//        .users-table th { background: #f8f9fa; }
//        .status-online { color: green; font-weight: bold; }
//        .status-offline { color: gray; }
//        .api-info { background: #e9ecef; padding: 15px; border-radius: 8px; margin: 20px 0; }
//        .success { color: green; font-weight: bold; }
//      </style>
//    </head>
//    <body>
//      <div class="container">
//        <div class="header">
//          <h1>🚀 SocialM Szerver - <span class="success">JAVÍTOTT VERZIÓ</span></h1>
//          <p>SQLite adatbázissal - Like/Unlike működik!</p>
//        </div>
//
//        <div class="stats">
//          <div class="stat-box">
//            <div style="font-size: 2em; font-weight: bold;">${usersCount.count}</div>
//            <div>Regisztrált felhasználó</div>
//          </div>
//          <div class="stat-box">
//            <div style="font-size: 2em;">✅</div>
//            <div>Like/Unlike működik</div>
//          </div>
//          <div class="stat-box">
//            <div style="font-size: 2em;">🟢</div>
//            <div>Szerver aktív</div>
//          </div>
//        </div>
//
//        <div class="api-info">
//          <h3>📡 Elérhető API végpontok:</h3>
//          <ul>
//            <li><strong>POST /register</strong> - Regisztráció ✅</li>
//            <li><strong>POST /login</strong> - Bejelentkezés ✅</li>
//            <li><strong>POST /posts</strong> - Új bejegyzés ✅</li>
//            <li><strong>GET /posts</strong> - Bejegyzések listázása ✅</li>
//            <li><strong>POST /posts/:id/like</strong> - Like/Unlike ✅</li>
//            <li><strong>GET /posts/:id/like-status</strong> - Like státusz ✅</li>
//            <li><strong>POST /posts/:id/comments</strong> - Komment hozzáadása ✅</li>
//            <li><strong>POST /posts/:id/save</strong> - Mentés ✅</li>
//          </ul>
//        </div>
//
//        <h2>📊 Regisztrált felhasználók</h2>
//
//        ${users.length > 0 ? `
//        <table class="users-table">
//          <thead>
//            <tr>
//              <th>Felhasználónév</th>
//              <th>E-mail</th>
//              <th>Regisztráció dátuma</th>
//              <th>Utolsó bejelentkezés</th>
//              <th>Állapot</th>
//            </tr>
//          </thead>
//          <tbody>
//            ${users.map(user => `
//              <tr>
//                <td><strong>${user.username}</strong></td>
//                <td>${user.email || 'Nincs megadva'}</td>
//                <td>${new Date(user.created_at).toLocaleString("hu-HU")}</td>
//                <td>${user.last_login ? new Date(user.last_login).toLocaleString("hu-HU") : 'Még nem jelentkezett be'}</td>
//                <td><span class="${user.last_login ? 'status-online' : 'status-offline'}">${user.last_login ? 'Aktív' : 'Inaktív'}</span></td>
//              </tr>
//            `).join('')}
//          </tbody>
//        </table>
//        ` : `
//        <div style="text-align: center; padding: 40px;">
//          <h3>🤷‍♂️ Még nincsenek regisztrált felhasználók</h3>
//          <p>Az első felhasználó regisztrálása után itt fognak megjelenni az adatok.</p>
//        </div>
//        `}
//
//        <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
//          <h3>ℹ️ Szerver információk</h3>
//          <p><strong>Adatbázis:</strong> SQLite (Lokális fájl)</p>
//          <p><strong>Port:</strong> ${PORT}</p>
//          <p><strong>Utolsó frissítés:</strong> ${new Date().toLocaleString("hu-HU")}</p>
//          <p><strong>Státusz:</strong> <span class="success">Minden funkció működik!</span></p>
//        </div>
//      </div>
//    </body>
//    </html>
//    `;
//
//    res.send(html);
//  } catch (error) {
//    console.error('Hiba a főoldal betöltésekor:', error);
//    res.status(500).send('Hiba a szerveren');
//  }
//});
//
//// Szerver indítás
//initializeDatabase().then(() => {
//  app.listen(PORT, '0.0.0.0', () => {
//    console.log(`🚀 SocialM szerver fut: http://localhost:${PORT}`);
//    console.log(`🗃️ Adatbázis: SQLite (socialm.db)`);
//    console.log(`✅ Like/Unlike rendszer működik!`);
//    console.log(`📡 API végpontok elérhetőek!`);
//  });
//}).catch(error => {
//  console.error('❌ Hiba az adatbázis inicializálásakor:', error);
//});
//
//
//
// app.js - JAVÍTOTT VERZIÓ
require('dotenv').config();
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const path = require('path');
const { initializeDatabase, dbAll, dbRun, dbGet } = require('./database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: "*",
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"]
}));
app.options('*', cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

let lastActivity = {
  type: "Szerver indítva",
  username: "Rendszer",
  timestamp: new Date().toLocaleString("hu-HU")
};

// ✅ REGISZTRÁCIÓ
app.post("/register", async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const existing = await dbGet('SELECT id FROM users WHERE username = ?', [username]);

    if (existing) {
      return res.status(400).json({ message: "Felhasználó már létezik" });
    }

    const hashedPw = await bcrypt.hash(password, 10);
    
    const result = await dbRun(
      'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
      [username, hashedPw, email || 'Nincs megadva']
    );

    lastActivity = {
      type: "Regisztráció",
      username: username,
      timestamp: new Date().toLocaleString("hu-HU")
    };

    console.log(`✅ Új felhasználó regisztrálva: ${username}`);
    res.json({ message: "Sikeres regisztráció" });
  } catch (err) {
    console.error('Regisztrációs hiba:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ BEJELENTKEZÉS
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  try {
    const user = await dbGet('SELECT * FROM users WHERE username = ?', [username]);

    if (!user) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    
    if (!isMatch) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const token = jwt.sign({ id: user.id }, process.env.SECRET || "titkoskulcs", { expiresIn: "24h" });

    await dbRun('UPDATE users SET last_login = datetime("now") WHERE id = ?', [user.id]);

    lastActivity = {
      type: "Bejelentkezés",
      username: username,
      timestamp: new Date().toLocaleString("hu-HU")
    };

    console.log(`🔐 Bejelentkezés: ${username}`);
    res.json({
      message: "Bejelentkezés sikeres!",
      token: token,
      username: user.username,
      user_id: user.id
    });
  } catch (err) {
    console.error('Bejelentkezési hiba:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ BEJEGYZÉS LÉTREHOZÁSA
app.post("/posts", async (req, res) => {
  const { user_id, content, image_url, video_url } = req.body;
  
  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    const result = await dbRun(
      'INSERT INTO posts (user_id, content, image_url, video_url) VALUES (?, ?, ?, ?)',
      [user_id, content || '', image_url || '', video_url || '']
    );

    lastActivity = {
      type: "Bejegyzés létrehozva",
      username: "Felhasználó",
      timestamp: new Date().toLocaleString("hu-HU")
    };

    res.json({
      message: "Bejegyzés létrehozva",
      post_id: result.id
    });
  } catch (err) {
    console.error('Hiba a bejegyzés létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ BEJEGYZÉSEK LEKÉRÉSE
app.get("/posts", async (req, res) => {
  try {
    const posts = await dbAll(`
      SELECT p.*, u.username 
      FROM posts p 
      LEFT JOIN users u ON p.user_id = u.id 
      ORDER BY p.created_at DESC
    `);

    // Kommentek és like információk lekérése
    for (let post of posts) {
      const comments = await dbAll(`
        SELECT c.*, u.username 
        FROM comments c 
        LEFT JOIN users u ON c.user_id = u.id 
        WHERE c.post_id = ? 
        ORDER BY c.created_at ASC
      `, [post.id]);
      post.comments = comments;

      // Like információk
      const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [post.id]);
      post.likes = likeCount.count;

      // Poll információk
      const poll = await dbGet('SELECT * FROM polls WHERE post_id = ?', [post.id]);
      if (poll) {
        const pollOptions = await dbAll('SELECT * FROM poll_options WHERE poll_id = ?', [poll.id]);
        post.poll = {
          ...poll,
          options: pollOptions,
          total_votes: pollOptions.reduce((sum, opt) => sum + (opt.votes_count || 0), 0),
          user_has_voted: false
        };
      }
    }

    res.json(posts);
  } catch (err) {
    console.error('Hiba a bejegyzések lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ KOMMENT HOZZÁADÁSA
app.post("/posts/:id/comments", async (req, res) => {
  const postId = req.params.id;
  const { user_id, content } = req.body;

  if (!user_id || !content) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const result = await dbRun(
      'INSERT INTO comments (post_id, user_id, content) VALUES (?, ?, ?)',
      [postId, user_id, content]
    );

    res.json({
      message: "Komment hozzáadva",
      comment_id: result.id
    });
  } catch (err) {
    console.error('Hiba a komment hozzáadásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ LIKE/UNLIKE
app.post("/posts/:id/like", async (req, res) => {
  const postId = req.params.id;
  const { user_id } = req.body;

  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    // Ellenőrizzük, hogy likeolta-e már
    const existingLike = await dbGet(
      'SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?',
      [postId, user_id]
    );

    if (existingLike) {
      // Ha már likeolta, akkor unlike
      await dbRun('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, user_id]);
      
      const updatedPost = await dbGet('SELECT COUNT(*) as likes FROM post_likes WHERE post_id = ?', [postId]);
      
      res.json({
        message: "Like eltávolítva",
        liked: false,
        likes: updatedPost.likes
      });
    } else {
      // Ha még nem likeolta, akkor like
      await dbRun('INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)', [postId, user_id]);
      
      const updatedPost = await dbGet('SELECT COUNT(*) as likes FROM post_likes WHERE post_id = ?', [postId]);
      
      res.json({
        message: "Like hozzáadva",
        liked: true,
        likes: updatedPost.likes
      });
    }
  } catch (err) {
    console.error('Hiba a like műveletnél:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ LIKE STÁTUSZ LEKÉRÉSE
app.get("/posts/:id/like-status", async (req, res) => {
  const postId = req.params.id;
  const user_id = req.query.user_id;

  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    const like = await dbGet(
      'SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?',
      [postId, user_id]
    );

    const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [postId]);

    res.json({
      liked: !!like,
      likes: likeCount.count
    });
  } catch (err) {
    console.error('Hiba a like státusz lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ FELHASZNÁLÓ ADATAI
app.get("/users/:id", async (req, res) => {
  const userId = req.params.id;

  try {
    const user = await dbGet(
      'SELECT id, username, email, created_at, last_login FROM users WHERE id = ?',
      [userId]
    );

    if (!user) {
      return res.status(404).json({ message: "Felhasználó nem található" });
    }

    res.json(user);
  } catch (err) {
    console.error('Hiba a felhasználó lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ FELHASZNÁLÓ KERESÉS - JAVÍTOTT VERZIÓ
app.get("/users/search", async (req, res) => {
  const { query } = req.query;
  
  console.log(`🎯 KERESÉS: "${query}"`);
  
  if (!query || query.trim().length === 0) {
    return res.json([]);
  }

  const searchQuery = `%${query.trim()}%`;
  
  try {
    // Először debugoljuk, hogy mit keresünk pontosan
    console.log(`🔍 Keresési paraméter: ${searchQuery}`);
    
    // Ellenőrizzük, hogy vannak-e egyáltalán felhasználók
    const allUsers = await dbAll('SELECT id, username, email FROM users');
    console.log(`📊 Összes felhasználó az adatbázisban:`, allUsers);
    
    // Most a keresés - SQLite-ban máshogy kell a LIKE
    const users = await dbAll(
      `SELECT id, username, email, created_at, last_login 
       FROM users 
       WHERE username LIKE ? OR email LIKE ? 
       ORDER BY username 
       LIMIT 20`,
      [searchQuery, searchQuery]
    );
    
    console.log(`✅ Találatok: ${users.length} felhasználó`);
    
    if (users.length === 0) {
      // Ha nincs találat, üres array-t küldünk, nem hibaüzenetet
      return res.json([]);
    }
    
    res.json(users);
  } catch (err) {
    console.error('❌ Keresési hiba:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ DEBUG - ÖSSZES FELHASZNÁLÓ
app.get("/debug/all-users", async (req, res) => {
  try {
    const users = await dbAll('SELECT id, username, email FROM users ORDER BY username');
    console.log('📊 Összes felhasználó:', users);
    res.json({
      total: users.length,
      users: users
    });
  } catch (err) {
    console.error('Hiba a felhasználók lekérésekor:', err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ MENTÉS/VISSZAVONÁS
app.post("/posts/:id/save", async (req, res) => {
  const postId = req.params.id;
  const { user_id } = req.body;

  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    const existingSave = await dbGet(
      'SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?',
      [postId, user_id]
    );

    if (existingSave) {
      await dbRun('DELETE FROM saved_posts WHERE post_id = ? AND user_id = ?', [postId, user_id]);
      res.json({ saved: false, message: "Mentés visszavonva" });
    } else {
      await dbRun('INSERT INTO saved_posts (post_id, user_id) VALUES (?, ?)', [postId, user_id]);
      res.json({ saved: true, message: "Poszt mentve" });
    }
  } catch (err) {
    console.error('Hiba a mentés váltásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ MENTETT POSZTOK
app.get("/users/:id/saved-posts", async (req, res) => {
  const userId = req.params.id;

  try {
    const savedPosts = await dbAll(`
      SELECT p.*, u.username, sp.saved_at 
      FROM saved_posts sp 
      JOIN posts p ON sp.post_id = p.id 
      LEFT JOIN users u ON p.user_id = u.id 
      WHERE sp.user_id = ? 
      ORDER BY sp.saved_at DESC
    `, [userId]);

    // Kommentek lekérése
    for (let post of savedPosts) {
      const comments = await dbAll(`
        SELECT c.*, u.username 
        FROM comments c 
        LEFT JOIN users u ON c.user_id = u.id 
        WHERE c.post_id = ? 
        ORDER BY c.created_at ASC
      `, [post.id]);
      post.comments = comments;

      // Like információk
      const likeCount = await dbGet('SELECT COUNT(*) as count FROM post_likes WHERE post_id = ?', [post.id]);
      post.likes = likeCount.count;
    }

    res.json(savedPosts);
  } catch (err) {
    console.error('Hiba a mentett posztok lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ MENTÉSI STÁTUSZ
app.get("/posts/:id/save-status", async (req, res) => {
  const postId = req.params.id;
  const user_id = req.query.user_id;

  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    const save = await dbGet(
      'SELECT id FROM saved_posts WHERE post_id = ? AND user_id = ?',
      [postId, user_id]
    );

    res.json({ saved: !!save });
  } catch (err) {
    console.error('Hiba a mentési státusz lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ CHAT SZOBA LÉTREHOZÁSA
app.post("/chat/rooms", async (req, res) => {
  const { user1_id, user2_id } = req.body;

  if (!user1_id || !user2_id) {
    return res.status(400).json({ message: "Hiányzó user_id-k" });
  }

  try {
    let room = await dbGet(
      `SELECT * FROM chat_rooms 
       WHERE (user1_id = ? AND user2_id = ?) 
       OR (user1_id = ? AND user2_id = ?)`,
      [user1_id, user2_id, user2_id, user1_id]
    );

    if (!room) {
      const [minId, maxId] = [user1_id, user2_id].sort((a, b) => a - b);
      const result = await dbRun(
        'INSERT INTO chat_rooms (user1_id, user2_id) VALUES (?, ?)',
        [minId, maxId]
      );
      room = await dbGet('SELECT * FROM chat_rooms WHERE id = ?', [result.id]);
    }

    res.json(room);
  } catch (err) {
    console.error('Hiba a chat szoba létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ ÜZENET KÜLDÉSE
app.post("/chat/messages", async (req, res) => {
  const { room_id, sender_id, message } = req.body;

  if (!room_id || !sender_id || !message) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const result = await dbRun(
      'INSERT INTO messages (room_id, sender_id, message) VALUES (?, ?, ?)',
      [room_id, sender_id, message]
    );

    await dbRun(
      'UPDATE chat_rooms SET last_message_at = CURRENT_TIMESTAMP WHERE id = ?',
      [room_id]
    );

    const newMessage = await dbGet(
      `SELECT m.*, u.username as sender_username 
       FROM messages m 
       LEFT JOIN users u ON m.sender_id = u.id 
       WHERE m.id = ?`,
      [result.id]
    );

    res.json(newMessage);
  } catch (err) {
    console.error('Hiba az üzenet küldésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ ÜZENETEK LEKÉRÉSE
app.get("/chat/rooms/:roomId/messages", async (req, res) => {
  const roomId = req.params.roomId;

  try {
    const messages = await dbAll(
      `SELECT m.*, u.username as sender_username 
       FROM messages m 
       LEFT JOIN users u ON m.sender_id = u.id 
       WHERE m.room_id = ? 
       ORDER BY m.created_at ASC`,
      [roomId]
    );

    res.json(messages);
  } catch (err) {
    console.error('Hiba az üzenetek lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ CHAT SZOBÁK LEKÉRÉSE
app.get("/users/:userId/chat-rooms", async (req, res) => {
  const userId = req.params.userId;

  try {
    const rooms = await dbAll(
      `SELECT cr.*, 
              u1.username as user1_username,
              u2.username as user2_username,
              (SELECT message FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message,
              (SELECT created_at FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_time
       FROM chat_rooms cr
       LEFT JOIN users u1 ON cr.user1_id = u1.id
       LEFT JOIN users u2 ON cr.user2_id = u2.id
       WHERE cr.user1_id = ? OR cr.user2_id = ?
       ORDER BY cr.last_message_at DESC`,
      [userId, userId]
    );

    res.json(rooms);
  } catch (err) {
    console.error('Hiba a chat szobák lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ OLVASATLAN ÜZENETEK
app.get("/users/:userId/unread-messages", async (req, res) => {
  const userId = req.params.userId;

  try {
    const unreadCount = await dbGet(
      `SELECT COUNT(*) as count 
       FROM messages m
       JOIN chat_rooms cr ON m.room_id = cr.id
       WHERE m.is_read = 0 
       AND m.sender_id != ?
       AND (cr.user1_id = ? OR cr.user2_id = ?)`,
      [userId, userId, userId]
    );

    res.json({ unread_count: unreadCount.count });
  } catch (err) {
    console.error('Hiba az olvasatlan üzenetek lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ ÜZENETEK OLVASOTTNAK JELÖLÉSE
app.post("/chat/rooms/:roomId/mark-read", async (req, res) => {
  const roomId = req.params.roomId;
  const { user_id } = req.body;

  try {
    await dbRun(
      `UPDATE messages 
       SET is_read = 1 
       WHERE room_id = ? AND sender_id != ? AND is_read = 0`,
      [roomId, user_id]
    );

    res.json({ message: "Üzenetek olvasottnak jelölve" });
  } catch (err) {
    console.error('Hiba az üzenetek olvasottnak jelölésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ SZAVAZÁS LÉTREHOZÁSA
app.post("/posts/:id/poll", async (req, res) => {
  const postId = req.params.id;
  const { user_id, question, options } = req.body;

  if (!user_id || !question || !options || options.length < 2) {
    return res.status(400).json({
      message: "Hiányzó adatok: kérdés és legalább 2 opció szükséges"
    });
  }

  try {
    // Szavazás létrehozása
    const result = await dbRun(
      'INSERT INTO polls (post_id, user_id, question) VALUES (?, ?, ?)',
      [postId, user_id, question]
    );

    const pollId = result.id;

    // Opciók hozzáadása
    for (let option of options) {
      await dbRun(
        'INSERT INTO poll_options (poll_id, option_text) VALUES (?, ?)',
        [pollId, option.text]
      );
    }

    res.json({
      message: "Szavazás létrehozva",
      poll_id: pollId
    });
  } catch (err) {
    console.error('Hiba a szavazás létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ SZAVAZÁS LEADÁSA
app.post("/polls/:id/vote", async (req, res) => {
  const pollId = req.params.id;
  const { user_id, option_id } = req.body;

  if (!user_id || !option_id) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    // Ellenőrizzük, hogy szavazott-e már
    const existingVote = await dbGet(
      'SELECT id FROM poll_votes WHERE poll_id = ? AND user_id = ?',
      [pollId, user_id]
    );

    if (existingVote) {
      return res.status(400).json({ message: "Már szavaztál erre a szavazásra" });
    }

    // Szavazat rögzítése
    await dbRun(
      'INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES (?, ?, ?)',
      [pollId, option_id, user_id]
    );

    // Frissítjük az opció szavazatszámát
    await dbRun(
      'UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = ?',
      [option_id]
    );

    res.json({ message: "Szavazat leadva" });
  } catch (err) {
    console.error('Hiba a szavazás leadásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ SZAVAZÁS ADATAI
app.get("/polls/:id", async (req, res) => {
  const pollId = req.params.id;
  const user_id = req.query.user_id;

  try {
    // Szavazás alapadatok
    const poll = await dbGet(`
      SELECT p.*, u.username 
      FROM polls p 
      LEFT JOIN users u ON p.user_id = u.id 
      WHERE p.id = ?
    `, [pollId]);

    if (!poll) {
      return res.status(404).json({ message: "Szavazás nem található" });
    }

    // Opciók lekérése
    const options = await dbAll(`
      SELECT po.*, 
             EXISTS(SELECT 1 FROM poll_votes pv WHERE pv.option_id = po.id AND pv.user_id = ?) as user_voted
      FROM poll_options po 
      WHERE po.poll_id = ?
    `, [user_id, pollId]);

    // Összes szavazat számának kiszámítása
    const totalVotes = options.reduce((sum, option) => sum + option.votes_count, 0);

    // Százalékos arányok hozzáadása
    const optionsWithPercent = options.map(option => ({
      ...option,
      percentage: totalVotes > 0 ? Math.round((option.votes_count / totalVotes) * 100) : 0
    }));

    res.json({
      ...poll,
      options: optionsWithPercent,
      total_votes: totalVotes,
      user_has_voted: options.some(option => option.user_voted)
    });
  } catch (err) {
    console.error('Hiba a szavazás lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ EGYSZERŰ TESZT VÉGPONT
app.get("/test", (req, res) => {
  res.json({
    status: "ok",
    message: "Szerver működik!",
    timestamp: new Date().toISOString()
  });
});

// ✅ HEALTH CHECK
app.get("/health", async (req, res) => {
  try {
    const users = await dbGet('SELECT COUNT(*) as total FROM users');
    const posts = await dbGet('SELECT COUNT(*) as total FROM posts');
    const comments = await dbGet('SELECT COUNT(*) as total FROM comments');
    
    res.json({
      status: "ok",
      database: "sqlite",
      stats: {
        users: users.total,
        posts: posts.total,
        comments: comments.total
      },
      lastActivity: lastActivity,
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.json({
      status: "error",
      database: "sqlite",
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ✅ DEBUG VÉGPONTOK
app.get("/debug/users", async (req, res) => {
  try {
    const users = await dbAll('SELECT id, username, email FROM users');
    console.log('📊 Összes felhasználó:', users);
    res.json({
      total: users.length,
      users: users
    });
  } catch (err) {
    console.error('Hiba a felhasználók lekérésekor:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post("/debug/create-test-user", async (req, res) => {
  try {
    const hashedPw = await bcrypt.hash("test123", 10);
    
    const result = await dbRun(
      'INSERT OR IGNORE INTO users (username, password, email) VALUES (?, ?, ?)',
      ["adam", hashedPw, "adam@test.com"]
    );
    
    const users = await dbAll('SELECT * FROM users WHERE username = "adam"');
    
    res.json({
      message: "Teszt felhasználó létrehozva",
      userId: result.id,
      users: users
    });
  } catch (err) {
    console.error('Hiba a teszt felhasználó létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ FŐOLDAL
app.get("/", async (req, res) => {
  try {
    const usersCount = await dbGet('SELECT COUNT(*) as count FROM users');
    const users = await dbAll('SELECT username, email, created_at, last_login FROM users ORDER BY created_at DESC');
    
    const html = `
    <!DOCTYPE html>
    <html lang="hu">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>SocialM Szerver - JAVÍTOTT</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .stats { display: flex; justify-content: space-around; margin-bottom: 30px; }
        .stat-box { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 8px; }
        .users-table { width: 100%; border-collapse: collapse; }
        .users-table th, .users-table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        .users-table th { background: #f8f9fa; }
        .status-online { color: green; font-weight: bold; }
        .status-offline { color: gray; }
        .api-info { background: #e9ecef; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .success { color: green; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚀 SocialM Szerver - <span class="success">JAVÍTOTT VERZIÓ</span></h1>
          <p>SQLite adatbázissal - Like/Unlike működik!</p>
        </div>
        
        <div class="stats">
          <div class="stat-box">
            <div style="font-size: 2em; font-weight: bold;">${usersCount.count}</div>
            <div>Regisztrált felhasználó</div>
          </div>
          <div class="stat-box">
            <div style="font-size: 2em;">✅</div>
            <div>Like/Unlike működik</div>
          </div>
          <div class="stat-box">
            <div style="font-size: 2em;">🟢</div>
            <div>Szerver aktív</div>
          </div>
        </div>

        <div class="api-info">
          <h3>📡 Elérhető API végpontok:</h3>
          <ul>
            <li><strong>POST /register</strong> - Regisztráció ✅</li>
            <li><strong>POST /login</strong> - Bejelentkezés ✅</li>
            <li><strong>POST /posts</strong> - Új bejegyzés ✅</li>
            <li><strong>GET /posts</strong> - Bejegyzések listázása ✅</li>
            <li><strong>POST /posts/:id/like</strong> - Like/Unlike ✅</li>
            <li><strong>GET /posts/:id/like-status</strong> - Like státusz ✅</li>
            <li><strong>POST /posts/:id/comments</strong> - Komment hozzáadása ✅</li>
            <li><strong>POST /posts/:id/save</strong> - Mentés ✅</li>
          </ul>
        </div>
        
        <h2>📊 Regisztrált felhasználók</h2>
        
        ${users.length > 0 ? `
        <table class="users-table">
          <thead>
            <tr>
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
                <td><strong>${user.username}</strong></td>
                <td>${user.email || 'Nincs megadva'}</td>
                <td>${new Date(user.created_at).toLocaleString("hu-HU")}</td>
                <td>${user.last_login ? new Date(user.last_login).toLocaleString("hu-HU") : 'Még nem jelentkezett be'}</td>
                <td><span class="${user.last_login ? 'status-online' : 'status-offline'}">${user.last_login ? 'Aktív' : 'Inaktív'}</span></td>
              </tr>
            `).join('')}
          </tbody>
        </table>
        ` : `
        <div style="text-align: center; padding: 40px;">
          <h3>🤷‍♂️ Még nincsenek regisztrált felhasználók</h3>
          <p>Az első felhasználó regisztrálása után itt fognak megjelenni az adatok.</p>
        </div>
        `}
        
        <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 10px;">
          <h3>ℹ️ Szerver információk</h3>
          <p><strong>Adatbázis:</strong> SQLite (Lokális fájl)</p>
          <p><strong>Port:</strong> ${PORT}</p>
          <p><strong>Utolsó frissítés:</strong> ${new Date().toLocaleString("hu-HU")}</p>
          <p><strong>Státusz:</strong> <span class="success">Minden funkció működik!</span></p>
        </div>
      </div>
    </body>
    </html>
    `;
    
    res.send(html);
  } catch (error) {
    console.error('Hiba a főoldal betöltésekor:', error);
    res.status(500).send('Hiba a szerveren');
  }
});






// ✅ KVIZ VÉGPONTOK

// ✅ KVIZEK LEKÉRÉSE
app.get("/quizzes", async (req, res) => {
  try {
    const { category, difficulty, search } = req.query;
    
    let sql = `
      SELECT q.*, u.username as creator_username,
             (SELECT COUNT(*) FROM quiz_plays WHERE quiz_id = q.id) as plays_count,
             (SELECT AVG(score) FROM quiz_plays WHERE quiz_id = q.id) as average_score
      FROM quizzes q
      LEFT JOIN users u ON q.created_by = u.id
      WHERE q.is_public = 1
    `;
    let params = [];
    
    if (category && category !== 'Összes') {
      sql += ' AND q.category = ?';
      params.push(category);
    }
    
    if (difficulty) {
      sql += ' AND q.difficulty = ?';
      params.push(difficulty);
    }
    
    if (search) {
      sql += ' AND (q.title LIKE ? OR q.description LIKE ?)';
      const searchParam = `%${search}%`;
      params.push(searchParam, searchParam);
    }
    
    sql += ' ORDER BY q.created_at DESC';
    
    const quizzes = await dbAll(sql, params);
    
    // Kérdések lekérése minden kvízhez
    for (let quiz of quizzes) {
      const questions = await dbAll(`
        SELECT * FROM quiz_questions 
        WHERE quiz_id = ? 
        ORDER BY question_order ASC
      `, [quiz.id]);
      
      quiz.questions = questions;
      
      // Opciók lekérése minden kérdéshez
      for (let question of quiz.questions) {
        const options = await dbAll(`
          SELECT * FROM quiz_options 
          WHERE question_id = ? 
          ORDER BY option_order ASC
        `, [question.id]);
        question.options = options.map(opt => opt.option_text);
      }
    }
    
    res.json(quizzes);
  } catch (err) {
    console.error('Hiba a kvízek lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ ÚJ KVIZ LÉTREHOZÁSA
app.post("/quizzes", async (req, res) => {
  const { title, description, category, difficulty, time_limit, max_players, is_public, questions, created_by } = req.body;

  if (!title || !questions || !created_by) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    // Kvíz létrehozása
    const quizResult = await dbRun(
      `INSERT INTO quizzes (title, description, category, difficulty, time_limit, max_players, is_public, created_by) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [title, description, category, difficulty, time_limit, max_players, is_public ? 1 : 0, created_by]
    );

    const quizId = quizResult.id;

    // Kérdések hozzáadása
    for (let i = 0; i < questions.length; i++) {
      const question = questions[i];
      const questionResult = await dbRun(
        `INSERT INTO quiz_questions (quiz_id, question_text, explanation, question_order, correct_answer) 
         VALUES (?, ?, ?, ?, ?)`,
        [quizId, question.question, question.explanation || '', i, question.correctAnswer]
      );

      const questionId = questionResult.id;

      // Opciók hozzáadása
      for (let j = 0; j < question.options.length; j++) {
        await dbRun(
          `INSERT INTO quiz_options (question_id, option_text, option_order) 
           VALUES (?, ?, ?)`,
          [questionId, question.options[j], j]
        );
      }
    }

    res.json({
      message: "Kvíz létrehozva",
      quiz_id: quizId
    });
  } catch (err) {
    console.error('Hiba a kvíz létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ KVIZ SESSION LÉTREHOZÁSA
app.post("/quiz-sessions", async (req, res) => {
  const { quiz_id, creator_id, invited_users = [] } = req.body;

  if (!quiz_id || !creator_id) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    // Session kód generálása
    const sessionCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    const sessionResult = await dbRun(
      `INSERT INTO quiz_sessions (quiz_id, creator_id, session_code, status) 
       VALUES (?, ?, ?, 'waiting')`,
      [quiz_id, creator_id, sessionCode]
    );

    const sessionId = sessionResult.id;

    // Creator hozzáadása játékosként
    await dbRun(
      `INSERT INTO quiz_players (session_id, user_id, is_ready) 
       VALUES (?, ?, 1)`,
      [sessionId, creator_id]
    );

    // Meghívott felhasználók hozzáadása
    for (let userId of invited_users) {
      await dbRun(
        `INSERT INTO quiz_players (session_id, user_id) 
         VALUES (?, ?)`,
        [sessionId, userId]
      );
    }

    const session = await dbGet(`
      SELECT qs.*, q.title as quiz_title, u.username as creator_username
      FROM quiz_sessions qs
      LEFT JOIN quizzes q ON qs.quiz_id = q.id
      LEFT JOIN users u ON qs.creator_id = u.id
      WHERE qs.id = ?
    `, [sessionId]);

    res.json({
      ...session,
      session_code: sessionCode
    });
  } catch (err) {
    console.error('Hiba a session létrehozásakor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ CSATLAKOZÁS SESSION-HEZ
app.post("/quiz-sessions/:sessionId/join", async (req, res) => {
  const sessionId = req.params.sessionId;
  const { user_id } = req.body;

  if (!user_id) {
    return res.status(400).json({ message: "Hiányzó user_id" });
  }

  try {
    // Ellenőrizzük, hogy létezik-e a session
    const session = await dbGet('SELECT * FROM quiz_sessions WHERE id = ?', [sessionId]);
    if (!session) {
      return res.status(404).json({ message: "Session nem található" });
    }

    // Ellenőrizzük, hogy már csatlakozott-e
    const existingPlayer = await dbGet(
      'SELECT id FROM quiz_players WHERE session_id = ? AND user_id = ?',
      [sessionId, user_id]
    );

    if (existingPlayer) {
      return res.status(400).json({ message: "Már csatlakoztál ehhez a session-hez" });
    }

    // Játékos hozzáadása
    await dbRun(
      'INSERT INTO quiz_players (session_id, user_id) VALUES (?, ?)',
      [sessionId, user_id]
    );

    res.json({ message: "Sikeresen csatlakoztál a session-hez" });
  } catch (err) {
    console.error('Hiba a csatlakozáskor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ SESSION ADATAI
app.get("/quiz-sessions/:sessionId", async (req, res) => {
  const sessionId = req.params.sessionId;

  try {
    const session = await dbGet(`
      SELECT qs.*, q.title as quiz_title, q.description as quiz_description,
             u.username as creator_username
      FROM quiz_sessions qs
      LEFT JOIN quizzes q ON qs.quiz_id = q.id
      LEFT JOIN users u ON qs.creator_id = u.id
      WHERE qs.id = ?
    `, [sessionId]);

    if (!session) {
      return res.status(404).json({ message: "Session nem található" });
    }

    // Játékosok lekérése
    const players = await dbAll(`
      SELECT qp.*, u.username 
      FROM quiz_players qp
      LEFT JOIN users u ON qp.user_id = u.id
      WHERE qp.session_id = ?
    `, [sessionId]);

    session.players = players;

    res.json(session);
  } catch (err) {
    console.error('Hiba a session lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ VÁLASZ BEKÜLDÉSE
app.post("/quiz-sessions/:sessionId/answer", async (req, res) => {
  const sessionId = req.params.sessionId;
  const { user_id, question_id, selected_answer, answer_time } = req.body;

  if (!user_id || !question_id || selected_answer === undefined) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    await dbRun(
      `INSERT INTO quiz_answers (session_id, user_id, question_id, selected_answer, answer_time) 
       VALUES (?, ?, ?, ?, ?)`,
      [sessionId, user_id, question_id, selected_answer, answer_time || Date.now()]
    );

    res.json({ message: "Válasz sikeresen beküldve" });
  } catch (err) {
    console.error('Hiba a válasz beküldésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ EREDMÉNYEK LEKÉRÉSE
app.get("/quiz-sessions/:sessionId/results", async (req, res) => {
  const sessionId = req.params.sessionId;

  try {
    const results = await dbAll(`
      SELECT u.username, 
             COUNT(CASE WHEN qo.option_order = qq.correct_answer THEN 1 END) as correct_answers,
             COUNT(*) as total_questions,
             SUM(qa.answer_time) as total_time
      FROM quiz_answers qa
      LEFT JOIN quiz_questions qq ON qa.question_id = qq.id
      LEFT JOIN quiz_options qo ON qa.question_id = qo.question_id AND qa.selected_answer = qo.option_order
      LEFT JOIN users u ON qa.user_id = u.id
      WHERE qa.session_id = ?
      GROUP BY qa.user_id
      ORDER BY correct_answers DESC, total_time ASC
    `, [sessionId]);

    res.json(results);
  } catch (err) {
    console.error('Hiba az eredmények lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});

// ✅ FELHASZNÁLÓ KVIZ EREDMÉNYEI
app.get("/users/:userId/quiz-stats", async (req, res) => {
  const userId = req.params.userId;

  try {
    const stats = await dbGet(`
      SELECT 
        COUNT(DISTINCT qp.session_id) as games_played,
        AVG(qp.score) as average_score,
        MAX(qp.score) as best_score,
        COUNT(CASE WHEN qp.position = 1 THEN 1 END) as wins
      FROM quiz_plays qp
      WHERE qp.user_id = ?
    `, [userId]);

    const recentGames = await dbAll(`
      SELECT q.title, qp.score, qp.position, qp.played_at
      FROM quiz_plays qp
      LEFT JOIN quiz_sessions qs ON qp.session_id = qs.id
      LEFT JOIN quizzes q ON qs.quiz_id = q.id
      WHERE qp.user_id = ?
      ORDER BY qp.played_at DESC
      LIMIT 10
    `, [userId]);

    res.json({
      ...stats,
      recent_games: recentGames
    });
  } catch (err) {
    console.error('Hiba a statisztikák lekérésekor:', err);
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});



// Szerver indítás
initializeDatabase().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 SocialM szerver fut: http://localhost:${PORT}`);
    console.log(`🗃️ Adatbázis: SQLite (socialm.db)`);
    console.log(`✅ Like/Unlike rendszer működik!`);
    console.log(`📡 API végpontok elérhetőek!`);
  });
}).catch(error => {
  console.error('❌ Hiba az adatbázis inicializálásakor:', error);
});
