-- Junction table for Event categories (@ElementCollection)
CREATE TABLE event_categories (
    event_id BIGINT NOT NULL,
    category VARCHAR(50) NOT NULL,  -- Enum stored as STRING
    CONSTRAINT fk_event_categories_event
        FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE
);

-- Index for better performance
CREATE INDEX idx_event_categories_event_id ON event_categories(event_id);