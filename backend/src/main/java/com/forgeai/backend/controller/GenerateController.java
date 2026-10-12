package com.forgeai.backend.controller;

import com.forgeai.backend.dto.GenerateRequest;
import com.forgeai.backend.model.GenerationJob;
import com.forgeai.backend.service.GenerateService;
import com.forgeai.backend.service.JobStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
/**
 * Controller responsible for handling project generation requests.
 * Uses an asynchronous job system to prevent timeouts on long-running
 * generations.
 */
public class GenerateController {

    private static final Logger logger = LoggerFactory.getLogger(GenerateController.class);
    private final GenerateService generateService;
    private final JobStore jobStore;

    public GenerateController(GenerateService generateService, JobStore jobStore) {
        this.generateService = generateService;
        this.jobStore = jobStore;
    }

    /**
     * Initiates a new project generation job.
     * Returns immediately with a job ID so the client can poll for status.
     *
     * @param request The generation parameters (prompt, model, etc.)
     * @return Accepted response with the created job details.
     */
    @PostMapping("/generate")
    public ResponseEntity<GenerationJob> generate(@RequestBody GenerateRequest request) {
        logger.info("🚀 Received generation request for project: {}", request.getProjectName());

        GenerationJob job = jobStore.createJob();
        generateService.startGeneration(job.getJobId(), request);

        logger.info("✅ Started async job: {}", job.getJobId());
        return ResponseEntity.accepted().body(job);
    }

    /**
     * Polls the status of a specific generation job.
     *
     * @param jobId The ID of the job to check.
     * @return The current state of the job (PENDING, COMPLETED, FAILED, etc.)
     */
    @GetMapping("/jobs/{jobId}")
    public ResponseEntity<GenerationJob> getJobStatus(@PathVariable String jobId) {
        GenerationJob job = jobStore.getJob(jobId);
        if (job == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(job);
    }
}
