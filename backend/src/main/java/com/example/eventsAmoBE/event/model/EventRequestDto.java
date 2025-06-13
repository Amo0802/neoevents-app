package com.example.eventsAmoBE.event.model;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

//This is Dto for SubmitEventService for sending email to admin
@Data
public class EventRequestDto {

    @NotBlank(message = "Event name is required")
    private String name;

    @NotBlank(message = "Description is required")
    private String description;

    @NotBlank(message = "Address is required")
    private String address;

    @NotBlank(message = "Start date and time is required")
    private String startDateTime; // as ISO string

    @NotBlank(message = "Price is required")
    private String price;

    @NotEmpty(message = "At least one category is required")
    private List<String> categories; // as list of strings
}
