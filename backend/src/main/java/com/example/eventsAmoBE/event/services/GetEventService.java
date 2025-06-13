package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.exceptions.EventNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class GetEventService {

    private final EventRepository eventRepository;

    public GetEventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    public EventDto execute(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(EventNotFoundException::new);

        return new EventDto(event);
    }
}
