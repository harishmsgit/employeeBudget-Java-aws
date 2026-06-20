package com.example.budget.event;

public record ProjectChangedEvent(Long projectId, String action, String status) {
}
