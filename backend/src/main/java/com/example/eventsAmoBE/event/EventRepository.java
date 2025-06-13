package com.example.eventsAmoBE.event;

import com.example.eventsAmoBE.event.model.Category;
import com.example.eventsAmoBE.event.model.City;
import com.example.eventsAmoBE.event.model.Event;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {

    @Query("""
    SELECT e FROM Event e
    WHERE e.startDateTime > :now
    ORDER BY e.startDateTime ASC
""")
    Page<Event> findUpcomingEvents(@Param("now") LocalDateTime now, Pageable pageable);

    @Query("""
    SELECT e FROM Event e
    WHERE e.mainEvent = true
    AND e.startDateTime > :now
    ORDER BY e.priority DESC, e.startDateTime ASC
""")
    Page<Event> findUpcomingMainEvents(@Param("now") LocalDateTime now, Pageable pageable);

    @Query("""
    SELECT e FROM Event e
    WHERE e.startDateTime > :now AND (
        LOWER(e.name) LIKE LOWER(CONCAT('%', :text, '%')) OR
        LOWER(e.description) LIKE LOWER(CONCAT('%', :text, '%'))
    )
    ORDER BY e.startDateTime ASC
""")
    Page<Event> searchUpcomingByNameOrDescription(@Param("text") String text, @Param("now") LocalDateTime now, Pageable pageable);

    @Query("""
    SELECT DISTINCT e FROM Event e
    JOIN e.categories c
    WHERE (:category IS NULL OR c = :category)
    AND (:city IS NULL OR e.city = :city)
    AND e.startDateTime > :now
    ORDER BY e.startDateTime ASC
""")
    Page<Event> findUpcomingByCityAndCategory(
            @Param("city") City city,
            @Param("category") Category category,
            @Param("now") LocalDateTime now,
            Pageable pageable
    );


    @Query("""
    SELECT e FROM Event e
    WHERE e.promoted = true
    AND e.startDateTime > :now
    ORDER BY e.priority DESC, e.startDateTime ASC
""")
    Page<Event> findUpcomingPromotedEvents(@Param("now") LocalDateTime now, Pageable pageable);
}