package com.example.budget.event;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class ProjectEventConsumer {

    private static final Logger LOG = LoggerFactory.getLogger(ProjectEventConsumer.class);

    @KafkaListener(topics = "project-changed", groupId = "budget-service")
    public void onProjectChanged(ProjectChangedEvent event) {
        LOG.info("Received project event: {}", event);
    }
}
