AI-Powered Nutrition & Fitness Tracker
A comprehensive Flutter application designed to help users manage their health through smart calorie tracking and AI-driven meal planning. The app integrates with Firebase for data management and uses the Spoonacular API to generate personalized meal suggestions.

 Key Features
AI Meal Generator: Personalized daily meal plans using Spoonacular AI based on user-specific calorie targets.

Smart Dashboard: Real-time tracking of Calories, Macros (Protein, Carbs, Fats), and daily streaks.

Progress Analytics: Interactive weight tracking charts with target weight estimation and 10-day averages.

Personalized Profile: Dynamic calorie goal calculation based on user activity level, age, weight, and height.

Cloud Integration: Secure authentication and real-time data sync using Google Firebase.

Tech Stack
Frontend: Flutter (Dart)

Backend: Firebase Auth, Firestore, and Storage.

APIs: Spoonacular API (for AI meal generation).

Charts: fl_chart for data visualization.

State Management: StatefulWidgets with optimized UI logic
)

Installation & Setup
Clone the repository:

Bash

git clone git clone https://github.com/heb0x/AI_Dietician.git
Install dependencies:

Bash

flutter pub get
Firebase Setup:

Create a Firebase project.

Add your google-services.json
API Key:

Get a free API key from Spoonacular.

Add it to your API service file.

 Responsive Design
The app is fully responsive, optimized for various screen sizes using MediaQuery, Wrap, and FittedBox widgets to ensure a seamless experience on both Android and iOS devices.
