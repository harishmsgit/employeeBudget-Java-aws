package com.example.project.event;

public record EmployeeChangedEvent(Long employeeId, String action, String email) {
}
