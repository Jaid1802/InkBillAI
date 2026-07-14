# Supabase OTP Verification Setup

The app uses email/password signup followed by **6-digit email OTP** verification.

## Required Dashboard Changes

### 1. Keep email confirmations enabled

Go to **Supabase Dashboard → Authentication → Settings → General**

Ensure **"Enable email confirmations"** is **ON**.

### 2. Update the Confirm signup email template

Go to **Supabase Dashboard → Authentication → Email Templates → Confirm signup**

Replace the default template content with the following.

**`{{ .Token }}` is what the app reads** — the template must display it, not `{{ .ConfirmationURL }}`.

**Subject:**
```
Verify your email — InkBill AI
```

**Body (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; padding: 24px;">
    <tr>
      <td style="text-align: center; padding: 32px 0;">
        <h1 style="color: #1A237E; font-size: 28px; margin: 0;">InkBill AI</h1>
        <p style="color: #666; font-size: 14px; margin: 4px 0 0;">Digital Ink Billing</p>
      </td>
    </tr>
    <tr>
      <td style="background-color: #ffffff; border-radius: 12px; padding: 32px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
        <h2 style="color: #1A237E; font-size: 20px; margin: 0 0 16px;">Verify your email</h2>
        <p style="color: #333; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          Thank you for signing up for InkBill AI. Use the verification code below to complete your registration.
        </p>
        <div style="text-align: center; margin: 32px 0;">
          <div style="display: inline-block; background-color: #1A237E; color: #ffffff; font-size: 36px; font-weight: bold; letter-spacing: 12px; padding: 16px 32px; border-radius: 8px;">
            {{ .Token }}
          </div>
        </div>
        <p style="color: #333; font-size: 15px; line-height: 1.6; margin: 0 0 16px;">
          Enter this code in the InkBill AI app to verify your email address.
        </p>
        <p style="color: #999; font-size: 13px; line-height: 1.5; margin: 0;">
          This code will expire in 10 minutes. If you did not create an account with InkBill AI, please ignore this email.
        </p>
      </td>
    </tr>
    <tr>
      <td style="text-align: center; padding: 24px 0;">
        <p style="color: #999; font-size: 12px; margin: 0;">
          InkBill AI &mdash; Never share this code with anyone.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
```

**Body (Text):**
```
InkBill AI — Verify your email

Thank you for signing up for InkBill AI.

Your verification code is: {{ .Token }}

Enter this code in the InkBill AI app to verify your email address.

This code will expire in 10 minutes.

If you did not create an account with InkBill AI, please ignore this email.
```

### 3. Verify no localhost redirect

The email **must not** contain a link to `localhost:3000` or any other URL. The user enters the code directly in the app.

## How the OTP Flow Works

1. User signs up with email + password → `supabase.auth.signUp()`
2. Supabase creates the user (unconfirmed) and sends the "Confirm signup" email
3. Email body contains `{{ .Token }}` — the 6-digit code
4. User enters the 6-digit code on the Verify Email screen
5. App calls `supabase.auth.verifyOTP(type: OtpType.email, ...)`
6. Supabase validates the token and returns a session
7. App creates the profile/shop via `onboard_new_user` RPC and navigates to the main app

## API Summary

| Operation | API Call |
|-----------|----------|
| Sign up | `supabase.auth.signUp(email, password, data)` |
| Verify OTP | `supabase.auth.verifyOTP(email, token, type: OtpType.email)` |
| Resend | `supabase.auth.resend(type: OtpType.signup, email)` |
| Login | `supabase.auth.signInWithPassword(email, password)` |

## Testing Checklist

- [ ] Fresh signup with new email → user created in Supabase Auth
- [ ] OTP email received with 6-digit code
- [ ] Correct OTP → verified, profile created, navigated to home
- [ ] Wrong OTP → error message shown
- [ ] Expired OTP → "expired" message + resend option
- [ ] Resend → new OTP sent, cooldown shown
- [ ] Resend rate-limited → friendly error
- [ ] Login with unverified email → "verify your email" prompt + resend button
- [ ] Login with verified email → success
- [ ] Wrong password → "Invalid email or password"
- [ ] Logout → returns to login
- [ ] App restart after login → session restored

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| No OTP email received | Email template still uses `ConfirmationURL` | Update template to display `{{ .Token }}` |
| "The verification code is incorrect" | OTP expired, wrong, or wrong verify type | Request new code via "Resend" |
| "Too many attempts" | Rate-limited by Supabase | Wait before retrying |
| Login says "Email not confirmed" but user verified | Profile creation failed | Check Supabase `onboard_new_user` RPC exists |
| App shows white screen after login | Session not fully restored | Check auth listener in debug logs |
