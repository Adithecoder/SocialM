//
//  login.js
//  SocialM
//
//  Created by Czeglédi Ádi on 9/27/25.
//

const jwt = require("jsonwebtoken");
const SECRET = "titkoskulcs"; // ⚠️ Ezt .env fájlban kellene tárolni!

app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Hibás belépési adatok" });
    }

    const token = jwt.sign({ id: user._id }, SECRET, { expiresIn: "1h" });

    res.json({ message: "Sikeres belépés", token });
  } catch (err) {
    res.status(500).json({ message: "Szerver hiba", error: err.message });
  }
});
