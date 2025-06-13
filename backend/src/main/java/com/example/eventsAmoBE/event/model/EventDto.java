package com.example.eventsAmoBE.event.model;

import com.example.eventsAmoBE.user.model.User;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Set;

@Data
public class EventDto {

    private Long id;
    private String name;
    private String description;
    private String imageUrl;
    private City city;
    private String address;
    private LocalDateTime startDateTime;
    private Double price;
    private Set<Category> categories;
    private int priority;
    private boolean mainEvent;
    private boolean promoted;

    public EventDto(Event event) {
        this.id = event.getId();
        this.name = event.getName();
        this.description = event.getDescription();
        this.imageUrl = event.getImageUrl();
        this.city = event.getCity();
        this.address = event.getAddress();
        this.startDateTime = event.getStartDateTime();
        this.price = event.getPrice();
        this.categories = event.getCategories();
        this.priority = event.getPriority();
        this.mainEvent = event.isMainEvent();
        this.promoted = event.isPromoted();
    }
}
