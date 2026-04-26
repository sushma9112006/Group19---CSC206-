
# IMEI Track

## Note on Project Structure

The project has 3 main parts:

- **Flutter App (`imei_app/`)** → What user sees  
- **Backend (`backend/`)** → Logic + APIs  
- **Database (`PostgreSQL`)** → Stores everything  

All three must run together.

---

## Overview

IMEI Track helps:

- Register devices  
- Report lost phones  
- Detect fake/cloned devices  

### Simple Idea

Like a **police system for phones**:

- OTP → verifies user  
- IMEI → identifies phone  
- TAC → checks if phone is real  
- Alerts → warns if duplicate  

---

## System Architecture

User → Flutter App → Node.js Backend → PostgreSQL

---

## Technologies Used

| Layer    | Tech               |
|----------|--------------------|
| Frontend | Flutter            |
| Backend  | Node.js + Express  |
| DB       | PostgreSQL         |
| OCR      | Google ML Kit      |

---

# COMPLETE SETUP 

---

## Step 1: Install Software

Install:

- Flutter → https://docs.flutter.dev/get-started/install  
- Android Studio  
- Node.js → https://nodejs.org  
- PostgreSQL  

---

## Step 2: Setup Database 

### 2.1 Open PostgreSQL

- Open **pgAdmin** or terminal

---

### 2.2 Create Database

Run:

CREATE DATABASE imei_db;

---

### 2.3 Run SQL File

- Open Query Tool  
- Open file:

database_setup.sql

- Click **Run**

✔ This creates all tables automatically

---

## Step 3: Setup Backend

### 3.1 Go to backend folder

**Windows**

cd backend

**Linux/macOS**

cd backend

---

### 3.2 Install dependencies

npm install

---

### 3.3 Check database config

Open:

backend/server.js

Verify:

database: 'imei_db' user: 'postgres' host: 'localhost' port: 5432

---

### 3.4 Start backend

node server.js

✔ You should see:

Server running on port 4000

---

## Step 4: Setup Flutter App

### 4.1 Go to app folder

cd imei_app

---

### 4.2 Install dependencies

flutter pub get

---

### 4.3 Set backend URL 

Open:

imei_app/lib/main.dart

Find:

baseUrl

Replace with:

**Emulator**

http://10.0.2.2:4000

**Real Phone**

http://<your-laptop-ip>:4000

---

## Step 5: Run App

### Option 1: Real Phone

- Enable Developer Options  
- Enable USB Debugging  

Run:

flutter run

---

### Option 2: Emulator

- Start emulator from Android Studio  

Run:

flutter run

---

## Step 6: Build APK
Run these commands in terminal, after opening the folder having the dart code:
- flutter clean 
- flutter pub get 
- flutter build apk

APK location:

build/app/outputs/flutter-apk/

Install this APK on mobile

---

#  TESTING 


---

### 1. Start backend

node server.js

---

### 2. Open app

---

### 3. Test Login

- Enter phone number  
- Enter OTP  

---

### 4. Register Device

- Allow permissions  
- Upload screenshot  
- Check IMEI auto-detection  

---

### 5. Friend Linking

- Add friend via OTP  
- Try:
  - With name  
  - Without name  

---

### 6. Edit Names

- Change friend names  

---

### 7. Lost Device

- Flag device  
- Unflag device  

---

### 8. Suspicious Detection

- Use mismatched device + IMEI  

---

### 9. Alerts

- Check if alert appears  

---

# SYSTEM WORKFLOW

1. User logs in  
2. Device info collected  
3. IMEI extracted  
4. Backend verifies TAC  
5. If mismatch → suspicious  
6. Alert generated  

---

## Important Notes

- Backend must run first  
- DB must be created first  
- Correct `baseUrl` is critical  
- Internet required  

---

## Conclusion

This system combines:

- Mobile App  
- Backend  
- Database  

To create a **device security + tracking system**

---

## Contributors

Group 19


---
