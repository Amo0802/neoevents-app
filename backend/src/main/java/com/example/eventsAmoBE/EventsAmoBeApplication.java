package com.example.eventsAmoBE;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class EventsAmoBeApplication {

	public static void main(String[] args) {
		SpringApplication.run(EventsAmoBeApplication.class, args);
	}

}
