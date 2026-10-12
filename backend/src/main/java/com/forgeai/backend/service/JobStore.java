package com.forgeai.backend.service;

import com.forgeai.backend.dto.GenerateResponse;
import com.forgeai.backend.model.GenerationJob;
import com.forgeai.backend.model.JobStatus;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
/**
 * In-memory store for tracking the status of asynchronous generation jobs.
 * Uses a ConcurrentHashMap to be thread-safe.
 * note: In a real production app, this should be replaced by a database
 * (Redis/Postgres).
 */
public class JobStore {
    private final ConcurrentHashMap<String, GenerationJob> jobs = new ConcurrentHashMap<>();

    public GenerationJob createJob() {
        String jobId = UUID.randomUUID().toString();
        GenerationJob job = new GenerationJob(jobId);
        jobs.put(jobId, job);
        return job;
    }

    public GenerationJob getJob(String jobId) {
        return jobs.get(jobId);
    }

    public void updateStatus(String jobId, JobStatus status) {
        GenerationJob job = jobs.get(jobId);
        if (job != null) {
            job.setStatus(status);
        }
    }

    public void completeJob(String jobId, GenerateResponse response) {
        GenerationJob job = jobs.get(jobId);
        if (job != null) {
            job.setStatus(JobStatus.COMPLETED);
            job.setResult(response);
            job.setProjectId(response.getProjectId());
            job.setEndTime(System.currentTimeMillis());
        }
    }

    public void failJob(String jobId, String errorMessage) {
        GenerationJob job = jobs.get(jobId);
        if (job != null) {
            job.setStatus(JobStatus.FAILED);
            job.setErrorMessage(errorMessage);
            job.setEndTime(System.currentTimeMillis());
        }
    }
}
