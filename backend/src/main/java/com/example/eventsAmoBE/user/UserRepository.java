package com.example.eventsAmoBE.user;

import com.example.eventsAmoBE.user.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    @Query("SELECT u FROM User u LEFT JOIN FETCH u.savedEvents WHERE u.email = :email")
    Optional<User> findByEmailWithSavedEvents(@Param("email") String email);

    @Query("SELECT DISTINCT u FROM User u " +
            "LEFT JOIN FETCH u.attendingEvents e " +
            "LEFT JOIN FETCH e.attendees " +
            "WHERE u.email = :email")
    Optional<User> findByEmailWithAttendingEvents(@Param("email") String email);

}