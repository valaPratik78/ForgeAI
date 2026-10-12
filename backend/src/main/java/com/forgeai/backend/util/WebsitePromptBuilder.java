package com.forgeai.backend.util;

public class WebsitePromptBuilder {

    public static String buildStrictWebsitePrompt(String userPrompt) {
        return String.format(
                "System: You are an expert web developer. Generate a full website based on the user's request.\n" +
                        "Rules:\n" +
                        "- Return ONLY a valid JSON object.\n" +
                        "- No markdown formatting, no backticks, no explanations.\n" +
                        "- The JSON must have a 'files' object containing 'index.html', 'style.css', and 'script.js'.\n"
                        +
                        "- HTML must link 'style.css' and 'script.js'.\n" +
                        "- Format: {\"files\": {\"index.html\": \"...\", \"style.css\": \"...\", \"script.js\": \"...\"}}\n\n"
                        +
                        "User Prompt: %s",
                userPrompt);
    }
}
