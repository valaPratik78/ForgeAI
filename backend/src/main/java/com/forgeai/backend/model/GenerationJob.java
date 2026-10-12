package com.forgeai.backend.model;

import com.forgeai.backend.dto.GenerateResponse;

public class GenerationJob {
    private String jobId;
    private JobStatus status;
    private String projectId;
    private GenerateResponse result;
    private Long startTime;
    private Long endTime;
    private String errorMessage;

    public GenerationJob(String jobId) {
        this.jobId = jobId;
        this.status = JobStatus.QUEUED;
        this.startTime = System.currentTimeMillis();
    }

    // Getters and Setters
    public String getJobId() {
        return jobId;
    }

    public void setJobId(String jobId) {
        this.jobId = jobId;
    }

    public JobStatus getStatus() {
        return status;
    }

    public void setStatus(JobStatus status) {
        this.status = status;
    }

    public String getProjectId() {
        return projectId;
    }

    public void setProjectId(String projectId) {
        this.projectId = projectId;
    }

    public GenerateResponse getResult() {
        return result;
    }

    public void setResult(GenerateResponse result) {
        this.result = result;
    }

    public Long getStartTime() {
        return startTime;
    }

    public void setStartTime(Long startTime) {
        this.startTime = startTime;
    }

    public Long getEndTime() {
        return endTime;
    }

    public void setEndTime(Long endTime) {
        this.endTime = endTime;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }
}
