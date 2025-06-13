package com.example.eventsAmoBE.event.services;

import com.example.eventsAmoBE.event.EventRepository;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
//import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;


@Service
@Transactional
public class DeleteEventService {
    private final EventRepository eventRepository;
    private final EntityManager entityManager;

    public DeleteEventService(EventRepository eventRepository, EntityManager entityManager) {
        this.eventRepository = eventRepository;
        this.entityManager = entityManager;
    }

    //@CacheEvict(value = "events", allEntries = true)
    public Void execute(Long id) {
        // First, clear junction tables
        entityManager.createNativeQuery("DELETE FROM user_attending_events WHERE event_id = :eventId")
                .setParameter("eventId", id)
                .executeUpdate();

        entityManager.createNativeQuery("DELETE FROM user_saved_events WHERE event_id = :eventId")
                .setParameter("eventId", id)
                .executeUpdate();

        // Now safe to delete the event
        eventRepository.deleteById(id);
        return null;
    }
}