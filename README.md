Group 19 — CSC 206 Project

IMEI Track


---

1. Project Overview

IMEI Track is a full-stack mobile + backend system designed to:

Register devices securely

Report lost phones

Detect suspicious or cloned devices


Core Idea (Simple Analogy)

Think of this system like a digital police station for phones:

OTP → verifies who you are

Device registration → records your phone identity

TAC + hardware check → verifies if the phone is genuine

Alerts → warns if someone is using a fake/duplicate identity



---

2. System Architecture

The project follows a 3-tier architecture:

[ User ]
   ↓
[ Flutter App ]        → User interaction (frontend)
   ↓
[ Node.js Backend ]    → Logic, validation, APIs
   ↓
[ PostgreSQL DB ]      → Data storage


---

3. Technologies Used

Layer	Technology	Purpose

Frontend	Flutter + Dart	Mobile app UI
Backend	Node.js + Express	API and logic
Database	PostgreSQL	Data storage
OCR	Google ML Kit	Extract IMEI from images
Storage	Shared Preferences	Local app data
Networking	HTTP APIs	App ↔ Server communication



---

4. Project Modules

4.1 Mobile Application (Flutter)

Handles everything the user interacts with:

OTP login

Device registration

OCR IMEI extraction

Friend linking

Lost phone flagging

Viewing alerts



---

4.2 Backend Server (Node.js + Express)

Acts as the brain of the system:

OTP generation & verification

Device validation logic

TAC matching

Suspicious device detection

Alert creation

Database communication



---

4.3 Database (PostgreSQL)

Stores all system data:

Table Name	Purpose

users	User accounts
otp_requests	OTP tracking
devices	Registered devices
friend_links	User connections
lost_flags	Lost device records
alerts	Notifications
suspicious_devices	Detected suspicious entries
tac_catalog	IMEI TAC database



---

5. Key Features

Authentication

OTP-based login (secure and simple)


Device Handling

Automatic device info collection

IMEI extraction using OCR (no manual typing)


Social Layer

Friend linking via OTP

Custom naming + default names

Edit names anytime


Security Features

Lost phone flagging / unflagging

TAC-based verification

Suspicious device detection


Alerts

User notified if a duplicate/suspicious device appears



---

6. Project Folder Structure

project-root/
│
├── backend/
│   ├── server.js
│   ├── package.json
│   └── package-lock.json
│
├── imei_app/
│   └── Flutter source code
│
└── database_setup.sql


---

7. Complete Setup Guide (Step-by-Step)

Step 1: Install Required Software

Install these first:

Flutter SDK

Android Studio

Node.js

PostgreSQL

VS Code (or any editor)



---

Step 2: Setup Database

1. Open PostgreSQL / pgAdmin


2. Create database:



imei_db

3. Open Query Tool


4. Run:



database_setup.sql

This creates all required tables automatically.


---

Step 3: Configure Backend

1. Go to backend/


2. Open server.js


3. Verify database config:



database: imei_db
user: postgres
host: localhost
port: 3000

Modify only if needed.


---

Step 4: Install Backend Dependencies

cd backend
npm install


---

Step 5: Start Backend Server

node server.js

Expected:

Server running on port 4000


---

Step 6: Configure Flutter Backend URL

1. Open:



imei_app/lib/main.dart

2. Find:



baseUrl

3. Set it to:



Emulator:

http://10.0.2.2:4000

Real Phone (same WiFi):

http://<your-laptop-ip>:4000



---

Step 7: Install Flutter Dependencies

cd imei_app
flutter pub get


---

Step 8: Run the App

Option 1: USB Device

Enable Developer Options

Enable USB Debugging


Run:

flutter run


---

Option 2: Emulator

Start emulator from Android Studio

Run:


flutter run


---

8. Build APK (Install on Phone)

flutter clean
flutter pub get
flutter build apk

APK location:

build/app/outputs/flutter-apk/

Install this APK on your phone.


---

9. Testing Guide (Full Flow)

Follow this sequence:

1. Start backend

node server.js

2. Open app

3. Test features step-by-step

Authentication

Enter phone number

Verify OTP


Device Registration

Check auto device info

Upload screenshot → OCR extracts IMEI


Friend Linking

Add friend via OTP

Try:

Custom name

No name → default name



Editing

Change friend names


Lost Device

Flag device

Unflag device


Suspicious Detection

Test mismatched TAC + device details


Alerts

Verify alert creation



---

10. TAC Catalog

The database includes sample TAC entries such as:

Apple

Samsung

Xiaomi

OnePlus

Nothing


Example Entry:

35081449 → Samsung Galaxy M1565B

Used for realistic testing of device validation.


---

11. System Workflow (Simple Explanation)

1. User logs in via OTP


2. App collects device info


3. IMEI extracted using OCR


4. Device is registered


5. Backend checks:

TAC validity

Device consistency



6. If mismatch → marked suspicious


7. Alerts sent to original user




---

12. Important Notes

Backend must be running before app

Database must be set up first

Correct baseUrl is critical

OCR requires permissions

Unregister action shows confirmation



---

13. Conclusion

This project demonstrates how multiple systems work together:

Mobile app (user interaction)

Backend (logic & validation)

Database (persistent storage)


It integrates:

OTP authentication

Device fingerprinting

OCR-based IMEI extraction

Social trust network

Security alert system


Result:
A complete and practical solution for device authenticity and tracking.


---

Prepared By

Group 19
