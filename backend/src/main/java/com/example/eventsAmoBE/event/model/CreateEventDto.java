package com.example.eventsAmoBE.event.model;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Set;

@Data
public class CreateEventDto {
    @NotBlank(message = "Event name is required")
    private String name;

    @NotBlank(message = "Description is required")
    private String description;

    @NotBlank(message = "Image URL is required")
    private String imageUrl;

    @NotBlank(message = "Address is required")
    private String address;

    @NotNull(message = "Start date and time is required")
    @Future(message = "Event date must be in the future")
    private LocalDateTime startDateTime;

    @NotNull(message = "Price is required")
    @Min(value = 0, message = "Price cannot be negative")
    private Double price;

    @NotNull(message = "City is required")
    private City city;

    @NotEmpty(message = "At least one category is required")
    private Set<Category> categories;

    private int priority;
    private boolean mainEvent;
    private boolean promoted;
}