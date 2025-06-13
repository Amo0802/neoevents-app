package com.example.eventsAmoBE.user.services;

import com.example.eventsAmoBE.event.model.Event;
import com.example.eventsAmoBE.user.model.User;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
public class SubmitEventService {

    private final JavaMailSender mailSender;

    public SubmitEventService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Async
    public void submitEventProposal(User user, Event event, List<MultipartFile> images)  {

        // Send email to admin with event proposal
        try {
            sendEventProposalEmail(user, event, images);
        } catch (MessagingException e) {
            throw new RuntimeException("Failed to send event proposal email", e);
        }
    }

    private void sendEventProposalEmail(User user, Event event, List<MultipartFile> images) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true);

        helper.setTo("arminramusovic11@gmail.com"); // Replace with your admin email
        helper.setSubject("New Event Proposal");

        String content = String.format(
                "Event Proposal from: %s %s (%s)\n\n" +
                        "Event Details:\n" +
                        "Name: %s\n" +
                        "Description: %s\n" +
                        "Address: %s\n" +
                        "Date & Time: %s\n" +
                        "Price: %s\n" +
                        "Categories: %s\n",
                user.getName(), user.getLastName(), user.getEmail(),
                event.getName(), event.getDescription(), event.getAddress(),
                event.getStartDateTime(), event.getPrice(), event.getCategories()
        );

        // Check if we need to add a message about images
        StringBuilder imageMessage = new StringBuilder();
        if (images != null && !images.isEmpty()) {
            boolean imagesFailed = false;
            for (int i = 0; i < images.size(); i++) {
                try {
                    MultipartFile image = images.get(i);
                    String originalFilename = image.getOriginalFilename();
                    String extension = originalFilename != null ?
                            originalFilename.substring(originalFilename.lastIndexOf(".")) : ".jpg";
                    String filename = "event-image-" + (i + 1) + "-" + System.currentTimeMillis() + extension;
                    helper.addAttachment(filename, new ByteArrayResource(image.getBytes()));
                } catch (IOException e) {
                    // Log the error and mark the image process as failed
                    System.err.println("Failed to process image attachment: " + e.getMessage());
                    imagesFailed = true;
                }
            }

            // Add a message to the email body if images couldn't be loaded
            if (imagesFailed) {
                imageMessage.append("\n\nUnfortunately, some or all images could not be loaded.");
            }
        }

        // Add the message about images to the email content
        content += imageMessage.toString();
        helper.setText(content);

        // Send the email without the images if any image fails to process
        mailSender.send(message);
    }
}
