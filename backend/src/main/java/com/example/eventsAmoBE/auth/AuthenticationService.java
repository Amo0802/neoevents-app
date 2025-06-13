package com.example.eventsAmoBE.auth;

import com.example.eventsAmoBE.exceptions.UserNotFoundException;
import com.example.eventsAmoBE.security.JwtService;
import com.example.eventsAmoBE.user.model.User;
import com.example.eventsAmoBE.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthResponseDto register(RegisterRequestDto request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        var user = User.builder()
                .name(request.getName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .isAdmin(false) // Default to regular user
                .build();

        userRepository.save(user);
        var jwtToken = jwtService.generateToken(user);

        return AuthResponseDto.builder()
                .token(jwtToken)
                .build();
    }

    @CacheEvict(value = "currentUser", allEntries = true)
    public AuthResponseDto authenticate(AuthRequestDto request) {
        User user1 = userRepository.findByEmail(request.getEmail())
                .orElseThrow(UserNotFoundException::new);

        System.out.println("Password matches: " +
                passwordEncoder.matches(request.getPassword(), user1.getPassword()));
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        var user = userRepository.findByEmail(request.getEmail())
                .orElseThrow();

        var jwtToken = jwtService.generateToken(user);

        return AuthResponseDto.builder()
                .token(jwtToken)
                .build();
    }
}