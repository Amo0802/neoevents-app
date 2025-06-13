package com.example.eventsAmoBE.exceptions;

import lombok.Getter;

@Getter
public enum ErrorMessages {
    EVENT_NOT_FOUND("Event Not Found"),
    USER_NOT_FOUND("User not found"),
    INVALID_CREDENTIALS("Invalid email or password");


    private final String message;

    ErrorMessages(String message) {
        this.message = message;
    }

}