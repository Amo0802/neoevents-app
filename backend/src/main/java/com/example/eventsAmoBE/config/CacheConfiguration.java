package com.example.eventsAmoBE.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
@EnableCaching
public class CacheConfiguration {
    @Bean
    public CacheManager eventCacheManager() {
        CaffeineCacheManager mgr = new CaffeineCacheManager("currentUser"); //"events", "mainEvents", "promotedEvents",
        mgr.setCaffeine(Caffeine.newBuilder()
                .initialCapacity(50)
                .maximumSize(500)
                .expireAfterWrite(24, TimeUnit.HOURS)
                .recordStats());
        return mgr;
    }
}