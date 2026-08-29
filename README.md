# ForgeAI - Frontend

This is the Flutter frontend for the ForgeAI application, an AI-powered website builder. It allows users to generate fully functional, responsive websites using natural language prompts and interact with the AI to refine their designs in a live preview environment.

## Architecture

ForgeAI consists of a decoupled frontend and backend:
- **Frontend**: Built with Flutter Web. Responsible for the UI, interacting with the backend REST APIs, and rendering the generated website within an `<iframe>` for live preview and real-time editing.
- **Backend**: Built with Java Spring Boot. Handles orchestration, prompting the OpenRouter/LLM APIs, and serving the generated static files.

### Project Structure

The project follows a standard feature-based directory structure inside `lib/`:

#### `lib/screens/`
- **`home_screen.dart`**: The main entry point for users. Contains the form to input project details (name, category, theme).
- **`preview_screen.dart`**: The core workspace. It displays the AI chat on the left and a live `<iframe>` preview of the generated website on the right.

#### `lib/services/`
- **`api_service.dart`**: Singleton service handling low-level HTTP requests using `http` package. Manages JSON parsing and error handling.
- **`forge_service.dart`**: A wrapper service specifically for generation-related endpoints, mapping responses to strongly-typed models.

#### `lib/widgets/`
- **`web_preview/`**: Contains the platform-specific implementations for the web view. Since this is a Flutter Web app, it uses `dart:ui_web` to render an `<iframe>`.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.19 or higher)
- Chrome Browser (for debugging web)
- Running Backend server (ForgeAI Backend)

### Local Development Setup
1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d chrome
   ```
4. Ensure the backend is running locally at `http://localhost:8080` (or configure the base URL in `api_config.dart` accordingly).

### Docker Deployment

To easily spin up the frontend using Docker and Nginx:

1. Build the Flutter web bundle locally first:
   ```bash
   flutter build web
   ```
2. Build the Docker image:
   ```bash
   docker build -t forgeai-frontend .
   ```
3. Run the Docker container:
   ```bash
   docker run -d -p 3000:80 --name forgeai-frontend forgeai-frontend
   ```
4. The application will be accessible at `http://localhost:3000`.

## Key Features
- **Obsidian Dark Theme**: Configured globally in `main.dart`, featuring a developer-grade high-contrast dark mode with neon accents.
- **Skeleton Loading**: Rich animated skeleton loaders give users a sense of structure while their website is being forged.
- **Live Preview**: Uses a split-screen layout to allow real-time iteration on the generated website via AI chat.
- **Job Polling**: Initiates generation jobs and polls the backend for asynchronous completion.
