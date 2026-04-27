import { NextResponse } from 'next/server';
import nodemailer from 'nodemailer';

export async function POST(req: Request) {
  try {
    const { name, email, message } = await req.json();

    // 1. Basic Validation
    if (!name || !email || !message) {
      return NextResponse.json(
        { error: 'All fields are required' },
        { status: 400 }
      );
    }

    // 2. Email Format Validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { error: 'Invalid email format' },
        { status: 400 }
      );
    }

    // 3. Configure Hostinger SMTP Transporter
    const transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST || 'smtp.hostinger.com',
      port: Number(process.env.EMAIL_PORT) || 465,
      secure: true, // true for 465
      auth: {
        user: process.env.EMAIL_USER, // e.g., support@trimapp.co
        pass: process.env.EMAIL_PASS, // Your Hostinger email password
      },
    });

    // 4. Send Email
    await transporter.sendMail({
      from: `"Trim Contact Form" <${process.env.EMAIL_USER}>`,
      to: 'support@trimapp.co',
      replyTo: email,
      subject: `New Contact Submission from ${name}`,
      text: `Name: ${name}\nEmail: ${email}\n\nMessage:\n${message}`,
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; padding: 32px; background-color: #ffffff; color: #0f172a;">
          <h2 style="color: #0f172a; margin-top: 0; font-size: 24px;">New Message for Trim Support</h2>
          <p style="color: #64748b; font-size: 16px; margin-bottom: 24px;">You have received a new contact form submission from the Trim landing page.</p>
          
          <div style="background: #f8fafc; padding: 24px; border-radius: 12px; margin-bottom: 24px;">
            <p style="margin: 0 0 10px 0;"><strong>Name:</strong> ${name}</p>
            <p style="margin: 0 0 10px 0;"><strong>Email:</strong> <a href="mailto:${email}" style="color: #4ade80; text-decoration: none;">${email}</a></p>
            <p style="margin: 20px 0 10px 0;"><strong>Message:</strong></p>
            <p style="margin: 0; white-space: pre-wrap; color: #334155; line-height: 1.6;">${message}</p>
          </div>
          
          <p style="font-size: 12px; color: #94a3b8; text-align: center; margin-top: 32px;">
            This email was sent from the Trim Contact Form backend.
          </p>
        </div>
      `,
    });

    return NextResponse.json(
      { message: 'Message sent successfully' },
      { status: 200 }
    );

  } catch (error) {
    console.error('Hostinger SMTP Error:', error);
    return NextResponse.json(
      { error: 'Failed to send message via Hostinger' },
      { status: 500 }
    );
  }
}
