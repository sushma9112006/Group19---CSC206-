Group 19
CSC 206 Source Codes

Project Title
IMEI Track

About the project
This project is a mobile and backend based system for device registration and IMEI tracking. It allows a user to verify their phone number using OTP, register their device, link with friends, flag a lost phone, unflag it later, and detect suspicious devices when the IMEI TAC number does not match the expected device details.

The project has two main parts.
Flutter app in the folder `imei_app`
Node.js backend in the folder `backend`

Database used
PostgreSQL

Important note
The backend file already contains the PostgreSQL queries used in the project. A separate file named `database_setup.sql` is included in this submission so that the required tables can be created before starting the server.

Backend configuration used in this project
Database name: `imei_db`
User: `postgres`
Host: `localhost`
Port: `3000`

If your PostgreSQL setup uses a different password or port, please update the values inside `backend/server.js`.

How to run the backend
1. Open PostgreSQL and create a database named `imei_db`.
2. Run the file `database_setup.sql` in PostgreSQL.
3. Open the `backend` folder in terminal.
4. Install dependencies using `npm install`.
5. Start the server using `node server.js`.
6. The backend runs on port `4000`.

Database files included in this submission
`database_setup.sql`
This file creates the main tables used in the project such as users, otp requests, devices, friend links, flagged devices, alerts, suspicious devices, lost flag records, and TAC catalog entries.

How to run the Flutter app
1. Open the `imei_app` folder.
2. Run `flutter pub get`.
3. Connect an Android device or start an emulator.
4. Run the app using `flutter run`.

Main features
Phone number verification using OTP
Automatic device detail loading
IMEI extraction using OCR from screenshot
Device registration
Friend linking with OTP verification
Custom friend names
Default friend names like Friend 1, Friend 2 when no name is given
Lost phone flag and unflag options
Suspicious device detection
Alert generation for original users when similar suspicious devices are found

Current project structure
`backend`
Contains Node.js server code, package.json, and package-lock.json

`imei_app`
Contains Flutter source code and project files

Files included in this submission
Backend source code
Flutter source code
Project configuration files
PostgreSQL database setup file

Prepared by
Group 19
