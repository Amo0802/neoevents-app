package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.utils.PageResponse;
//import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class GetPromotedEventsService {

    private final EventRepository eventRepository;

    public GetPromotedEventsService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    //@Cacheable(value = "promotedEvents", key = "'promotedEvents_' + #pageable.pageNumber + '_' + #pageable.pageSize", cacheManager = "eventCacheManager")
    public PageResponse<EventDto> execute(Pageable pageable){
        Page<EventDto> page = eventRepository.findUpcomingPromotedEvents(LocalDateTime.now(), pageable).map(EventDto::new);
        return new PageResponse<>(page);
    }
}