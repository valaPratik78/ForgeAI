package com.forgeai.backend.controller;

import com.forgeai.backend.dto.GenerateResponse;
import com.forgeai.backend.service.GenerateService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/projects")
@CrossOrigin(origins = "*")
/**
 * Controller responsible for handling iterative edits to an existing project.
 * Allows the user to refine the generated code via chat.
 */
public class EditController {

    private final GenerateService generateService;

    public EditController(GenerateService generateService) {
        this.generateService = generateService;
    }

    /**
     * Applies an edit to an existing project based on user instructions.
     *
     * @param projectId The ID of the project to edit.
     * @param request   The edit instructions (e.g., "Make the button blue").
     * @return The updated project details.
     */
    @PostMapping("/{projectId}/edit")
    public GenerateResponse editProject(
            @PathVariable String projectId,
            @RequestBody Map<String, String> request) {
        String message = request.getOrDefault("message", "");
        return generateService.editProject(projectId, message);
    }
}
