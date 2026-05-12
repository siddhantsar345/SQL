# Email Imports 
import smtplib 
from email.mime.multipart import MIMEMultipart 
from email.mime.text import MIMEText 
from email.mime.base import MIMEBase 
from email import encoders 
import json
import os
import datetime as dt

# Google API Imports
from oauth2client.service_account import ServiceAccountCredentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# --- CONFIGURATION ---
PATH = '/home/saksham.chaba/MinutesPOPrioritization/output_files/'  # Ensure trailing slash
CREDENTIALS_FILE = 'credentials.json' # Path to your service account json
EMAIL_CONFIG_FILE = 'email_config.json'
DRIVE_FOLDER_ID = '1hYR7LzaN3hrSNWThCrJ92Y_zVofHvihw' # The folder ID from your code

# List of your 2 CSV filenames (Must exist in PATH)
FILES_TO_PROCESS = [
    "po_fsn_file.csv", 
    "po_ranking_file.csv",
    "vendor_ranking_file.csv" 
]

# --- SETUP DATE & CONFIG ---
date_val = str(dt.date.today())
today_date = dt.datetime.strftime(dt.date.today(), "%Y%m%d")

try:
    with open(os.path.join(PATH, EMAIL_CONFIG_FILE)) as f:
        email_config = json.load(f)
except FileNotFoundError:
    print(f"Error: {EMAIL_CONFIG_FILE} not found at {PATH}")
    exit()

fromaddr = email_config["default"]["from"]
base_sent = email_config["default"]["to_addr"]

# --- AUTHENTICATE GOOGLE DRIVE ---
scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
creds_path = os.path.join(PATH, CREDENTIALS_FILE)
creds = ServiceAccountCredentials.from_json_keyfile_name(creds_path, scope)
service = build('drive', 'v3', credentials=creds)

# --- UPLOAD FILES & PREPARE EMAIL ---
msg = MIMEMultipart('alternative')
msg['From'] = fromaddr
msg['To'] = ", ".join(base_sent)
msg['Subject'] = "Hyperlocal PO Prioritization Email : " + date_val

# Dictionary to store file links for the HTML body
uploaded_links = {}

# Process each file (Upload + Attach)
for filename in FILES_TO_PROCESS:
    file_path = os.path.join(PATH, filename)
    
    if not os.path.exists(file_path):
        print(f"Warning: {filename} not found at {file_path}, skipping.")
        continue

    # 1. UPLOAD TO DRIVE
    print(f"Uploading {filename}...")
    mime_type = 'text/csv'
    # Adding date to drive filename to keep history
    drive_filename = f"{os.path.splitext(filename)[0]}_{today_date}.csv"
    
    file_metadata = {
        'name': drive_filename,
        'parents': [DRIVE_FOLDER_ID]
    }
    
    media = MediaFileUpload(file_path, mimetype=mime_type)
    file_drive = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id,name,webViewLink',
        supportsAllDrives=True
    ).execute()
    
    # Store link for HTML
    uploaded_links[filename] = file_drive.get('webViewLink')

    # 2. ATTACH TO EMAIL
    print(f"Attaching {filename}...")
    try:
        with open(file_path, "rb") as attachment:
            p = MIMEBase('application', 'octet-stream')
            p.set_payload(attachment.read())
            encoders.encode_base64(p)
            p.add_header('Content-Disposition', f"attachment; filename= {filename}")
            msg.attach(p)
    except Exception as e:
        print(f"Failed to attach {filename}: {e}")

# --- BUILD HTML BODY ---
# Generate list items for the links dynamically
links_html = ""
for fname, link in uploaded_links.items():
    links_html += f'<li>{fname}: <a href="{link}">View on Drive</a></li>'

body = f"""
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">

<p>Hello Team,</p>

<p>This is an automated email for SH level PO prioritization for Hyperlocal.</p>

<p>Two types of ranks have been created for PO prioritization:
<ul>
    <li><strong>Rank 1:</strong> Based on count of FSNs less than 1, 3, 6 DOH at SH level</li>
    <li><strong>Rank 2:</strong> Based on GMV share of FSNs less than 1, 3, 6 DOH at SH level</li>
</ul>
</p>
<p>
PO_fsn_file is also available to provide fsn level insights for the PO's with an additional rebalance flag so as to indicate the FSN's that need to be rebalanced among darkstores.</p>

<h3>PO Prioritization at SH_P0 level - {date_val}</h3>

<p><strong>Drive Links:</strong></p>
<ul>
    {links_html}
</ul>

<p>Please schedule Unscheduled POs and advance Schedules of highly prioritized POs to protect Instock.</p>

<br>
<p style="font-size: 12px; color: #888;">Automated Notification</p>

</body>
</html>
"""

msg.attach(MIMEText(body, 'html'))


# --- SEND EMAIL ---
# Using Localhost SMTP (No password required)
try:
    s = smtplib.SMTP("127.0.0.1")
    # Note: sendmail expects a list for recipients, not a string, but msg['To'] needs a string header
    s.sendmail(fromaddr, base_sent, msg.as_string()) 
    s.quit()
    print("Email sent successfully.")
except Exception as e:
    print(f"Error sending email: {e}")