package com.example.employee.service;

import com.example.employee.domain.Employee;
import com.example.employee.event.EmployeeChangedEvent;
import com.example.employee.repository.EmployeeRepository;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final KafkaTemplate<String, EmployeeChangedEvent> kafkaTemplate;

    public EmployeeService(EmployeeRepository employeeRepository, KafkaTemplate<String, EmployeeChangedEvent> kafkaTemplate) {
        this.employeeRepository = employeeRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    public Employee addEmp(Employee employee) {
        Employee saved = employeeRepository.save(employee);
        publish(saved.getId(), "CREATED", saved.getEmail());
        return saved;
    }

    public Optional<Employee> updateEmp(Long id, Employee req) {
        return employeeRepository.findById(id).map(existing -> {
            existing.setName(req.getName());
            existing.setEmail(req.getEmail());
            existing.setRole(req.getRole());
            Employee saved = employeeRepository.save(existing);
            publish(saved.getId(), "UPDATED", saved.getEmail());
            return saved;
        });
    }

    public boolean deleteEmp(Long id) {
        if (employeeRepository.existsById(id)) {
            employeeRepository.deleteById(id);
            publish(id, "DELETED", null);
            return true;
        }
        return false;
    }

    public Optional<Employee> getEmp(Long id) {
        return employeeRepository.findById(id);
    }

    private void publish(Long id, String action, String email) {
        kafkaTemplate.send("employee-changed", new EmployeeChangedEvent(id, action, email));
    }
}
