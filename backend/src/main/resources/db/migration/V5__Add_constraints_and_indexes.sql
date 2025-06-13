-- Add constraints for enum validation (optional but good practice)
ALTER TABLE event
ADD CONSTRAINT check_city
CHECK (city IN ('PODGORICA', 'BERANE', 'NIKSIC'));

ALTER TABLE event_categories
ADD CONSTRAINT check_category
CHECK (category IN ('MUSIC', 'SPORTS', 'FOOD', 'ART', 'TECHNOLOGY'));

-- Additional indexes for common queries
CREATE INDEX idx_event_start_date_time ON event(start_date_time);
CREATE INDEX idx_event_city ON event(city);
CREATE INDEX idx_event_main_event ON event(main_event);
CREATE INDEX idx_event_promoted ON event(promoted);
CREATE INDEX idx_users_email ON users(email);