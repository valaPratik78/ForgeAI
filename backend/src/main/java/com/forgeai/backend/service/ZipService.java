package com.forgeai.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class ZipService {

    private static final Logger logger = LoggerFactory.getLogger(ZipService.class);
    private static final String BASE_FOLDER = "generated-projects";
    private static final String ZIP_FOLDER = "generated";

    public void zipProject(String projectId) {
        Path sourceDirPath = Paths.get(BASE_FOLDER, projectId);
        Path zipDirPath = Paths.get(ZIP_FOLDER);
        Path zipFilePath = Paths.get(ZIP_FOLDER, projectId + ".zip");

        if (!Files.exists(sourceDirPath)) {
            logger.error("Source directory does not exist: {}", sourceDirPath.toAbsolutePath());
            return;
        }

        // Create zip directory if it doesn't exist
        try {
            Files.createDirectories(zipDirPath);
        } catch (IOException e) {
            logger.error("Failed to create zip directory: {}", e.getMessage());
            throw new RuntimeException("Could not create zip directory", e);
        }

        try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
                ZipOutputStream zos = new ZipOutputStream(fos)) {

            Files.walkFileTree(sourceDirPath, new SimpleFileVisitor<Path>() {
                @Override
                public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                    // Only include HTML, CSS, and JS files
                    String fileName = file.getFileName().toString().toLowerCase();
                    if (fileName.endsWith(".html") || fileName.endsWith(".css") || fileName.endsWith(".js")) {
                        // Create relative path for the zip entry (flatten to root)
                        String relativePath = file.getFileName().toString();
                        zos.putNextEntry(new ZipEntry(relativePath));
                        Files.copy(file, zos);
                        zos.closeEntry();
                    }
                    return FileVisitResult.CONTINUE;
                }
            });

            logger.info("Project zipped successfully: {}", zipFilePath.toAbsolutePath());
        } catch (IOException e) {
            logger.error("Failed to zip project {}: {}", projectId, e.getMessage());
            throw new RuntimeException("Could not zip project", e);
        }
    }
}
