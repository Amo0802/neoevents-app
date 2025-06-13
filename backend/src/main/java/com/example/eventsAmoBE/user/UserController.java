package com.example.eventsAmoBE.user;

import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.event.model.EventDto;
import com.example.eventsAmoBE.event.model.EventRequestDto;
import com.example.eventsAmoBE.user.model.*;
import com.example.eventsAmoBE.user.services.*;
import com.example.eventsAmoBE.utils.EventMapper;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final CurrentUserService currentUserService;
    private final UserByIdService userByIdService;
    private final SaveEventService saveEventService;
    private final AttendEventService attendEventService;
    private final SubmitEventService submitEventService;
    private final ProfileUpdateService profileUpdateService;
    private final EventMapper eventMapper;

    @GetMapping("/{id}")
    @PreAuthorize("authentication.principal.id == #id or hasRole('ADMIN')")
    public ResponseEntity<UserDto> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(new UserDto(userByIdService.getUserById(id)));
    }

    @GetMapping("/current")
    public ResponseEntity<UserDto> getCurrentUser() {
        return ResponseEntity.ok(new UserDto(currentUserService.getCurrentUser()));
    }

    @DeleteMapping("/current")
    @Transactional
    public ResponseEntity<Void> deleteCurrentUser() {
        currentUserService.deleteCurrentUser();
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}")
    @PreAuthorize("authentication.principal.id == #id")
    public ResponseEntity<UserDto> updateUser(@PathVariable Long id, @RequestBody User user) {
        return ResponseEntity.ok(new UserDto(userByIdService.updateUserById(id, user)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("authentication.principal.id == #id or hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userByIdService.deleteUserById(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/profile")
    public ResponseEntity<UserDto> updateProfile(@RequestBody ProfileChangeRequest request) {
        User updatedUser = profileUpdateService.updateProfile(request.getNewName(), request.getNewLastName());
        return ResponseEntity.ok(new UserDto(updatedUser));
    }

    @PutMapping("/avatar")
    public ResponseEntity<UserDto> updateAvatar(@RequestBody AvatarUpdateRequest request) {
        User updatedUser = profileUpdateService.updateAvatar(request.getAvatarId());
        return ResponseEntity.ok(new UserDto(updatedUser));
    }

    @PutMapping("/password")
    public ResponseEntity<Void> updatePassword(@RequestBody PasswordChangeRequest request) {
        profileUpdateService.updatePassword(request.getCurrentPassword(), request.getNewPassword());
        return ResponseEntity.ok().build();
    }

//    @PutMapping("/email")
//    public ResponseEntity<Void> initiateEmailChange(@RequestBody EmailChangeRequest request) {
//        profileUpdateService.initiateEmailChange(request.getCurrentPassword(), request.getNewEmail());
//        return ResponseEntity.ok().build();
//    }

//    @PutMapping("/verify-email")
//    public ResponseEntity<UserDto> verifyEmailChange(@RequestBody VerificationRequest request) {
//        User updatedUser = profileUpdateService.completeEmailChange(request.getVerificationCode());
//        return ResponseEntity.ok(new UserDto(updatedUser));
//    }

    // Event saving functionality
    @PostMapping("/save-event/{eventId}")
    public ResponseEntity<Void> saveEvent(@PathVariable Long eventId) {
        saveEventService.saveEvent(eventId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/unsave-event/{eventId}")
    public ResponseEntity<Void> unsaveEvent(@PathVariable Long eventId) {
        saveEventService.unsaveEvent(eventId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/saved-events")
    public ResponseEntity<Set<EventDto>> getSavedEvents() {
        return ResponseEntity.ok(saveEventService.getSavedEvents());
    }

    // Event attending functionalities
    @PostMapping("/attend-event/{eventId}")
    public ResponseEntity<Void> attendEvent(@PathVariable Long eventId) {
        attendEventService.attendEvent(eventId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/unattend-event/{eventId}")
    public ResponseEntity<Void> unattendEvent(@PathVariable Long eventId) {
        attendEventService.unattendEvent(eventId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/attending-events")
    public ResponseEntity<Set<EventDto>> getAttendingEvents() {
        return ResponseEntity.ok(attendEventService.getAttendingEvents());
    }

    // For admin use only - to make another user an admin
    @PutMapping("/make-admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserDto> makeAdminByEmail(@RequestParam String email) {
        return ResponseEntity.ok(new UserDto(userByIdService.makeUserAdminByEmail(email)));
    }

    @PostMapping(value = "/submit-event", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('ADMIN') or hasAuthority('USER')")
    public ResponseEntity<Void> submitEvent(
            @Valid @RequestPart("event") EventRequestDto eventDto,
            @RequestPart(value = "images", required = false) List<MultipartFile> images) {

        User user = currentUserService.getCurrentUser();

        Event event = eventMapper.fromDto(eventDto);

        submitEventService.submitEventProposal(user, event, images);
        return ResponseEntity.ok().build();
    }
}
