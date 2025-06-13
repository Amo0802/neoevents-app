package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.utils.PageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class SearchEventService {

    private final EventRepository eventRepository;

    public SearchEventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    public PageResponse<EventDto> execute(String search, Pageable pageable){

        Page<EventDto> page = eventRepository.searchUpcomingByNameOrDescription(
                        search, LocalDateTime.now(), pageable).map(EventDto::new);

        return new PageResponse<>(page);
    }
}
