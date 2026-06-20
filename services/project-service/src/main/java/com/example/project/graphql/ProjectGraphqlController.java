package com.example.project.graphql;

import com.example.project.domain.Project;
import com.example.project.service.ProjectService;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class ProjectGraphqlController {

    private final ProjectService projectService;

    public ProjectGraphqlController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @MutationMapping
    public Project addProject(@Argument String name, @Argument String owner, @Argument String status) {
        Project p = new Project();
        p.setName(name);
        p.setOwner(owner);
        p.setStatus(status);
        return projectService.addProject(p);
    }

    @MutationMapping
    public Project updateProject(@Argument Long id, @Argument String name, @Argument String owner, @Argument String status) {
        Project p = new Project();
        p.setName(name);
        p.setOwner(owner);
        p.setStatus(status);
        return projectService.updateProject(id, p).orElse(null);
    }

    @MutationMapping
    public Boolean deleteProject(@Argument Long id) {
        return projectService.deleteProject(id);
    }

    @QueryMapping
    public Project getProject(@Argument Long id) {
        return projectService.getProject(id).orElse(null);
    }
}
