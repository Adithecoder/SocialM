//
//  register.js
//  SocialM
//
//  Created by Czeglédi Ádi on 9/27/25.
//

const bcrypt = require("bcrypt");

app.post("/register", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: "Hiányzó adatok" });
  }

  try {
    const existing = await User.findOne({ username });
    if (existing) {
      return res.status(400).json({ message: "Felhasználó már létezik" });
    }

    const hashedPw = await bcrypt.hash(password, 10);
    const newUser = new User({ username, password: hashedPw });
    await newUser.save();

    res.json({ message: "Sikeres regisztráció" });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});
