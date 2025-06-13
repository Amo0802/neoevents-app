package com.example.eventsAmoBE.exceptions;

import lombok.Getter;
import java.util.List;

@Getter
public class ErrorResponse {
    private final List<String> messages;

    public ErrorResponse(List<String> messages) {
        this.messages = messages;
    }

    public ErrorResponse(String message) {
        this.messages = List.of(message);
    }
}
