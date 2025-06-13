package com.example.eventsAmoBE.user.model;

import lombok.Data;

@Data
public class UserDto {

    private Long id;
    private String name;
    private String lastName;
    private String email;
    private boolean isAdmin;
    private int avatarId;

    public UserDto(User user){

        this.id = user.getId();
        this.name = user.getName();
        this.lastName = user.getLastName();
        this.email = user.getEmail();
        this.isAdmin = user.isAdmin();
        this.avatarId = user.getAvatarId() != null ? user.getAvatarId() : 0;
    }
}
