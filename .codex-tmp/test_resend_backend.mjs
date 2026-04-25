import dotenv from "dotenv";

dotenv.config({ path: "/var/www/myapp/backend/.env" });

const { sendEmail } = await import("/var/www/myapp/backend/src/services/email.service.js");

const result = await sendEmail({
  to: "delivered@resend.dev",
  subject: "Tawsil Resend verification",
  text: "Backend Resend transport OK",
  html: "<strong>Backend Resend transport OK</strong>"
});

console.log(JSON.stringify(result));
