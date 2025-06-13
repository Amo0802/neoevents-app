package com.example.eventsAmoBE.auth;

import lombok.Data;

@Data
public class AuthRequestDto {
    private String email;
    private String password;
}
