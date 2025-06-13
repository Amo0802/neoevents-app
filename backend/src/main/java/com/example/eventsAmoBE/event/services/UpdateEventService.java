package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.Category;
import com.example.eventsAmoBE.event.model.Event;
import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Set;

@Service
@Transactional
public class UpdateEventService {

    private final EventRepository eventRepository;

    @Autowired
    public UpdateEventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    //@CacheEvict(value = "events", allEntries = true)
    public Event execute(Long id, Event updatedEvent) {
        Event existingEvent = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event with id " + id + " doesn't exist!"));

        // Update only non-null and non-empty fields
        updateIfNotNullOrEmpty(existingEvent, updatedEvent);

        return eventRepository.save(existingEvent);
    }

    private void updateIfNotNullOrEmpty(Event existingEvent, Event updatedEvent) {
        // Update simple string fields
        if (StringUtils.hasText(updatedEvent.getName())) {
            existingEvent.setName(updatedEvent.getName());
        }

        if (StringUtils.hasText(updatedEvent.getDescription())) {
            existingEvent.setDescription(updatedEvent.getDescription());
        }

        if (StringUtils.hasText(updatedEvent.getImageUrl())) {
            existingEvent.setImageUrl(updatedEvent.getImageUrl());
        }

        if (StringUtils.hasText(updatedEvent.getAddress())) {
            existingEvent.setAddress(updatedEvent.getAddress());
        }

        // Update date/time if not null
        if (updatedEvent.getStartDateTime() != null) {
            existingEvent.setStartDateTime(updatedEvent.getStartDateTime());
        }

        // Update numeric values (using wrapper classes to check for null)
        if (updatedEvent.getPrice() != null) {
            existingEvent.setPrice(updatedEvent.getPrice());
        }

        if (updatedEvent.getPriority() != 0) {  // Assuming 0 is default/unset value
            existingEvent.setPriority(updatedEvent.getPriority());
        }

        // Update enum if not null
        if (updatedEvent.getCity() != null) {
            existingEvent.setCity(updatedEvent.getCity());
        }

        // Update boolean flags (always update as they're primitives)
        existingEvent.setMainEvent(updatedEvent.isMainEvent());
        existingEvent.setPromoted(updatedEvent.isPromoted());

        // Update collection if not empty
        Set<Category> updatedCategories = updatedEvent.getCategories();
        if (updatedCategories != null && !updatedCategories.isEmpty()) {
            existingEvent.setCategories(updatedCategories);
        }
    }
}