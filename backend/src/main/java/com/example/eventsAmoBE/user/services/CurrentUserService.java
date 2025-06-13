package com.example.eventsAmoBE.user.services;

//import com.example.eventsAmoBE.event.model.City;
import com.example.eventsAmoBE.exceptions.UserNotFoundException;
import com.example.eventsAmoBE.user.UserRepository;
import com.example.eventsAmoBE.user.model.User;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class CurrentUserService {

    private final UserRepository userRepository;

    public CurrentUserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Cacheable(value = "currentUser")
    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(UserNotFoundException::new);
    }

    @CacheEvict(value = "currentUser", allEntries = true)
    public void deleteCurrentUser() {
        userRepository.delete(getCurrentUser());
    }

    public User getCurrentUserWithSavedEvents() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return userRepository.findByEmailWithSavedEvents(email)
                .orElseThrow(UserNotFoundException::new);
    }

    public User getCurrentUserWithAttendingEvents() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return userRepository.findByEmailWithAttendingEvents(email)
                .orElseThrow(UserNotFoundException::new);
    }

    public Optional<User> getOptionalCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated() ||
                "anonymousUser".equals(authentication.getPrincipal())) {
            return Optional.empty();
        }

        String email = authentication.getName();
        return userRepository.findByEmail(email);
    }

}
