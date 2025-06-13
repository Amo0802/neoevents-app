package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.utils.PageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class GetEventsService {

    private final EventRepository eventRepository;

    public GetEventsService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    //@Cacheable(value = "events", key = "'allEvents_' + #pageable.pageNumber + '_' + #pageable.pageSize", cacheManager = "eventCacheManager")
    public PageResponse<EventDto> execute(Pageable pageable) {
        Page<Event> page = eventRepository.findUpcomingEvents(LocalDateTime.now(), pageable);

        List<EventDto> dtos = page.getContent().stream()
                .map(EventDto::new)
                .toList();

        return new PageResponse<>(
                dtos,
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.getNumberOfElements(),
                page.isLast()
        );
    }
}
