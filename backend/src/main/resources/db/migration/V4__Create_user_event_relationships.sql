-- Junction table for saved events (Many-to-Many)
CREATE TABLE user_saved_events (
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, event_id),
    CONSTRAINT fk_user_saved_events_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_saved_events_event
        FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE
);

-- Junction table for attending events (Many-to-Many)
CREATE TABLE user_attending_events (
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, event_id),
    CONSTRAINT fk_user_attending_events_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_attending_events_event
        FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE
);

-- Indexes for better query performance
CREATE INDEX idx_user_saved_events_user_id ON user_saved_events(user_id);
CREATE INDEX idx_user_saved_events_event_id ON user_saved_events(event_id);
CREATE INDEX idx_user_attending_events_user_id ON user_attending_events(user_id);
CREATE INDEX idx_user_attending_events_event_id ON user_attending_events(event_id);