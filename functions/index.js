const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

// Настраиваем транспорт для Gmail или Яндекс SMTP
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com", // Для Яндекса: smtp.yandex.ru
  port: 465,
  secure: true, // true для 465, false для 587
  auth: {
    user: "mazitova.arincka@yandex.ru",   // твоя почта Яндекс
    pass: "qqctxfeqnmvtqrhf"
  }
});

exports.sendVerificationCode = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const code = Math.floor(100000 + Math.random() * 900000).toString();

  await db.collection("emailVerifications").doc(email).set({
    code,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  const mailOptions = {
    from: '"languageapl" <mazitova.arincka@yandex.ru>', // или Яндекс почта
    to: email,
    subject: "Код подтверждения",
    text: `Ваш код подтверждения: ${code}`
  };

  await transporter.sendMail(mailOptions);
  return { success: true };
});
