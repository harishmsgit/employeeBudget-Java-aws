package com.example.project.event;

public record ProjectChangedEvent(Long projectId, String action, String status) {
}
