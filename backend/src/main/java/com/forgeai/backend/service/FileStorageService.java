package com.forgeai.backend.service;

import com.forgeai.backend.dto.GenerateResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
/**
 * Service responsible for low-level file system operations.
 * Manages the "generated-projects" directory where all user projects are
 * stored.
 */
public class FileStorageService {

    private static final Logger logger = LoggerFactory.getLogger(FileStorageService.class);
    private static final String BASE_FOLDER = "generated-projects";

    /**
     * Saves a list of generated files (path + content) to the local disk.
     * Creates necessary directories if they don't exist.
     *
     * @param projectId The unique ID of the project (defines the folder name).
     * @param files     The list of files to write.
     */
    public void saveProjectFiles(String projectId, List<GenerateResponse.GeneratedFile> files) {
        Path projectDirPath = Paths.get(BASE_FOLDER, projectId);

        try {
            // 1. Create Base Folder and Project Folder
            Files.createDirectories(projectDirPath);
            logger.info("Created directory: {}", projectDirPath.toAbsolutePath());

            // 2. Write Files
            for (GenerateResponse.GeneratedFile file : files) {
                Path filePath = projectDirPath.resolve(file.getPath());

                // Ensure parent directories for the file exist (nested paths)
                Files.createDirectories(filePath.getParent());

                Files.writeString(filePath, file.getContent());
                logger.info("Saved: {}/{}", BASE_FOLDER, projectId + "/" + file.getPath());
            }
        } catch (IOException e) {
            logger.error("Failed to save project files for projectId {}: {}", projectId, e.getMessage());
            throw new RuntimeException("Could not save generated files", e);
        }
    }

    public Path getProjectRoot(String projectId) {
        return Paths.get(BASE_FOLDER, projectId);
    }

    public Path getBaseFolder() {
        return Paths.get(BASE_FOLDER);
    }

    public List<GenerateResponse.GeneratedFile> loadProjectFiles(String projectId) {
        Path projectRoot = getProjectRoot(projectId);

        if (!Files.exists(projectRoot)) {
            logger.warn("Project directory does not exist: {}", projectRoot);
            return Collections.emptyList();
        }

        List<GenerateResponse.GeneratedFile> files = new ArrayList<>();

        try {
            Files.walkFileTree(projectRoot, new SimpleFileVisitor<Path>() {
                @Override
                public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                    // Only load HTML, CSS, and JS files
                    String fileName = file.getFileName().toString().toLowerCase();
                    if (fileName.endsWith(".html") || fileName.endsWith(".css") || fileName.endsWith(".js")) {
                        String relativePath = projectRoot.relativize(file).toString().replace("\\", "/");
                        String content = Files.readString(file);
                        files.add(new GenerateResponse.GeneratedFile(relativePath, content));
                    }
                    return FileVisitResult.CONTINUE;
                }
            });
        } catch (IOException e) {
            logger.error("Failed to load project files for projectId {}: {}", projectId, e.getMessage());
            throw new RuntimeException("Could not load project files", e);
        }

        return files;
    }
}
