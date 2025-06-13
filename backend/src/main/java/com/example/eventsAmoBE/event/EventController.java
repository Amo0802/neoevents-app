package com.example.eventsAmoBE.event;

import com.example.eventsAmoBE.event.model.CreateEventDto;
import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.event.services.*;
import com.example.eventsAmoBE.utils.PageResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;

@RestController
@RequiredArgsConstructor
public class EventController {

    private final CreateEventService createEventService;
    private final DeleteEventService deleteEventService;
    private final GetFilteredEventsService getFilteredEventsService;
    private final GetEventService getEventService;
    private final GetEventsService getEventsService;
    private final GetMainEventsService getMainEventsService;
    private final GetPromotedEventsService getPromotedEventsService;
    private final SearchEventService searchEventService;
    private final UpdateEventService updateEventService;

    @PostMapping("/event")
    public ResponseEntity<EventDto> createEvent(@Valid @RequestBody CreateEventDto event) {
        Event response = createEventService.execute(event);
        URI location = URI.create("/event/" + response.getId());
        return ResponseEntity.created(location).body(new EventDto(response));
    }

    @DeleteMapping("event/{id}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long id) {
        deleteEventService.execute(id);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }

    @GetMapping("eventGet/{id}")
    public ResponseEntity<EventDto> getEvent(@PathVariable Long id) {
        EventDto response = getEventService.execute(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/event/{id}")
    public ResponseEntity<EventDto> updateEvent(@PathVariable Long id, @RequestBody Event event) {
        Event response = updateEventService.execute(id, event);
        return ResponseEntity.ok(new EventDto(response));
    }

    @GetMapping("/events")
    public ResponseEntity<PageResponse<EventDto>> getEvents(
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<EventDto> response = getEventsService.execute(pageable);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/event/filter")
    public ResponseEntity<PageResponse<EventDto>> getEventsByCategory(
            @RequestParam String city,
            @RequestParam String category,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<EventDto> response = getFilteredEventsService.execute(pageable, city, category);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/event/main")
    public ResponseEntity<PageResponse<EventDto>> getMainEvents(
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<EventDto> response = getMainEventsService.execute(pageable);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/event/promoted")
    public ResponseEntity<PageResponse<EventDto>> getPromotedEvents(
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<EventDto> response = getPromotedEventsService.execute(pageable);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/event/search")
    public ResponseEntity<PageResponse<EventDto>> searchEvents(
            @RequestParam String search,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        PageResponse<EventDto> response = searchEventService.execute(search, pageable);

        return ResponseEntity.ok(response);
    }
}
