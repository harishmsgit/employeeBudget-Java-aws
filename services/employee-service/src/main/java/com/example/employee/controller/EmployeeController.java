package com.example.employee.controller;

import com.example.employee.domain.Employee;
import com.example.employee.service.EmployeeService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EmployeeController {

    private final EmployeeService employeeService;

    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @PostMapping("/addEmp")
    public ResponseEntity<Employee> addEmp(@Valid @RequestBody Employee employee) {
        return ResponseEntity.status(HttpStatus.CREATED).body(employeeService.addEmp(employee));
    }

    @PutMapping("/updateEmp")
    public ResponseEntity<Employee> updateEmp(@RequestParam Long id, @Valid @RequestBody Employee employee) {
        return employeeService.updateEmp(id, employee)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/deleteEmp")
    public ResponseEntity<Void> deleteEmp(@RequestParam Long id) {
        return employeeService.deleteEmp(id)
                ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }

    @GetMapping("/getEmp")
    public ResponseEntity<Employee> getEmp(@RequestParam Long id) {
        return employeeService.getEmp(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
