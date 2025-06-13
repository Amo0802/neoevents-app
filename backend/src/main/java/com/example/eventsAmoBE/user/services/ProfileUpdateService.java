package com.example.eventsAmoBE.user.services;

import com.example.eventsAmoBE.user.UserRepository;
import com.example.eventsAmoBE.user.model.ProfileChangeRequest;
import com.example.eventsAmoBE.user.model.User;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileUpdateService {

    private final UserRepository userRepository;
    private final CurrentUserService currentUserService;
    private final PasswordEncoder passwordEncoder;

    public ProfileUpdateService(UserRepository userRepository, CurrentUserService currentUserService, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.currentUserService = currentUserService;
        this.passwordEncoder = passwordEncoder;
    }
//    private final EmailVerificationService emailVerificationService;
//    private final EmailService emailService;

    @Transactional
    public User updateProfile(String newName, String newLastName) {
        // Get current user
        User currentUser = currentUserService.getCurrentUser();

        // Update only name and lastName
        currentUser.setName(newName);
        currentUser.setLastName(newLastName);
        userRepository.save(currentUser);

        return currentUser;
    }

    @Transactional
    public User updateAvatar(int avatarId) {
        // Get current user
        User currentUser = currentUserService.getCurrentUser();

        // Update avatar ID
        currentUser.setAvatarId(avatarId);
        userRepository.save(currentUser);

        return currentUser;
    }

    @Transactional
    public void updatePassword(String currentPassword, String newPassword) {
        // Get current user
        User currentUser = currentUserService.getCurrentUser();

        // Verify current password
        if (!passwordEncoder.matches(currentPassword, currentUser.getPassword())) {
            throw new BadCredentialsException("Current password is incorrect");
        }

        // Update password with encoded new password
        currentUser.setPassword(passwordEncoder.encode(newPassword));

        userRepository.save(currentUser);
    }

//    @Transactional
//    public void initiateEmailChange(String currentPassword, String newEmail) {
//        // Get current user
//        User currentUser = currentUserService.getCurrentUser();
//
//        // Verify current password
//        if (!passwordEncoder.matches(currentPassword, currentUser.getPassword())) {
//            throw new BadCredentialsException("Current password is incorrect");
//        }
//
//        // Check if email already exists
//        if (userRepository.existsByEmail(newEmail)) {
//            throw new RuntimeException("Email already registered");
//        }
//
//        // Generate verification code
//        String code = emailVerificationService.generateVerificationCode(currentUser.getId(), newEmail);
//
//        // Send verification email
//        try {
//            emailService.sendVerificationEmail(newEmail, code);
//        } catch (MessagingException e) {
//            throw new RuntimeException("Failed to send verification email", e);
//        }
//    }
//
//    @Transactional
//    public User completeEmailChange(String verificationCode) {
//        // Get current user
//        User currentUser = currentUserService.getCurrentUser();
//
//        // Verify code
//        boolean isValid = emailVerificationService.verifyCode(currentUser.getId(), verificationCode);
//        if (!isValid) {
//            throw new RuntimeException("Invalid or expired verification code");
//        }
//
//        // Get pending email
//        String newEmail = emailVerificationService.getPendingEmail(currentUser.getId());
//        if (newEmail == null) {
//            throw new RuntimeException("No pending email change found");
//        }
//
//        // Update email
//        currentUser.setEmail(newEmail);
//
//        return userRepository.save(currentUser);
//    }
}