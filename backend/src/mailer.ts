import nodemailer from 'nodemailer';

// SMTP_URL e.g. smtps://user:pass@smtp.example.com:465
const transport = process.env.SMTP_URL ? nodemailer.createTransport(process.env.SMTP_URL) : null;

/** Sends an email, or logs it in development when SMTP isn't configured. */
export async function sendMail(to: string, subject: string, text: string): Promise<void> {
  if (transport) {
    await transport.sendMail({ from: process.env.MAIL_FROM || 'AutoLearn <no-reply@autolearn.app>', to, subject, text });
    return;
  }
  if (process.env.NODE_ENV === 'production') {
    console.error(`SMTP_URL is not set — could not send "${subject}" to ${to}`);
    return;
  }
  console.log(`\n[dev mail] to=${to} subject="${subject}"\n${text}\n`);
}
