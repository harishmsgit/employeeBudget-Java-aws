package com.example.employee.event;

public record EmployeeChangedEvent(Long employeeId, String action, String email) {
}
