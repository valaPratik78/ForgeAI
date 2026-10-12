package com.forgeai.backend.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Handle client disconnect exceptions gracefully.
     * These are NOT server errors - the client simply disconnected before receiving
     * the response.
     * The operation may have completed successfully on the server side.
     */
    @ExceptionHandler({
            org.apache.catalina.connector.ClientAbortException.class,
            org.springframework.web.context.request.async.AsyncRequestNotUsableException.class
    })
    public void handleClientAbort(Exception ex) {
        logger.warn("Client disconnected before response completed: {}", ex.getClass().getSimpleName());
        // Return nothing - client is gone, no point in sending a response
    }

    /**
     * Handle IOException that may be caused by client disconnect (Broken pipe).
     */
    @ExceptionHandler(IOException.class)
    public void handleIOException(IOException ex) {
        if (isClientDisconnect(ex)) {
            logger.warn("Client disconnected (Broken pipe): {}", ex.getMessage());
            // Return nothing - client is gone
        } else {
            // Re-throw if it's not a client disconnect issue
            throw new RuntimeException("IO error during request processing", ex);
        }
    }

    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(NoHandlerFoundException ex) {
        logger.warn("Handler not found: {}", ex.getRequestURL());
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Not Found");
        body.put("message", "The requested resource was not found");
        body.put("status", HttpStatus.NOT_FOUND.value());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex) {
        // Check if this is a client disconnect that wasn't caught by specific handlers
        if (isClientDisconnect(ex)) {
            logger.warn("Client disconnected during request: {}", ex.getClass().getSimpleName());
            return null; // Client is gone, no response needed
        }

        logger.error("Unhandled exception", ex);
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Internal Server Error");
        body.put("message", ex.getMessage());
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }

    /**
     * Detect if an exception is caused by client disconnect.
     */
    private boolean isClientDisconnect(Throwable ex) {
        if (ex == null) {
            return false;
        }

        String className = ex.getClass().getName();
        String message = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";

        // Check for known client disconnect exceptions
        if (className.contains("ClientAbortException") ||
                className.contains("AsyncRequestNotUsableException")) {
            return true;
        }

        // Check for "Broken pipe" in IOException
        if (ex instanceof IOException && message.contains("broken pipe")) {
            return true;
        }

        // Check cause chain
        return isClientDisconnect(ex.getCause());
    }
}
