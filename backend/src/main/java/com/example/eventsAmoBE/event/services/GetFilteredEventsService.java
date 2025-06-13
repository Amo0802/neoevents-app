package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import com.example.eventsAmoBE.event.model.Category;
import com.example.eventsAmoBE.event.model.City;
import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.utils.PageResponse;
import com.example.eventsAmoBE.user.model.User;
import com.example.eventsAmoBE.user.services.CurrentUserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class GetFilteredEventsService {

    private final EventRepository eventRepository;

    public GetFilteredEventsService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    public PageResponse<EventDto> execute(Pageable pageable, String city, String category) {

        City city1 = city.equalsIgnoreCase("ALL") ? null : City.valueOf(city);
        Category category1 = category.equalsIgnoreCase("ALL") ? null : Category.valueOf(category);

        Page<Event> page = eventRepository.findUpcomingByCityAndCategory(city1, category1, LocalDateTime.now(), pageable);

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
