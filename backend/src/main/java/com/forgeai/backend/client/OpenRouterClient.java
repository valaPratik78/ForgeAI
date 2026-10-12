package com.forgeai.backend.client;

import com.forgeai.backend.dto.ai.OpenRouterRequest;
import com.forgeai.backend.dto.ai.OpenRouterResponse;
import com.forgeai.backend.config.OpenRouterProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class OpenRouterClient {

    private static final Logger logger = LoggerFactory.getLogger(OpenRouterClient.class);
    private final RestTemplate restTemplate;
    private final OpenRouterProperties properties;

    public OpenRouterClient(RestTemplate restTemplate, OpenRouterProperties properties) {
        this.restTemplate = restTemplate;
        this.properties = properties;
    }

    public String generate(String prompt) {
        String apiKey = properties.getKey();
        String apiUrl = properties.getUrl();
        // validated below

        if (apiKey == null || apiKey.isBlank()) {
            throw new RuntimeException("OpenRouter API key is not configured");
        }
        if (apiUrl == null || apiUrl.isBlank()) {
            throw new RuntimeException("OpenRouter API URL is not configured");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);
        headers.add("HTTP-Referer", "http://localhost");
        headers.add("X-Title", "ForgeAI");

        OpenRouterRequest request = OpenRouterRequest.defaultRequest(prompt);
        HttpEntity<OpenRouterRequest> entity = new HttpEntity<>(request, headers);

        ResponseEntity<OpenRouterResponse> response = restTemplate.postForEntity(
                apiUrl,
                entity,
                OpenRouterResponse.class);

        OpenRouterResponse body = response.getBody();
        if (body != null && body.choices() != null && !body.choices().isEmpty()) {
            return body.choices().get(0).message().content();
        }

        throw new RuntimeException("Empty or invalid response from OpenRouter");
    }
}
