package com.example.eventsAmoBE.user.model;

import lombok.Data;

@Data
public class ProfileChangeRequest {
    String newName;
    String newLastName;
}
