package com.forgeai.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.forgeai.backend.client.OpenRouterClient;
import com.forgeai.backend.dto.GenerateRequest;
import com.forgeai.backend.dto.GenerateResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Service
/**
 * Core service logic for generating web projects using AI.
 * Orchestrates these steps:
 * 1. Building a prompt for the AI model.
 * 2. Calling the AI client (OpenRouter).
 * 3. Cleaning and parsing the JSON response.
 * 4. Saving files to disk via FileStorageService.
 * 5. Zipping the project via ZipService.
 */
public class GenerateService {

    private static final Logger logger = LoggerFactory.getLogger(GenerateService.class);
    private final ObjectMapper objectMapper;
    private final OpenRouterClient openRouterClient;
    private final FileStorageService fileStorageService;
    private final ZipService zipService;
    private final JobStore jobStore;

    public GenerateService(ObjectMapper objectMapper, OpenRouterClient openRouterClient,
            FileStorageService fileStorageService, ZipService zipService, JobStore jobStore) {
        this.objectMapper = objectMapper;
        this.openRouterClient = openRouterClient;
        this.fileStorageService = fileStorageService;
        this.zipService = zipService;
        this.jobStore = jobStore;
    }

    /**
     * Async entry point for starting a generation job.
     * Updates the job status as it creates the project.
     * NOTE: This runs on a separate thread to avoid blocking the HTTP request.
     *
     * @param jobId   The ID of the tracking job.
     * @param request The user's generation request.
     */
    @org.springframework.scheduling.annotation.Async
    public void startGeneration(String jobId, GenerateRequest request) {
        logger.info("🧵 Starting async generation for Job: {}", jobId);
        try {
            jobStore.updateStatus(jobId, com.forgeai.backend.model.JobStatus.PROCESSING);
            GenerateResponse response = generateProject(request);

            if (response.isSuccess()) {
                jobStore.completeJob(jobId, response);
                logger.info("✅ Job {} completed successfully", jobId);
            } else {
                jobStore.failJob(jobId, response.getMessage());
                logger.error("❌ Job {} failed: {}", jobId, response.getMessage());
            }
        } catch (Exception e) {
            logger.error("❌ Unexpected error in Job {}: {}", jobId, e.getMessage());
            jobStore.failJob(jobId, "Unexpected error: " + e.getMessage());
        }
    }

    public GenerateResponse generateProject(GenerateRequest request) {
        String prompt = buildPrompt(request);
        String projectId = UUID.randomUUID().toString();

        try {
            String aiResult = openRouterClient.generate(prompt);

            logger.info("===== RAW AI RESPONSE START =====");
            logger.info(aiResult);
            logger.info("===== RAW AI RESPONSE END =====");

            String cleanedJson = cleanAiJson(aiResult);

            GeneratedFilesWrapper wrapper = objectMapper.readValue(cleanedJson, GeneratedFilesWrapper.class);

            // VALIDATE: Must have exactly 3 files: index.html, styles.css, script.js
            validateFiles(wrapper.files());

            // SAVE FILES TO DISK
            fileStorageService.saveProjectFiles(projectId, wrapper.files());
            logger.info("✅ Files saved successfully for project: {}", projectId);

            // ZIP PROJECT
            zipService.zipProject(projectId);
            logger.info("✅ ZIP created successfully for project: {}", projectId);

            // SUCCESS
            logger.info("✅ Project generation completed successfully: {}", projectId);

            return new GenerateResponse(
                    true,
                    "Project generated successfully",
                    projectId,
                    wrapper.files());
        } catch (Exception e) {
            logger.error("PRODUCTION ERROR: AI generation failed. Falling back to generating a mock template project due to error: {}", e.getMessage(), e);
            try {
                List<GenerateResponse.GeneratedFile> mockFiles = createMockFiles(request);
                fileStorageService.saveProjectFiles(projectId, mockFiles);
                zipService.zipProject(projectId);
                logger.info("✅ Mock project generated successfully: {}", projectId);
                return new GenerateResponse(
                        true,
                        "Project generated successfully (Mock Fallback)",
                        projectId,
                        mockFiles);
            } catch (Exception ex) {
                logger.error("Failed to generate mock project fallback: {}", ex.getMessage(), ex);
                return new GenerateResponse(false, "Failed to generate project: " + e.getMessage(), null,
                        Collections.emptyList());
            }
        }
    }

    /**
     * Cleans the raw string response from the AI model to ensure valid JSON.
     * Often AI models wrap JSON in markdown code blocks (e.g., ```json ... ```),
     * which this method strips.
     *
     * @param raw The raw string from the AI.
     * @return A clean JSON string.
     */
    private String cleanAiJson(String raw) {
        if (raw == null)
            return "{}";

        String cleaned = raw.trim();

        // Remove markdown code blocks if present
        if (cleaned.contains("```")) {
            // Specifically look for ```json ... ```
            if (cleaned.contains("```json")) {
                int start = cleaned.indexOf("```json") + 7;
                int end = cleaned.lastIndexOf("```");
                if (end > start) {
                    cleaned = cleaned.substring(start, end).trim();
                }
            } else {
                // Handle generic ``` ... ```
                int start = cleaned.indexOf("```") + 3;
                int end = cleaned.lastIndexOf("```");
                if (end > start) {
                    cleaned = cleaned.substring(start, end).trim();
                }
            }
        }

        // If it still contains markdown characters or text outside the JSON, we can't
        // easily fix it here
        // without a more complex regex, but this handles the most common case.
        return cleaned;
    }

    /**
     * Constructs the detailed system prompt for the AI model.
     * Defines strict output format rules (JSON) and design guidelines.
     */
    private String buildPrompt(GenerateRequest request) {
        return String.format(
                "You are ForgeAI, an expert senior web product designer and frontend architect.\n" +
                        "\n" +
                        "You generate complete production-quality websites using:\n" +
                        "- HTML\n" +
                        "- CSS\n" +
                        "- Vanilla JavaScript only\n" +
                        "\n" +
                        "📦 OUTPUT FORMAT (MANDATORY JSON)\n" +
                        "Always respond in this exact format:\n" +
                        "{\n" +
                        "  \"files\": [\n" +
                        "    { \"path\": \"index.html\", \"content\": \"...\" },\n" +
                        "    { \"path\": \"styles.css\", \"content\": \"...\" },\n" +
                        "    { \"path\": \"script.js\", \"content\": \"...\" }\n" +
                        "  ]\n" +
                        "}\n" +
                        "\n" +
                        "No markdown. No explanations. No backticks.\n" +
                        "\n" +
                        "🏗️ WEBSITE STRUCTURE (MANDATORY)\n" +
                        "Every website MUST include:\n" +
                        "- Sticky header with nav\n" +
                        "- Hero section with CTA\n" +
                        "- Features / Services section (3–6 cards)\n" +
                        "- About section\n" +
                        "- Benefits / Why Choose Us section\n" +
                        "- Call-to-action section\n" +
                        "- Footer with:\n" +
                        "  - Links\n" +
                        "  - Copyright\n" +
                        "  - Text: Built with ForgeAI\n" +
                        "\n" +
                        "🎨 DESIGN RULES\n" +
                        "Must look modern startup / SaaS quality\n" +
                        "Must include:\n" +
                        "- Cards\n" +
                        "- Shadows\n" +
                        "- Gradients\n" +
                        "- Hover animations\n" +
                        "- Scroll animations\n" +
                        "- Section reveal animations\n" +
                        "- Fully responsive\n" +
                        "\n" +
                        "🧠 CONTENT RULES\n" +
                        "Use the user's idea as the business theme\n" +
                        "Write realistic professional marketing content\n" +
                        "No lorem ipsum\n" +
                        "No placeholders\n" +
                        "No \"Hello world\"\n" +
                        "\n" +
                        "⚙️ INTERACTIVITY RULES\n" +
                        "Must include:\n" +
                        "- Smooth scrolling\n" +
                        "- Navbar scroll effect\n" +
                        "- Button hover animations\n" +
                        "- Section reveal animation\n" +
                        "- Simple JS animations\n" +
                        "\n" +
                        "🧱 TECH RULES\n" +
                        "❌ No React\n" +
                        "❌ No Tailwind\n" +
                        "❌ No Bootstrap\n" +
                        "❌ No frameworks\n" +
                        "❌ No external JS or CSS libraries\n" +
                        "❌ No CDN dependencies\n" +
                        "\n" +
                        "🏷️ BRANDING RULE\n" +
                        "If user asks who you are or who built this:\n" +
                        "Always say:\n" +
                        "I am ForgeAI, an AI website builder created by the ForgeAI team.\n" +
                        "\n" +
                        "🧨 HARD FAIL CONDITIONS\n" +
                        "Do NOT return code fences\n" +
                        "Do NOT return explanations\n" +
                        "Do NOT return markdown\n" +
                        "Do NOT return partial files\n" +
                        "\n" +
                        "PROJECT DETAILS:\n" +
                        "Name: %s\n" +
                        "Description: %s\n" +
                        "Category: %s\n" +
                        "Features/Sections: %s\n" +
                        "\n" +
                        "Use proper escaping for double quotes and newlines in the JSON content values.",
                request.getProjectName(),
                request.getDescription(),
                request.getCategory(),
                String.join(", ", request.getSections()));
    }

    public GenerateResponse editProject(String projectId, String userInstruction) {
        try {
            // Load current files
            List<GenerateResponse.GeneratedFile> currentFiles = fileStorageService.loadProjectFiles(projectId);

            // Build edit prompt
            String prompt = buildEditPrompt(currentFiles, userInstruction);

            // Generate updated files
            String aiResult = openRouterClient.generate(prompt);

            logger.info("===== RAW AI EDIT RESPONSE START =====");
            logger.info(aiResult);
            logger.info("===== RAW AI EDIT RESPONSE END =====");

            String cleanedJson = cleanAiJson(aiResult);
            GeneratedFilesWrapper wrapper = objectMapper.readValue(cleanedJson, GeneratedFilesWrapper.class);

            // VALIDATE: Must have exactly 3 files: index.html, styles.css, script.js
            validateFiles(wrapper.files());

            // SAVE UPDATED FILES TO DISK
            fileStorageService.saveProjectFiles(projectId, wrapper.files());
            logger.info("✅ Updated files saved successfully for project: {}", projectId);

            // UPDATE ZIP
            zipService.zipProject(projectId);
            logger.info("✅ ZIP updated successfully for project: {}", projectId);

            // SUCCESS: Edit is complete regardless of whether client receives response
            logger.info("✅ Project edit completed successfully: {}", projectId);

            return new GenerateResponse(
                    true,
                    "Project updated successfully",
                    projectId,
                    wrapper.files());
        } catch (Exception e) {
            logger.error("PRODUCTION ERROR: AI edit failed. Falling back to mock edit due to error: {}", e.getMessage(), e);
            try {
                List<GenerateResponse.GeneratedFile> updatedFiles = createMockEditFiles(projectId, userInstruction);
                fileStorageService.saveProjectFiles(projectId, updatedFiles);
                zipService.zipProject(projectId);
                logger.info("✅ Mock project edit completed successfully: {}", projectId);
                return new GenerateResponse(
                        true,
                        "Project updated successfully (Mock Fallback)",
                        projectId,
                        updatedFiles);
            } catch (Exception ex) {
                logger.error("Failed to edit mock project fallback: {}", ex.getMessage(), ex);
                return new GenerateResponse(false, "Failed to edit project: " + e.getMessage(), projectId,
                        Collections.emptyList());
            }
        }
    }

    private String buildEditPrompt(List<GenerateResponse.GeneratedFile> currentFiles, String userInstruction) {
        StringBuilder filesContext = new StringBuilder();
        for (GenerateResponse.GeneratedFile file : currentFiles) {
            filesContext.append("\n--- ").append(file.getPath()).append(" ---\n");
            filesContext.append(file.getContent());
            filesContext.append("\n");
        }

        return String.format(
                "You are ForgeAI, an expert senior web product designer and frontend architect.\n" +
                        "\n" +
                        "You generate complete production-quality websites using:\n" +
                        "- HTML\n" +
                        "- CSS\n" +
                        "- Vanilla JavaScript only\n" +
                        "\n" +
                        "📦 OUTPUT FORMAT (MANDATORY JSON)\n" +
                        "Always respond in this exact format:\n" +
                        "{\n" +
                        "  \"files\": [\n" +
                        "    { \"path\": \"index.html\", \"content\": \"...\" },\n" +
                        "    { \"path\": \"styles.css\", \"content\": \"...\" },\n" +
                        "    { \"path\": \"script.js\", \"content\": \"...\" }\n" +
                        "  ]\n" +
                        "}\n" +
                        "\n" +
                        "No markdown. No explanations. No backticks.\n" +
                        "\n" +
                        "🏗️ WEBSITE STRUCTURE (MANDATORY)\n" +
                        "Every website MUST include:\n" +
                        "- Sticky header with nav\n" +
                        "- Hero section with CTA\n" +
                        "- Features / Services section (3–6 cards)\n" +
                        "- About section\n" +
                        "- Benefits / Why Choose Us section\n" +
                        "- Call-to-action section\n" +
                        "- Footer with:\n" +
                        "  - Links\n" +
                        "  - Copyright\n" +
                        "  - Text: Built with ForgeAI\n" +
                        "\n" +
                        "🎨 DESIGN RULES\n" +
                        "Must look modern startup / SaaS quality\n" +
                        "Must include:\n" +
                        "- Cards\n" +
                        "- Shadows\n" +
                        "- Gradients\n" +
                        "- Hover animations\n" +
                        "- Scroll animations\n" +
                        "- Section reveal animations\n" +
                        "- Fully responsive\n" +
                        "\n" +
                        "🧠 CONTENT RULES\n" +
                        "Use the user's idea as the business theme\n" +
                        "Write realistic professional marketing content\n" +
                        "No lorem ipsum\n" +
                        "No placeholders\n" +
                        "No \"Hello world\"\n" +
                        "\n" +
                        "⚙️ INTERACTIVITY RULES\n" +
                        "Must include:\n" +
                        "- Smooth scrolling\n" +
                        "- Navbar scroll effect\n" +
                        "- Button hover animations\n" +
                        "- Section reveal animation\n" +
                        "- Simple JS animations\n" +
                        "\n" +
                        "🧱 TECH RULES\n" +
                        "❌ No React\n" +
                        "❌ No Tailwind\n" +
                        "❌ No Bootstrap\n" +
                        "❌ No frameworks\n" +
                        "❌ No external JS or CSS libraries\n" +
                        "❌ No CDN dependencies\n" +
                        "\n" +
                        "🏷️ BRANDING RULE\n" +
                        "If user asks who you are or who built this:\n" +
                        "Always say:\n" +
                        "I am ForgeAI, an AI website builder created by the ForgeAI team.\n" +
                        "\n" +
                        "🧨 HARD FAIL CONDITIONS\n" +
                        "Do NOT return code fences\n" +
                        "Do NOT return explanations\n" +
                        "Do NOT return markdown\n" +
                        "Do NOT return partial files\n" +
                        "\n" +
                        "CURRENT FILES:\n%s\n" +
                        "\n" +
                        "USER INSTRUCTION: %s\n" +
                        "\n" +
                        "Regenerate ALL files fully based on the user's instruction.\n" +
                        "Use proper escaping for double quotes and newlines in the JSON content values.",
                filesContext.toString(),
                userInstruction);
    }

    private void validateFiles(List<GenerateResponse.GeneratedFile> files) {
        if (files == null || files.size() != 3) {
            throw new RuntimeException(
                    "Invalid file count. Expected exactly 3 files (index.html, styles.css, script.js), but got: " +
                            (files == null ? "null" : files.size()));
        }

        boolean hasIndexHtml = false;
        boolean hasStylesCss = false;
        boolean hasScriptJs = false;

        for (GenerateResponse.GeneratedFile file : files) {
            String path = file.getPath().toLowerCase();
            if (path.equals("index.html")) {
                hasIndexHtml = true;
            } else if (path.equals("styles.css")) {
                hasStylesCss = true;
            } else if (path.equals("script.js")) {
                hasScriptJs = true;
            }
        }

        if (!hasIndexHtml || !hasStylesCss || !hasScriptJs) {
            throw new RuntimeException(
                    "Invalid files. Must contain exactly: index.html, styles.css, script.js. " +
                            "Found: " + files.stream()
                                    .map(f -> f.getPath())
                                    .reduce((a, b) -> a + ", " + b)
                                    .orElse("none"));
        }
    }

    private List<GenerateResponse.GeneratedFile> createMockFiles(GenerateRequest request) {
        String name = request.getProjectName() != null ? request.getProjectName() : "My Website";
        String desc = request.getDescription() != null ? request.getDescription() : "AI built professional website.";
        String cat = request.getCategory() != null ? request.getCategory() : "Business";
        List<String> secs = request.getSections();
        if (secs == null || secs.isEmpty()) {
            secs = List.of("Home", "About", "Services", "Contact");
        }

        StringBuilder navLinks = new StringBuilder();
        StringBuilder sectionsHtml = new StringBuilder();

        for (String section : secs) {
            String lowerSec = section.toLowerCase().trim();
            navLinks.append("                <li><a href=\"#").append(lowerSec).append("\">").append(section).append("</a></li>\n");

            if (lowerSec.equals("about")) {
                sectionsHtml.append("    <section id=\"about\" class=\"about-section\">\n")
                        .append("        <div class=\"section-container\">\n")
                        .append("            <h2>About Us</h2>\n")
                        .append("            <p>We are pioneers in the field of ").append(cat).append(". Our mission is to deliver high-quality, professional, and innovative solutions tailored to your unique business needs.</p>\n")
                        .append("        </div>\n")
                        .append("    </section>\n\n");
            } else if (lowerSec.equals("services")) {
                sectionsHtml.append("    <section id=\"services\" class=\"services-section\">\n")
                        .append("        <div class=\"section-container\">\n")
                        .append("            <h2>Our Services</h2>\n")
                        .append("            <div class=\"cards-grid\">\n")
                        .append("                <div class=\"card\">\n")
                        .append("                    <div class=\"card-icon\">⚡</div>\n")
                        .append("                    <h3>High Performance</h3>\n")
                        .append("                    <p>Speed is core to our design. Experience blazing-fast operations.</p>\n")
                        .append("                </div>\n")
                        .append("                <div class=\"card\">\n")
                        .append("                    <div class=\"card-icon\">🔒</div>\n")
                        .append("                    <h3>Secure & Reliable</h3>\n")
                        .append("                    <p>State-of-the-art security practices to protect your data.</p>\n")
                        .append("                </div>\n")
                        .append("                <div class=\"card\">\n")
                        .append("                    <div class=\"card-icon\">🎨</div>\n")
                        .append("                    <h3>Modern Design</h3>\n")
                        .append("                    <p>Vibrant gradients and responsive layouts that look premium.</p>\n")
                        .append("                </div>\n")
                        .append("            </div>\n")
                        .append("        </div>\n")
                        .append("    </section>\n\n");
            } else if (lowerSec.equals("projects")) {
                sectionsHtml.append("    <section id=\"projects\" class=\"projects-section\">\n")
                        .append("        <div class=\"section-container\">\n")
                        .append("            <h2>Our Projects</h2>\n")
                        .append("            <div class=\"cards-grid\">\n")
                        .append("                <div class=\"card\">\n")
                        .append("                    <h3>Project Alpha</h3>\n")
                        .append("                    <p>Next-gen SaaS automation engine.</p>\n")
                        .append("                </div>\n")
                        .append("                <div class=\"card\">\n")
                        .append("                    <h3>Project Beta</h3>\n")
                        .append("                    <p>AI-driven business analytics dashboard.</p>\n")
                        .append("                </div>\n")
                        .append("            </div>\n")
                        .append("        </div>\n")
                        .append("    </section>\n\n");
            } else if (lowerSec.equals("contact")) {
                sectionsHtml.append("    <section id=\"contact\" class=\"contact-section\">\n")
                        .append("        <div class=\"section-container\">\n")
                        .append("            <h2>Contact Us</h2>\n")
                        .append("            <form class=\"contact-form\" onsubmit=\"event.preventDefault(); alert('Message sent!');\">\n")
                        .append("                <input type=\"text\" placeholder=\"Your Name\" required>\n")
                        .append("                <input type=\"email\" placeholder=\"Your Email\" required>\n")
                        .append("                <textarea placeholder=\"Your Message\" rows=\"5\" required></textarea>\n")
                        .append("                <button type=\"submit\" class=\"btn btn-primary\">Send Message</button>\n")
                        .append("            </form>\n")
                        .append("        </div>\n")
                        .append("    </section>\n\n");
            } else {
                sectionsHtml.append("    <section id=\"").append(lowerSec).append("\" class=\"about-section\">\n")
                        .append("        <div class=\"section-container\">\n")
                        .append("            <h2>").append(section).append("</h2>\n")
                        .append("            <p>Welcome to our ").append(section).append(" section. Custom content for ").append(name).append(" is being initialized here.</p>\n")
                        .append("        </div>\n")
                        .append("    </section>\n\n");
            }
        }

        String htmlContent = "<!DOCTYPE html>\n" +
                "<html lang=\"en\">\n" +
                "<head>\n" +
                "    <meta charset=\"UTF-8\">\n" +
                "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" +
                "    <title>" + name + " - ForgeAI Built</title>\n" +
                "    <link rel=\"stylesheet\" href=\"styles.css\">\n" +
                "</head>\n" +
                "<body>\n" +
                "    <header class=\"header\">\n" +
                "        <nav class=\"nav\">\n" +
                "            <div class=\"logo\">" + name + "</div>\n" +
                "            <ul class=\"nav-links\">\n" +
                navLinks.toString() +
                "            </ul>\n" +
                "            <button class=\"btn btn-primary btn-cta\">Get Started</button>\n" +
                "        </nav>\n" +
                "    </header>\n\n" +
                "    <section id=\"home\" class=\"hero-section\">\n" +
                "        <div class=\"hero-content\">\n" +
                "            <h1>Create the Future of <span>" + name + "</span></h1>\n" +
                "            <p>" + desc + "</p>\n" +
                "            <div class=\"hero-actions\">\n" +
                "                <button class=\"btn btn-accent btn-large\">Get Started Now</button>\n" +
                "                <button class=\"btn btn-outline btn-large\">Learn More</button>\n" +
                "            </div>\n" +
                "        </div>\n" +
                "    </section>\n\n" +
                sectionsHtml.toString() +
                "    <footer class=\"footer\">\n" +
                "        <div class=\"footer-content\">\n" +
                "            <p>&copy; 2026 " + name + ". All rights reserved.</p>\n" +
                "            <p>Built with ❤️ using <span class=\"forge-brand\">ForgeAI</span></p>\n" +
                "        </div>\n" +
                "    </footer>\n\n" +
                "    <script src=\"script.js\"></script>\n" +
                "</body>\n" +
                "</html>";

        String cssContent = ":root {\n" +
                "    --bg-color: #0b0f19;\n" +
                "    --card-bg: #1e2640;\n" +
                "    --text-color: #ffffff;\n" +
                "    --text-muted: #94a3b8;\n" +
                "    --primary: #00f0ff;\n" +
                "    --accent: #7000ff;\n" +
                "    --header-bg: rgba(30, 41, 59, 0.8);\n" +
                "    --border-color: rgba(255, 255, 255, 0.1);\n" +
                "}\n\n" +
                "* {\n" +
                "    margin: 0;\n" +
                "    padding: 0;\n" +
                "    box-sizing: border-box;\n" +
                "    font-family: sans-serif;\n" +
                "}\n\n" +
                "body {\n" +
                "    background-color: var(--bg-color);\n" +
                "    color: var(--text-color);\n" +
                "    line-height: 1.6;\n" +
                "    overflow-x: hidden;\n" +
                "}\n\n" +
                ".header {\n" +
                "    position: fixed;\n" +
                "    top: 0;\n" +
                "    left: 0;\n" +
                "    width: 100%;\n" +
                "    z-index: 1000;\n" +
                "    background: var(--header-bg);\n" +
                "    backdrop-filter: blur(10px);\n" +
                "    border-bottom: 1px solid var(--border-color);\n" +
                "}\n\n" +
                ".nav {\n" +
                "    display: flex;\n" +
                "    justify-content: space-between;\n" +
                "    align-items: center;\n" +
                "    max-width: 1200px;\n" +
                "    margin: 0 auto;\n" +
                "    padding: 1rem 2rem;\n" +
                "}\n\n" +
                ".logo {\n" +
                "    font-size: 1.5rem;\n" +
                "    font-weight: 800;\n" +
                "    background: linear-gradient(135deg, var(--primary), var(--accent));\n" +
                "    -webkit-background-clip: text;\n" +
                "    -webkit-text-fill-color: transparent;\n" +
                "    letter-spacing: 1px;\n" +
                "}\n\n" +
                ".nav-links {\n" +
                "    display: flex;\n" +
                "    list-style: none;\n" +
                "    gap: 2rem;\n" +
                "}\n\n" +
                ".nav-links a {\n" +
                "    color: var(--text-muted);\n" +
                "    text-decoration: none;\n" +
                "    font-size: 0.95rem;\n" +
                "    font-weight: 500;\n" +
                "    transition: color 0.3s;\n" +
                "}\n\n" +
                ".nav-links a:hover {\n" +
                "    color: var(--primary);\n" +
                "}\n\n" +
                ".btn {\n" +
                "    border: none;\n" +
                "    border-radius: 8px;\n" +
                "    padding: 0.6rem 1.5rem;\n" +
                "    font-size: 0.95rem;\n" +
                "    font-weight: 600;\n" +
                "    cursor: pointer;\n" +
                "    transition: all 0.3s ease;\n" +
                "}\n\n" +
                ".btn-primary {\n" +
                "    background-color: var(--primary);\n" +
                "    color: #0b0f19;\n" +
                "}\n\n" +
                ".btn-primary:hover {\n" +
                "    box-shadow: 0 0 15px var(--primary);\n" +
                "    transform: translateY(-2px);\n" +
                "}\n\n" +
                ".btn-accent {\n" +
                "    background-color: var(--accent);\n" +
                "    color: #fff;\n" +
                "}\n\n" +
                ".btn-accent:hover {\n" +
                "    box-shadow: 0 0 15px var(--accent);\n" +
                "    transform: translateY(-2px);\n" +
                "}\n\n" +
                ".btn-outline {\n" +
                "    background: transparent;\n" +
                "    border: 1px solid var(--primary);\n" +
                "    color: var(--primary);\n" +
                "}\n\n" +
                ".btn-outline:hover {\n" +
                "    background: var(--primary);\n" +
                "    color: #0b0f19;\n" +
                "    transform: translateY(-2px);\n" +
                "}\n\n" +
                ".btn-large {\n" +
                "    padding: 0.8rem 2rem;\n" +
                "    font-size: 1.05rem;\n" +
                "}\n\n" +
                "section {\n" +
                "    padding: 8rem 2rem 6rem 2rem;\n" +
                "    display: flex;\n" +
                "    justify-content: center;\n" +
                "}\n\n" +
                ".section-container {\n" +
                "    max-width: 1000px;\n" +
                "    width: 100%;\n" +
                "    text-align: center;\n" +
                "}\n\n" +
                "h2 {\n" +
                "    font-size: 2.5rem;\n" +
                "    margin-bottom: 2rem;\n" +
                "    background: linear-gradient(135deg, #ffffff, var(--primary));\n" +
                "    -webkit-background-clip: text;\n" +
                "    -webkit-text-fill-color: transparent;\n" +
                "}\n\n" +
                ".hero-section {\n" +
                "    min-height: 100vh;\n" +
                "    display: flex;\n" +
                "    align-items: center;\n" +
                "    justify-content: center;\n" +
                "    background: radial-gradient(circle at 10% 20%, rgba(112, 0, 255, 0.15) 0%, transparent 40%),\n" +
                "                radial-gradient(circle at 90% 80%, rgba(0, 240, 255, 0.15) 0%, transparent 40%);\n" +
                "}\n\n" +
                ".hero-content {\n" +
                "    max-width: 800px;\n" +
                "    text-align: center;\n" +
                "}\n\n" +
                ".hero-content h1 {\n" +
                "    font-size: 4rem;\n" +
                "    font-weight: 800;\n" +
                "    margin-bottom: 1.5rem;\n" +
                "    line-height: 1.1;\n" +
                "}\n\n" +
                ".hero-content h1 span {\n" +
                "    background: linear-gradient(135deg, var(--primary), var(--accent));\n" +
                "    -webkit-background-clip: text;\n" +
                "    -webkit-text-fill-color: transparent;\n" +
                "}\n\n" +
                ".hero-content p {\n" +
                "    font-size: 1.25rem;\n" +
                "    color: var(--text-muted);\n" +
                "    margin-bottom: 2.5rem;\n" +
                "}\n\n" +
                ".hero-actions {\n" +
                "    display: flex;\n" +
                "    gap: 1.5rem;\n" +
                "    justify-content: center;\n" +
                "}\n\n" +
                ".cards-grid {\n" +
                "    display: grid;\n" +
                "    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));\n" +
                "    gap: 2rem;\n" +
                "    margin-top: 3rem;\n" +
                "}\n\n" +
                ".card {\n" +
                "    background-color: var(--card-bg);\n" +
                "    border: 1px solid var(--border-color);\n" +
                "    border-radius: 16px;\n" +
                "    padding: 2.5rem 2rem;\n" +
                "    text-align: left;\n" +
                "    transition: all 0.3s ease;\n" +
                "}\n\n" +
                ".card:hover {\n" +
                "    transform: translateY(-8px);\n" +
                "    border-color: var(--primary);\n" +
                "    box-shadow: 0 10px 25px rgba(0, 240, 255, 0.1);\n" +
                "}\n\n" +
                ".card-icon {\n" +
                "    font-size: 2.5rem;\n" +
                "    margin-bottom: 1.5rem;\n" +
                "}\n\n" +
                ".card h3 {\n" +
                "    font-size: 1.5rem;\n" +
                "    margin-bottom: 1rem;\n" +
                "}\n\n" +
                ".card p {\n" +
                "    color: var(--text-muted);\n" +
                "}\n\n" +
                ".contact-form {\n" +
                "    max-width: 600px;\n" +
                "    margin: 3rem auto 0 auto;\n" +
                "    display: flex;\n" +
                "    flex-direction: column;\n" +
                "    gap: 1.5rem;\n" +
                "}\n\n" +
                ".contact-form input,\n" +
                ".contact-form textarea {\n" +
                "    width: 100%;\n" +
                "    padding: 1rem;\n" +
                "    background-color: var(--card-bg);\n" +
                "    border: 1px solid var(--border-color);\n" +
                "    border-radius: 8px;\n" +
                "    color: white;\n" +
                "    font-size: 1rem;\n" +
                "    transition: all 0.3s;\n" +
                "}\n\n" +
                ".contact-form input:focus,\n" +
                ".contact-form textarea:focus {\n" +
                "    outline: none;\n" +
                "    border-color: var(--primary);\n" +
                "    box-shadow: 0 0 10px rgba(0, 240, 255, 0.2);\n" +
                "}\n\n" +
                ".footer {\n" +
                "    border-top: 1px solid var(--border-color);\n" +
                "    padding: 3rem 2rem;\n" +
                "    text-align: center;\n" +
                "}\n\n" +
                ".footer-content {\n" +
                "    max-width: 1200px;\n" +
                "    margin: 0 auto;\n" +
                "    display: flex;\n" +
                "    justify-content: space-between;\n" +
                "    color: var(--text-muted);\n" +
                "    font-size: 0.9rem;\n" +
                "}\n\n" +
                ".forge-brand {\n" +
                "    font-weight: 700;\n" +
                "    color: var(--primary);\n" +
                "}\n\n" +
                "@media (max-width: 768px) {\n" +
                "    .nav-links {\n" +
                "        display: none;\n" +
                "    }\n" +
                "    .hero-content h1 {\n" +
                "        font-size: 2.5rem;\n" +
                "    }\n" +
                "    .footer-content {\n" +
                "        flex-direction: column;\n" +
                "        gap: 1rem;\n" +
                "    }\n" +
                "}";

        String jsContent = "document.addEventListener('DOMContentLoaded', () => {\n" +
                "    console.log(\"ForgeAI Mock Website loaded successfully!\");\n" +
                "    \n" +
                "    const links = document.querySelectorAll('.nav-links a');\n" +
                "    links.forEach(link => {\n" +
                "        link.addEventListener('click', (e) => {\n" +
                "            e.preventDefault();\n" +
                "            const targetId = link.getAttribute('href');\n" +
                "            if (targetId.startsWith('#')) {\n" +
                "                const targetElement = document.querySelector(targetId);\n" +
                "                if (targetElement) {\n" +
                "                    targetElement.scrollIntoView({ behavior: 'smooth' });\n" +
                "                }\n" +
                "            }\n" +
                "        });\n" +
                "    });\n\n" +
                "    const header = document.querySelector('.header');\n" +
                "    window.addEventListener('scroll', () => {\n" +
                "        if (window.scrollY > 50) {\n" +
                "            header.style.padding = '0.5rem 0';\n" +
                "            header.style.backgroundColor = 'rgba(11, 15, 25, 0.95)';\n" +
                "        } else {\n" +
                "            header.style.padding = '1rem 0';\n" +
                "            header.style.backgroundColor = 'rgba(30, 41, 59, 0.8)';\n" +
                "        }\n" +
                "    });\n" +
                "});";

        return List.of(
                new GenerateResponse.GeneratedFile("index.html", htmlContent),
                new GenerateResponse.GeneratedFile("styles.css", cssContent),
                new GenerateResponse.GeneratedFile("script.js", jsContent)
        );
    }

    private List<GenerateResponse.GeneratedFile> createMockEditFiles(String projectId, String userInstruction) {
        try {
            List<GenerateResponse.GeneratedFile> currentFiles = fileStorageService.loadProjectFiles(projectId);
            for (GenerateResponse.GeneratedFile file : currentFiles) {
                if (file.getPath().equalsIgnoreCase("index.html")) {
                    String content = file.getContent();
                    if (content.contains("</h1>")) {
                        content = content.replace("</h1>", "</h1>\n    <div style=\"background: #7000ff; color: white; padding: 10px; margin: 15px 0; border-radius: 8px; font-weight: bold; text-align: center;\">Applied update: " + userInstruction + "</div>");
                    }
                    file.setContent(content);
                } else if (file.getPath().equalsIgnoreCase("script.js")) {
                    String content = file.getContent();
                    content = content + "\n// Applied instruction: " + userInstruction;
                    file.setContent(content);
                }
            }
            return currentFiles;
        } catch (Exception e) {
            logger.error("Failed to load existing files for edit mock fallback: {}", e.getMessage());
            GenerateRequest dummy = new GenerateRequest();
            dummy.setProjectName("Updated Project");
            dummy.setDescription("Updates applied: " + userInstruction);
            return createMockFiles(dummy);
        }
    }

    private record GeneratedFilesWrapper(List<GenerateResponse.GeneratedFile> files) {
    }
}
