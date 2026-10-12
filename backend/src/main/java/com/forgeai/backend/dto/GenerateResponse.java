package com.forgeai.backend.dto;

import java.util.List;

public class GenerateResponse {
    private boolean success;
    private String message;
    private String projectId;
    private List<GeneratedFile> files;

    public GenerateResponse(boolean success, String message, String projectId, List<GeneratedFile> files) {
        this.success = success;
        this.message = message;
        this.projectId = projectId;
        this.files = files;
    }

    public static class GeneratedFile {
        private String path;
        private String content;

        public GeneratedFile() {
        }

        public GeneratedFile(String path, String content) {
            this.path = path;
            this.content = content;
        }

        public String getPath() {
            return path;
        }

        public void setPath(String path) {
            this.path = path;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getProjectId() {
        return projectId;
    }

    public void setProjectId(String projectId) {
        this.projectId = projectId;
    }

    public List<GeneratedFile> getFiles() {
        return files;
    }

    public void setFiles(List<GeneratedFile> files) {
        this.files = files;
    }
}
