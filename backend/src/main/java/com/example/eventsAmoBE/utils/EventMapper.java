package com.example.eventsAmoBE.utils;

import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventRequestDto;
import com.example.eventsAmoBE.event.model.Category;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class EventMapper {

    public Event fromDto(EventRequestDto eventDto) {
        Event event = new Event();

        // Mapping EventRequestDTO to Event entity
        event.setName(eventDto.getName());
        event.setDescription(eventDto.getDescription());
        event.setAddress(eventDto.getAddress());
        event.setStartDateTime(LocalDateTime.parse(eventDto.getStartDateTime()));
        event.setPrice(Double.parseDouble(eventDto.getPrice()));

        // Mapping categories from DTO to Enum Set
        Set<Category> categorySet = eventDto.getCategories().stream()
                .map(String::toUpperCase)
                .map(Category::valueOf)
                .collect(Collectors.toSet());
        event.setCategories(categorySet);

        return event;
    }
}
