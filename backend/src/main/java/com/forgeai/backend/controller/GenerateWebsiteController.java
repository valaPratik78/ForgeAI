package com.forgeai.backend.controller;

import com.forgeai.backend.dto.GenerateRequest;
import com.forgeai.backend.dto.GenerateResponse;
import com.forgeai.backend.service.GenerateService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class GenerateWebsiteController {

    private final GenerateService generateService;

    public GenerateWebsiteController(GenerateService generateService) {
        this.generateService = generateService;
    }

    @PostMapping("/generate-website")
    public GenerateResponse generateWebsite(@RequestBody GenerateRequest request) {
        return generateService.generateProject(request);
    }
}
