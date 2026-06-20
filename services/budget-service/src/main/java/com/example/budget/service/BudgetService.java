package com.example.budget.service;

import com.example.budget.domain.Budget;
import com.example.budget.repository.BudgetRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Optional;

@Service
public class BudgetService {

    private final BudgetRepository budgetRepository;

    public BudgetService(BudgetRepository budgetRepository) {
        this.budgetRepository = budgetRepository;
    }

    public Budget addbuget(Long projectId, Double amount, String currency) {
        Budget budget = new Budget();
        budget.setProjectId(projectId);
        budget.setAmount(BigDecimal.valueOf(amount).setScale(2, RoundingMode.HALF_UP));
        budget.setCurrency(currency);
        return budgetRepository.save(budget);
    }

    public Budget updatebuget(Long id, Double amount, String currency) {
        return budgetRepository.findById(id).map(existing -> {
            existing.setAmount(BigDecimal.valueOf(amount).setScale(2, RoundingMode.HALF_UP));
            existing.setCurrency(currency);
            return budgetRepository.save(existing);
        }).orElse(null);
    }

    public Boolean deletebuget(Long id) {
        if (budgetRepository.existsById(id)) {
            budgetRepository.deleteById(id);
            return true;
        }
        return false;
    }

    public Optional<Budget> budgetLinedProject(Long projectId) {
        return budgetRepository.findByProjectId(projectId);
    }
}
