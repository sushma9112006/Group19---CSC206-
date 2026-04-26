---

IMEI Track

Note on Project Structure

The project is divided into three major components:

Flutter Mobile App (imei_app/) → User interaction layer

Node.js Backend (backend/) → Core logic and APIs

PostgreSQL Database (database_setup.sql) → Persistent storage


All components must run together for the system to function correctly.


---

Overview

IMEI Track is a full-stack system designed to improve mobile device security and traceability.

The system allows users to:

Register devices securely

Report lost phones

Detect suspicious or cloned devices


Core Idea (Analogy)

Think of this system like a digital police station for phones:

OTP → verifies identity

Device registration → records phone identity

TAC + hardware check → validates authenticity

Alerts → warn about duplicate or suspicious devices



---

System Architecture

The system follows a 3-tier architecture:

[ User ]
   ↓
[ Flutter App ]        → Frontend (UI)
   ↓
[ Node.js Backend ]    → Business logic & APIs
   ↓
[ PostgreSQL DB ]      → Data storage


---

Technologies Used

Layer	Technology	Purpose

Frontend	Flutter + Dart	Mobile application UI
Backend	Node.js + Express	API and core logic
Database	PostgreSQL	Structured data storage
OCR	Google ML Kit	IMEI extraction from images
Storage	Shared Preferences	Local device storage
Networking	HTTP APIs	Communication between layers



---

Project Modules

1. Mobile Application (Flutter)

Handles all user interactions:

OTP-based login

Device registration

OCR-based IMEI extraction

Friend linking

Lost device flagging

Alert viewing



---

2. Backend Server (Node.js + Express)

Acts as the system brain:

OTP generation and verification

Device validation logic

TAC matching

Suspicious device detection

Alert generation

Database communication



---

3. Database (PostgreSQL)

Stores system data:

Table Name	Purpose

users	User accounts
otp_requests	OTP tracking
devices	Registered devices
friend_links	User relationships
lost_flags	Lost device records
alerts	Notifications
suspicious_devices	Suspicious device entries
tac_catalog	IMEI TAC reference database



---

Key Features

Authentication

OTP-based login (simple and secure)


Device Handling

Automatic device information collection

OCR-based IMEI extraction (no manual input)


Social Layer

Friend linking via OTP

Custom and default naming

Editable names


Security Features

Lost phone flagging / unflagging

TAC-based validation

Suspicious device detection


Alerts

Notifications for duplicate or suspicious device activity



---

Project Structure

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

Setup Guide (Windows / Linux / macOS)

1. Install Required Software

Flutter SDK

Android Studio

Node.js

PostgreSQL

VS Code (or any editor)



---

2. Setup Database

1. Open PostgreSQL / pgAdmin


2. Create database:



imei_db

3. Run:



database_setup.sql


---

3. Configure Backend

Go to backend/server.js and verify:

database: imei_db
user: postgres
host: localhost
port: 3000

Modify only if necessary.


---

4. Install Backend Dependencies

Windows (PowerShell / CMD)

cd backend
npm install

Linux / macOS

cd backend
npm install


---

5. Start Backend Server

Windows

node server.js

Linux / macOS

node server.js

Expected:

Server running on port 4000


---

6. Configure Flutter Backend URL

Edit:

imei_app/lib/main.dart

Set baseUrl:

Emulator:


http://10.0.2.2:4000

Real Device:


http://<your-laptop-ip>:4000


---

7. Install Flutter Dependencies

Windows

cd imei_app
flutter pub get

Linux / macOS

cd imei_app
flutter pub get


---

8. Run the App

USB Device

flutter run

Emulator

Start emulator, then:

flutter run


---

Build APK

flutter clean
flutter pub get
flutter build apk

APK location:

build/app/outputs/flutter-apk/


---

Testing Guide

Step-by-step flow:

1. Start backend


2. Open app



Test Features

Authentication

Enter phone number

Verify OTP


Device Registration

Auto device info

Upload screenshot → IMEI extraction


Friend Linking

Add friend via OTP

Test naming options


Editing

Modify friend names


Lost Device

Flag / unflag device


Suspicious Detection

Test mismatched TAC


Alerts

Verify alert generation



---

TAC Catalog

Includes sample entries:

Apple

Samsung

Xiaomi

OnePlus

Nothing


Example:

35081449 → Samsung Galaxy M1565B


---

System Workflow

1. User logs in via OTP


2. Device info collected


3. IMEI extracted via OCR


4. Device registered


5. Backend checks:

TAC validity

Device consistency



6. If mismatch → marked suspicious


7. Alerts generated




---

Important Notes

Backend must be running before app

Database must be initialized first

Correct baseUrl is critical

OCR requires permissions

Unregister actions include confirmation



---

Conclusion

This project demonstrates integration of:

Mobile frontend

Backend logic system

Database storage


Key concepts implemented:

OTP authentication

Device fingerprinting

OCR-based IMEI extraction

Social trust network

Security alert system


Outcome:
A practical system for detecting and managing device authenticity and misuse.


---

Contributors

Group 19
