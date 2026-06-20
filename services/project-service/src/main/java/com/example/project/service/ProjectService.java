package com.example.project.service;

import com.example.project.domain.Project;
import com.example.project.event.ProjectChangedEvent;
import com.example.project.repository.ProjectRepository;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final KafkaTemplate<String, ProjectChangedEvent> kafkaTemplate;

    public ProjectService(ProjectRepository projectRepository, KafkaTemplate<String, ProjectChangedEvent> kafkaTemplate) {
        this.projectRepository = projectRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    public Project addProject(Project project) {
        Project saved = projectRepository.save(project);
        publish(saved.getId(), "CREATED", saved.getStatus());
        return saved;
    }

    public Optional<Project> updateProject(Long id, Project req) {
        return projectRepository.findById(id).map(existing -> {
            existing.setName(req.getName());
            existing.setOwner(req.getOwner());
            existing.setStatus(req.getStatus());
            Project saved = projectRepository.save(existing);
            publish(saved.getId(), "UPDATED", saved.getStatus());
            return saved;
        });
    }

    public boolean deleteProject(Long id) {
        if (projectRepository.existsById(id)) {
            projectRepository.deleteById(id);
            publish(id, "DELETED", null);
            return true;
        }
        return false;
    }

    public Optional<Project> getProject(Long id) {
        return projectRepository.findById(id);
    }

    private void publish(Long projectId, String action, String status) {
        kafkaTemplate.send("project-changed", new ProjectChangedEvent(projectId, action, status));
    }
}
