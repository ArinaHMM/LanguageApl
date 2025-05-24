const express = require("express");
const nodemailer = require("nodemailer");
const bodyParser = require("body-parser");

const app = express();
app.use(bodyParser.json());

const PORT = 3000;

// Для хранения кодов (в реальном — лучше использовать БД или кеш с TTL)
const codes = {};

// Настройка почты
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "lerasemenova01697@gmail.com",
    pass: "itmlodizonhhpsxl",
  },
});

// Маршрут для отправки кода
app.post("/send-code", async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: "Email обязателен" });

  const code = Math.floor(100000 + Math.random() * 900000).toString();

  // Сохраняем код (например, с временем жизни 10 минут)
  codes[email] = { code, expires: Date.now() + 10 * 60 * 1000 };

  try {
    await transporter.sendMail({
      from: `"LingoQuest" <lerasemenova01697@gmail.com>`,
      to: email,
      subject: "Код подтверждения",
      text: `Ваш код подтверждения: ${code}`,
    });
    res.json({ success: true, message: "Код отправлен на почту" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Ошибка при отправке письма" });
  }
});

// Маршрут для проверки кода
app.post("/verify-code", (req, res) => {
  const { email, code } = req.body;
  if (!email || !code)
    return res.status(400).json({ error: "Email и код обязательны" });

  const record = codes[email];
  if (!record) return res.status(400).json({ error: "Код не найден, запросите новый" });

  if (Date.now() > record.expires) {
    delete codes[email];
    return res.status(400).json({ error: "Код истёк, запросите новый" });
  }

  if (record.code === code) {
    delete codes[email];
    return res.json({ success: true, message: "Код подтверждён" });
  } else {
    return res.status(400).json({ error: "Неверный код" });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Email server running on http://0.0.0.0:${PORT}`);
});

