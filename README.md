# SycX: AI-Powered Summarization System for University Learning

**SycX** is an AI-driven educational platform that simplifies complex academic content into clear, concise summaries. Designed to enhance the learning experience for university students, SycX employs advanced AI and NLP technologies to transform how students interact with their study materials.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setting Up the Flutter App](#setting-up-the-flutter-app)
  - [Setting Up the Flask API](#setting-up-the-flask-api)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Overview

SycX is designed to help university students manage their academic workload by condensing lecture notes, textbooks, and other academic materials into concise summaries. The platform integrates visual aids to enhance comprehension and retention and adapts to individual learning styles based on user feedback.

## Project Structure

The project is divided into two main parts:

```bash
SycX/
│
├── sycx_flutter_app/         # Folder for the Flutter mobile application
│   ├── lib/                  # Contains the main Flutter code
│   ├── assets/               # Images, fonts, etc.
│   ├── android/              # Android specific files
│   ├── ios/                  # iOS specific files
│   └── pubspec.yaml          # Flutter dependencies and metadata

├── venv/
├── .env
├── .gitignore
├── API-DOCUMENTATION.md
├── app.py
├── CONTRIBUTING
├── LICENSE
├── Procfile
├── README.md
└── requirements.txt
```

## Features

- AI-Powered Summarization: Uses advanced AI and NLP algorithms to create concise summaries from academic texts.
- Visual Enhancements: Incorporates visual aids such as diagrams and charts to improve comprehension.
- Feedback Loop: Continuously improves the summarization quality based on user feedback.
- Cross-Platform Availability: Available on both Android and iOS platforms.
- Secure Data Handling: Ensures user data privacy and security with robust encryption and compliance with regulations.

## Getting Started

### Prerequisites

- Flutter SDK: Install Flutter
- Python 3.x: Install Python
- Virtual Environment: (Recommended) Create a virtual environment

### Setting Up the Flutter App
Clone the repository:

```bash
git clone https://github.com/your-repo/sycx.git
cd sycx/sycx_flutter_app
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the app on your device:

```bash
flutter run
```

Detailed SycX Flutter App documentation can be found in the [SycX DOCUMENTATION](sycx_flutter_app/README.md).

### Setting Up the Flask API
Navigate to the Flask API directory:

```bash
cd sycx
```

Create and activate a virtual environment:

```bash
python -m venv venv
.\venv\Scripts\Activate
```

Update pip:

```bash
python.exe -m pip install --upgrade pip
```

Install the required Python packages:

```bash
pip install --timeout 1800 --retries 10 -r requirements.txt
```

Run the Flask server:

```bash
python app.py

## The API will be available at http://localhost:5000.
```

## Usage

- Upload Documents: Upload your academic materials via the Flutter app.
- Generate Summaries: Receive concise, AI-generated summaries of your documents.
- Provide Feedback: Rate the summaries and provide feedback to help improve the AI model.
- Access Enhanced Content: View summaries with integrated visual aids for better understanding.

## API Documentation

The Flask API includes the following endpoints:

- POST /upload: Upload documents for summarization.
- GET /summary: Retrieve the summary of an uploaded document.
- POST /feedback: Submit feedback on the generated summaries.

Detailed API documentation can be found in the [API DOCUMENTATION](API-DOCUMENTATION.md).

## Contributing
We welcome contributions from the community! Please follow the steps below to contribute:

- Fork the repository on GitHub.
- Create a new branch with a descriptive name for your feature or bugfix.
- Commit your changes and push them to your fork.
- Submit a pull request to the main repository.
- Before submitting, make sure to check out our [CONTRIBUTING](CONTRIBUTING.md) file for more details.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Contact
For any questions or issues, please contact:

- Project Lead: Don Artkins
- Email: opiyodon9@gmail.com
- GitHub: https://github.com/opiyodon
- Whatsapp: https://wa.me/254714230692
- Support Team: info.sycx.ke@gmail.com