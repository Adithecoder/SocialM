// database.js - JAVÍTOTT VERZIÓ
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'socialm.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Hiba az SQLite adatbázis kapcsolatban:', err.message);
  } else {
    console.log('✅ SQLite adatbázis kapcsolat létrejött');
  }
});

// Helper függvények
const dbAll = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

const dbRun = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

const dbGet = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};



// LIKE-ok kezeléséhez új tábla
function initializeDatabase() {
  return new Promise((resolve, reject) => {
    console.log('🔄 Adatbázis inicializálása...');
    
    // Users tábla
    db.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_login DATETIME
      )
    `, (err) => {
      if (err) {
        console.error('❌ Hiba a users tábla létrehozásakor:', err);
        reject(err);
      } else {
        console.log('✅ Users tábla létrehozva/ellenőrizve');
      }
    });

    // Posts tábla
    db.run(`
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        content TEXT,
        image_url TEXT,
        video_url TEXT,
        likes INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    `, (err) => {
      if (err) {
        console.error('❌ Hiba a posts tábla létrehozásakor:', err);
        reject(err);
      } else {
        console.log('✅ Posts tábla létrehozva/ellenőrizve');
      }
    });

    // Comments tábla
    db.run(`
      CREATE TABLE IF NOT EXISTS comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER,
        user_id INTEGER,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    `, (err) => {
      if (err) {
        console.error('❌ Hiba a comments tábla létrehozásakor:', err);
        reject(err);
      } else {
        console.log('✅ Comments tábla létrehozva/ellenőrizve');
      }
    });

    // Likes tábla - ÚJ: Like-ok nyilvántartása
    db.run(`
      CREATE TABLE IF NOT EXISTS post_likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER,
        user_id INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(post_id, user_id)
      )
    `, (err) => {
      if (err) {
        console.error('❌ Hiba a post_likes tábla létrehozásakor:', err);
        reject(err);
      } else {
        console.log('✅ Post_likes tábla létrehozva/ellenőrizve');
      }
    });

    // Saved posts tábla
    db.run(`
      CREATE TABLE IF NOT EXISTS saved_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id INTEGER,
        user_id INTEGER,
        saved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (post_id) REFERENCES posts (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(post_id, user_id)
      )
    `, (err) => {
      if (err) {
        console.error('❌ Hiba a saved_posts tábla létrehozásakor:', err);
        reject(err);
      } else {
        console.log('✅ Saved posts tábla létrehozva/ellenőrizve');
      }
    });

      
      // Polls tábla
      db.run(`
        CREATE TABLE IF NOT EXISTS polls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          question TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (post_id) REFERENCES posts (id),
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      `, (err) => {
        if (err) console.error('Hiba a polls tábla létrehozásakor:', err);
        else console.log('✅ Polls tábla létrehozva/ellenőrizve');
      });

      // Poll options tábla
      db.run(`
        CREATE TABLE IF NOT EXISTS poll_options (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          poll_id INTEGER NOT NULL,
          option_text TEXT NOT NULL,
          votes_count INTEGER DEFAULT 0,
          FOREIGN KEY (poll_id) REFERENCES polls (id)
        )
      `, (err) => {
        if (err) console.error('Hiba a poll_options tábla létrehozásakor:', err);
        else console.log('✅ Poll options tábla létrehozva/ellenőrizve');
      });

      // Poll votes tábla
      db.run(`
        CREATE TABLE IF NOT EXISTS poll_votes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          poll_id INTEGER NOT NULL,
          option_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (poll_id) REFERENCES polls (id),
          FOREIGN KEY (option_id) REFERENCES poll_options (id),
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(poll_id, user_id)
        )
      `, (err) => {
        if (err) console.error('Hiba a poll_votes tábla létrehozásakor:', err);
        else console.log('✅ Poll votes tábla létrehozva/ellenőrizve');
      });
      
      
    // Chat táblák
    db.run(`
      CREATE TABLE IF NOT EXISTS chat_rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user1_id INTEGER NOT NULL,
        user2_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_message_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user1_id, user2_id),
        FOREIGN KEY (user1_id) REFERENCES users (id),
        FOREIGN KEY (user2_id) REFERENCES users (id)
      )
    `, (err) => {
      if (err) reject(err);
    });

    db.run(`
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (room_id) REFERENCES chat_rooms (id),
        FOREIGN KEY (sender_id) REFERENCES users (id)
      )
    `, (err) => {
      if (err) reject(err);
    });

    // Indexek
    db.run(`CREATE INDEX IF NOT EXISTS idx_room_id ON messages(room_id)`, (err) => {
      if (err) reject(err);
    });
    
    db.run(`CREATE INDEX IF NOT EXISTS idx_sender_id ON messages(sender_id)`, (err) => {
      if (err) reject(err);
    });
    
    db.run(`CREATE INDEX IF NOT EXISTS idx_created_at ON messages(created_at)`, (err) => {
      if (err) reject(err);
      console.log('✅ Összes adatbázis tábla inicializálva');
      resolve();
    });
  });
}

module.exports = {
    db,
    initializeDatabase,
    dbAll,
    dbRun,
    dbGet
};
