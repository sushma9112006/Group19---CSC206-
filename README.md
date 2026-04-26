# IMEI Track

## Note on Project Structure

The project is divided into three major components:

- **Flutter Mobile App (`imei_app/`)** → User interaction layer  
- **Node.js Backend (`backend/`)** → Core logic and APIs  
- **PostgreSQL Database (`database_setup.sql`)** → Persistent storage  

All components must run together for the system to function correctly.

---

## Overview

**IMEI Track** is a full-stack system designed to improve **mobile device security and traceability**.

The system allows users to:
- Register devices securely  
- Report lost phones  
- Detect suspicious or cloned devices  

### Core Idea (Analogy)

Think of this system like a **digital police station for phones**:
- OTP → verifies identity  
- Device registration → records phone identity  
- TAC + hardware check → validates authenticity  
- Alerts → warn about duplicate or suspicious devices  

---

## System Architecture

[ User ] ↓ [ Flutter App ]        → Frontend (UI) ↓ [ Node.js Backend ]    → Business logic & APIs ↓ [ PostgreSQL DB ]      → Data storage

---

## Technologies Used

| Layer      | Technology            | Purpose                          |
|------------|----------------------|----------------------------------|
| Frontend   | Flutter + Dart       | Mobile application UI            |
| Backend    | Node.js + Express    | API and core logic               |
| Database   | PostgreSQL           | Structured data storage          |
| OCR        | Google ML Kit        | IMEI extraction from images      |
| Storage    | Shared Preferences   | Local device storage             |
| Networking | HTTP APIs            | Communication between layers     |

---

## Project Modules

### Mobile Application (Flutter)

- OTP-based login  
- Device registration  
- OCR-based IMEI extraction  
- Friend linking  
- Lost device flagging  
- Alert viewing  

### Backend Server (Node.js + Express)

- OTP generation and verification  
- Device validation logic  
- TAC matching  
- Suspicious device detection  
- Alert generation  
- Database communication  

### Database (PostgreSQL)

| Table Name          | Purpose                     |
|--------------------|-----------------------------|
| users              | User accounts               |
| otp_requests       | OTP tracking                |
| devices            | Registered devices          |
| friend_links       | User relationships          |
| lost_flags         | Lost device records         |
| alerts             | Notifications               |
| suspicious_devices | Suspicious entries          |
| tac_catalog        | IMEI TAC database           |

---

## Key Features

### Authentication
- OTP-based login  

### Device Handling
- Automatic device info collection  
- OCR-based IMEI extraction  

### Social Layer
- Friend linking via OTP  
- Custom and editable names  

### Security Features
- Lost phone flagging  
- TAC-based validation  
- Suspicious device detection  

### Alerts
- Notifications for suspicious activity  

---

## Project Structure

project-root/ │ ├── backend/ │   ├── server.js │   ├── package.json │ ├── imei_app/ │   └── Flutter source code │ └── database_setup.sql

---

## Setup Guide

### Install Requirements
- Flutter SDK  
- Android Studio  
- Node.js  
- PostgreSQL  

---

### Setup Database

CREATE DATABASE imei_db;

Run:

database_setup.sql

---

### Backend Setup

cd backend npm install node server.js

---

### Flutter Setup

cd imei_app flutter pub get flutter run

---

### Backend URL

- Emulator: `http://10.0.2.2:4000`  
- Real Device: `http://<your-ip>:4000`  

---

## Build APK

flutter clean flutter pub get flutter build apk

---

## Testing Flow

1. Start backend  
2. Open app  

Test:
- OTP login  
- Device registration  
- OCR extraction  
- Friend linking  
- Lost device flag  
- Alerts  

---

## System Workflow

1. User logs in  
2. Device info collected  
3. IMEI extracted  
4. Device registered  
5. Backend validates  
6. Suspicious detection  
7. Alerts generated  

---

## Important Notes

- Backend must run first  
- Database must be initialized  
- Correct `baseUrl` required  

---

## Conclusion

This project integrates:
- Mobile app  
- Backend system  
- Database  

Key features:
- OTP authentication  
- Device verification  
- OCR-based IMEI extraction  
- Security alert system  

---

## Contributors

**Group 19**


---
