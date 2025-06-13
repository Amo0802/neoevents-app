package com.example.eventsAmoBE.validators;

import com.example.eventsAmoBE.event.model.CreateEventDto;
import com.example.eventsAmoBE.exceptions.EventNotValidException;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class EventValidator {

    public void validateCreateEvent(CreateEventDto eventDto) {
        // Additional custom validations beyond annotations
        if (eventDto.getStartDateTime() != null &&
                eventDto.getStartDateTime().isBefore(LocalDateTime.now())) {
            throw new EventNotValidException("Event date must be in the future");
        }

        // Example of business rule validation
        if (eventDto.isPromoted() && eventDto.getPriority() < 5) {
            throw new EventNotValidException("Promoted events must have priority of at least 5");
        }
    }
}