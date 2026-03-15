Universal Science Academy Management System
A comprehensive, cross-platform mobile application built with Flutter and Firebase to digitize and streamline the complete administrative and academic operations of an educational institution.

About The Project
The Universal Science Academy Management System is a modern, high-level solution designed to replace traditional, paper-based record-keeping. It provides a real-time, secure, and intuitive digital ecosystem for both the academy's administration and its teaching staff, enhancing productivity and eliminating manual errors.

This application serves as a centralized portal for managing students, teachers, classes, fees, attendance, and academic performance, complete with a powerful automated reporting system.

Developed by: Atif Mubeen
Features
The application is divided into two primary user roles, each with a dedicated and feature-rich panel.

👨‍💼 Admin Panel
The central command center for the academy, providing full control over all operations.

📊 Interactive Dashboard: A real-time overview of key academy statistics (total students, teachers, classes, and today's fee collection). Cards are clickable, providing direct navigation to respective modules.

🧑‍🎓 Complete Student Management: A centralized hub to view all students. Includes powerful search by name, filter by class, and full CRUD (Create, Read, Update, Delete) capabilities for every student record.

👩‍🏫 Professional Teacher Management: A dedicated module for managing faculty. Features include case-insensitive search and full control to add, edit, and delete teacher profiles.

🏫 Dynamic Class & Subject Management: Admins can create classes with defined monthly fees. A detailed view for each class allows for managing assigned subjects and enrolled students, with intuitive swipe-to-delete and edit functionalities.

💰 Advanced Fee & Financial Reporting:

Quick Fee Entry: A powerful shortcut to record a fee payment for any student in seconds.

Detailed Fee Reports: A dynamic reporting system with a month-selector to view total and class-wise fee collections.

Student Fee Status: Admins can drill down to view a list of paid and unpaid students for any class in any given month.

📝 Automated Academic Reporting: A high-level system that completely automates report card generation.

The admin can generate consolidated reports for "Monthly Tests" or the "Overall Test Session".

The system automatically calculates total marks, obtained marks, and percentages for every student across all subjects and ranks them accordingly in a clean, "Excel-style" data table.

Reports can be exported as a PDF for sharing or printing.

👩‍🏫 Teacher Panel
A focused and efficient interface designed to empower teachers with the tools they need.

🖥️ Personalized Dashboard: A clean home screen displaying a list of all subjects assigned to the logged-in teacher, with a personalized welcome message.

✅ Smart Attendance System:

Teachers can mark daily attendance (Present, Absent, Leave) for their classes.

The system prevents duplicate entries for the same day and shows a summary report if attendance is already marked.

✍️ Efficient Marks Management:

Teachers can enter marks for both "Monthly Tests" and "Test Session" tests.

They can view a complete history of all tests conducted, edit marks to correct mistakes, or delete entire test records.

➕ Student Enrollment: Teachers are empowered to add new students directly to the classes they teach, streamlining the enrollment process.

✨ Universal Features
🎨 Light & Dark Mode: A beautiful, modern UI with full support for both light and dark themes.

🔒 Secure, Role-Based Authentication: A robust login system that remembers the user's session and directs them to the correct panel based on their role.

🌐 Offline Indicator: A system-wide banner automatically notifies the user if their internet connection is lost.

Technology Stack
Frontend: Flutter

Backend & Database: Google Firebase

Authentication: For secure user management.

Firestore: For real-time data storage.

Getting Started
To get a local copy up and running, follow these simple steps.

Prerequisites
Flutter SDK installed on your machine.

A code editor like VS Code or Android Studio.

A Firebase project set up.

Installation
Clone the repo:

git clone https://github.com/Atiimubeen/universal_science_academy.git

Navigate to the project directory:

cd universal_science_academy

Install packages:

flutter pub get

Setup Firebase:

Follow the instructions to add your firebase_options.dart file using the FlutterFire CLI.

Ensure you have enabled Email/Password Authentication and Firestore Database in your Firebase project console.

Run the app:

flutter run

Project Structure
The project follows a clean, feature-first architecture to ensure scalability and maintainability.

lib/
|-- app/              # Global app settings (theme, colors, widgets)
|-- core/             # Core logic (services, models)
|-- features/         # All feature modules
|   |-- auth/
|   |-- admin_panel/
|   |-- teacher_panel/
|   |-- ...
|-- main.dart         # App entry point
