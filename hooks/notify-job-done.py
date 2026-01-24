#!/usr/bin/env python3
"""
Notification hook for Claude Code - sends notification when a job completes.

Configure by setting environment variables:
  NOTIFY_METHOD: "email", "desktop", or "ntfy" (default: desktop)

For email:
  NOTIFY_EMAIL_TO: recipient email
  NOTIFY_EMAIL_FROM: sender email
  NOTIFY_SMTP_HOST: SMTP server (default: smtp.gmail.com)
  NOTIFY_SMTP_PORT: SMTP port (default: 587)
  NOTIFY_SMTP_USER: SMTP username
  NOTIFY_SMTP_PASS: SMTP password or app password

For ntfy (free push notifications - https://ntfy.sh):
  NOTIFY_NTFY_TOPIC: your ntfy topic name
"""

import os
import sys
import json
import subprocess
from datetime import datetime

def get_context():
    """Get context from Claude Code hook input."""
    try:
        stdin_data = sys.stdin.read()
        if stdin_data:
            return json.loads(stdin_data)
    except:
        pass
    return {}

def send_email(subject: str, body: str):
    """Send email via SMTP."""
    import smtplib
    from email.mime.text import MIMEText
    from email.mime.multipart import MIMEMultipart

    to_email = os.environ.get("NOTIFY_EMAIL_TO")
    from_email = os.environ.get("NOTIFY_EMAIL_FROM")
    smtp_host = os.environ.get("NOTIFY_SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.environ.get("NOTIFY_SMTP_PORT", "587"))
    smtp_user = os.environ.get("NOTIFY_SMTP_USER")
    smtp_pass = os.environ.get("NOTIFY_SMTP_PASS")

    if not all([to_email, from_email, smtp_user, smtp_pass]):
        print("Email notification not configured. Set NOTIFY_EMAIL_* env vars.", file=sys.stderr)
        return False

    msg = MIMEMultipart()
    msg['From'] = from_email
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Email send failed: {e}", file=sys.stderr)
        return False

def send_desktop_notification(title: str, body: str):
    """Send desktop notification (works on WSL with Windows integration)."""
    try:
        # Try Windows toast notification via PowerShell (for WSL)
        ps_script = f'''
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $template = "<toast><visual><binding template='ToastText02'><text id='1'>{title}</text><text id='2'>{body}</text></binding></visual></toast>"
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
        '''
        subprocess.run(
            ["powershell.exe", "-Command", ps_script],
            capture_output=True,
            timeout=10
        )
        return True
    except:
        pass

    try:
        # Fallback: try notify-send (Linux)
        subprocess.run(
            ["notify-send", title, body],
            capture_output=True,
            timeout=5
        )
        return True
    except:
        pass

    print(f"Desktop notification: {title} - {body}", file=sys.stderr)
    return False

def send_ntfy(title: str, body: str):
    """Send push notification via ntfy.sh (free service)."""
    import urllib.request
    import urllib.error

    topic = os.environ.get("NOTIFY_NTFY_TOPIC")
    if not topic:
        print("ntfy notification not configured. Set NOTIFY_NTFY_TOPIC env var.", file=sys.stderr)
        return False

    try:
        req = urllib.request.Request(
            f"https://ntfy.sh/{topic}",
            data=body.encode('utf-8'),
            headers={"Title": title}
        )
        urllib.request.urlopen(req, timeout=10)
        return True
    except Exception as e:
        print(f"ntfy send failed: {e}", file=sys.stderr)
        return False

def main():
    context = get_context()
    method = os.environ.get("NOTIFY_METHOD", "desktop").lower()

    # Build notification content
    cwd = context.get("cwd", os.getcwd())
    project = os.path.basename(cwd)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    title = f"Claude Code: Job Complete"
    body = f"Project: {project}\nTime: {timestamp}"

    # Send notification
    if method == "email":
        send_email(f"[Claude Code] Job Complete - {project}", body)
    elif method == "ntfy":
        send_ntfy(title, body)
    else:
        send_desktop_notification(title, body)

if __name__ == "__main__":
    main()
