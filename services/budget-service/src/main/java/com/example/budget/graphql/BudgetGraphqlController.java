package com.example.budget.graphql;

import com.example.budget.domain.Budget;
import com.example.budget.service.BudgetService;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class BudgetGraphqlController {

    private final BudgetService budgetService;

    public BudgetGraphqlController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @MutationMapping
    public Budget addbuget(@Argument Long projectId, @Argument Double amount, @Argument String currency) {
        return budgetService.addbuget(projectId, amount, currency);
    }

    @MutationMapping
    public Budget updatebuget(@Argument Long id, @Argument Double amount, @Argument String currency) {
        return budgetService.updatebuget(id, amount, currency);
    }

    @MutationMapping
    public Boolean deletebuget(@Argument Long id) {
        return budgetService.deletebuget(id);
    }

    @QueryMapping
    public Budget budgetLinedProject(@Argument Long projectId) {
        return budgetService.budgetLinedProject(projectId).orElse(null);
    }
}
