package com.example.eventsAmoBE.user.services;

import com.example.eventsAmoBE.exceptions.UserNotFoundException;
import com.example.eventsAmoBE.user.UserRepository;
import com.example.eventsAmoBE.user.model.User;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserByIdService {

    private final UserRepository userRepository;

    public UserByIdService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(UserNotFoundException::new);
    }

    @Transactional
    @CacheEvict(value = "currentUser", allEntries = true)
    public void deleteUserById(Long id) {
        User user = getUserById(id);
        userRepository.delete(user);
    }

    @Transactional
    @CacheEvict(value = "currentUser", allEntries = true)
    public User updateUserById(Long id, User userDetails) {
        User user = getUserById(id);

        // Only update fields that can be modified
        user.setName(userDetails.getName());
        user.setLastName(userDetails.getLastName());
        // Password is updated separately through a specific endpoint

        return userRepository.save(user);
    }

    @Transactional
    @CacheEvict(value = "currentUser", allEntries = true)
    public User makeUserAdminByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));
        user.setAdmin(true);
        return userRepository.save(user);
    }
}
