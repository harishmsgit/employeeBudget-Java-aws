package com.example.project.event;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class EmployeeEventConsumer {

    private static final Logger LOG = LoggerFactory.getLogger(EmployeeEventConsumer.class);

    @KafkaListener(topics = "employee-changed", groupId = "project-service")
    public void onEmployeeChanged(EmployeeChangedEvent event) {
        LOG.info("Received employee event: {}", event);
    }
}
