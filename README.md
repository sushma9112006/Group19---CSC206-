# Group 19
## CSC 206 Project

# IMEI Track

## Project Overview

IMEI Track is a mobile and backend based project developed for device registration, lost phone reporting, and suspicious device detection. The main purpose of this project is to improve device tracking and help identify possible misuse of IMEI details. The system allows users to verify their number using OTP, register their device, connect with friends, flag a lost phone, and detect suspicious devices using TAC and device property comparison.

This project has three major parts.

The Flutter mobile application

The Node.js backend server

The PostgreSQL database

## Technologies Used

Flutter

Dart

Node.js

Express.js

PostgreSQL

Google ML Kit OCR

Shared Preferences

HTTP API communication

## Modules in the Project

### Mobile Application

The Flutter app is the user side of the project. It is used for OTP verification, device registration, OCR based IMEI reading, friend linking, lost phone flagging, unflagging, and unregistering a device.

### Backend Server

The backend is developed using Node.js and Express. It handles OTP generation and verification, device registration logic, friend connection logic, suspicious device checks, alert creation, and all database operations.

### Database

PostgreSQL is used to store user data, OTP requests, device details, friend links, lost flag records, suspicious devices, alerts, and TAC catalog data.

## Main Features

User login using OTP verification

Automatic device details collection

OCR based IMEI extraction from uploaded screenshots

Device registration

Friend linking through OTP verification

Option to assign a custom name to a friend

Default friend names like Friend 1, Friend 2 when no custom name is given

Option to edit friend names later

Option to flag a friend’s device as lost

Option to unflag a device later

Suspicious device detection when TAC does not match the expected device model

Alert generation for the original user when a suspicious matching device is found

Confirmation dialog before unregistering a device

IMEI entry only through OCR upload and not by manual typing

## Project Folder Structure

### `backend`

Contains the Node.js backend files such as `server.js`, `package.json`, and `package-lock.json`.

### `imei_app`

Contains the Flutter application source code and project configuration.

### `database_setup.sql`

Contains the SQL required to create the database tables used in the project.

## How to Use the Source Code

The source code is divided into backend, mobile application, and database setup. To run the complete project, the database should be set up first, then the backend server should be started, and then the Flutter mobile app should be run.

## Step by Step Setup Instructions

### Step 1: Install the required software

Make sure the following software is installed in your system.

Flutter SDK

Android Studio

Node.js

PostgreSQL

A code editor such as VS Code

### Step 2: Set up PostgreSQL database

1. Open PostgreSQL or pgAdmin.
2. Create a new database named `imei_db`.
3. Open the SQL query tool.
4. Run the file named `database_setup.sql`.

This will create the required tables such as:

`users`

`otp_requests`

`devices`

`friend_links`

`flagged_devices`

`lost_flags`

`alerts`

`suspicious_devices`

`tac_catalog`

### Step 3: Check backend database configuration

1. Open the `backend` folder.
2. Open `server.js`.
3. Check the database configuration values and update them if needed according to your system.

The backend in this project uses the following default values:

Database name: `imei_db`

User: `postgres`

Host: `localhost`

Port: `3000`

### Step 4: Install backend dependencies

Open terminal in the `backend` folder and run:

```bash
npm install

#### Step 5: Start the backend server
In the same backend folder terminal, run:
``` bash
node server.js
If everything is correct, the backend server will start and run on port 4000.

### Step 6: Set the backend URL in Flutter app
1. Open the Flutter project inside the imei_app folder.
2. Open lib/main.dart.
3. Check the baseUrl value.
3. Make sure it points to the IP address and port where the backend is running.
If you are testing on a real Android phone, use your computer’s local network IP address.

## Step 7: Install Flutter dependencies

Open terminal in the `imei_app` folder and run:

```bash
flutter pub get
This downloads all Flutter packages used in the project.

## Step 8: Run the Flutter app

Connect an Android phone using USB debugging or open an Android emulator.

In the `imei_app` folder terminal, run:

```bash
flutter run
This will launch the application.

## How to Build the App

To create a release build of the Flutter application, follow these steps:

Open terminal in the `imei_app` folder.

Run:

```bash
flutter clean
flutter pub get
flutter build apk
After the build completes, the APK file can usually be found in the Flutter build output folder.

## How to Test the Project

Make sure PostgreSQL is running.

Make sure the `imei_db` database is created.

Make sure `database_setup.sql` has been executed.

Start the backend server using:

```bash
node server.js

Install the generated APK on an Android device.

Open the application on the Android device.

Enter a phone number and request OTP.

Verify the OTP.

Register the device.

Check whether device details are fetched properly.

Upload a screenshot to extract the IMEI using OCR.

Link a friend using OTP.

Give a friend name or leave it blank to check default naming.

Try editing the friend name later from the friends section.

Try flagging and unflagging a device.

Try testing suspicious device detection using TAC mismatch and matching hardware details.

### TAC Catalog Included in the Database Setup
The database_setup.sql file also contains sample TAC entries for testing the suspicious device detection logic. These entries include common brands and models such as Apple, Samsung, Google, Xiaomi, OnePlus, and Nothing.

One of the important Samsung entries included is:

35081449 Samsung Galaxy M1565B

This has been added specifically for correct TAC and model matching in the project.

## How the System Works
First, the user verifies their phone number through OTP. After successful verification, the user registers their device. The app collects device related details and extracts the IMEI through OCR from an uploaded screenshot.

Once the device is registered, the user can connect with friends using OTP verification. After verification, the app asks the user to provide a name for the friend. If the user does not provide a name, the system assigns a default sequential name such as Friend 1 or Friend 2. The name can also be edited later from the My Friends section.

The user can flag a lost phone and unflag it when needed. The backend checks whether a newly registered device is suspicious by comparing the TAC number and device details. If a suspicious device with matching characteristics is found, an alert is created for the original concerned user.

### Important Notes
The backend must be started before running the mobile app.

The database must be created before starting the backend.

The Flutter app should use the correct backend IP address in the baseUrl.

The IMEI is intended to be captured using OCR upload.

The unregister feature shows a confirmation dialog before removing the device.

The app may need device permissions depending on the Android device and OCR use.

## Conclusion
IMEI Track is a complete project that combines mobile development, backend development, and database management. It demonstrates how OTP verification, device registration, OCR based IMEI reading, friend linking, lost phone reporting, and suspicious device detection can be integrated into one system.

Prepared By
Group 19
