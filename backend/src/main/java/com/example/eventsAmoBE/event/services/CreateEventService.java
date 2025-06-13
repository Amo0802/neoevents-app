package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.CreateEventDto;
import com.example.eventsAmoBE.event.model.Event;
//import org.springframework.cache.annotation.CacheEvict;
import com.example.eventsAmoBE.validators.EventValidator;
import org.springframework.stereotype.Service;

@Service
public class CreateEventService {

    private final EventRepository eventRepository;
    private final EventValidator eventValidator;

    public CreateEventService(EventRepository eventRepository, EventValidator eventValidator) {
        this.eventRepository = eventRepository;
        this.eventValidator = eventValidator;
    }

    //@CacheEvict(value = "events", allEntries = true)
    public Event execute(CreateEventDto input) {

        eventValidator.validateCreateEvent(input);

        var event = Event.builder()
                .name(input.getName())
                .description(input.getDescription())
                .imageUrl(input.getImageUrl())
                .address(input.getAddress())
                .startDateTime(input.getStartDateTime())
                .price(input.getPrice())
                .city(input.getCity())
                .categories(input.getCategories())
                .priority(input.getPriority())
                .mainEvent(input.isMainEvent())
                .promoted(input.isPromoted())
                .build();

        return eventRepository.save(event);
    }
}
