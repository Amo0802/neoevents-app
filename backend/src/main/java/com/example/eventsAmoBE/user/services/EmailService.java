//package com.example.eventsAmoBE.user.services;
//
//import jakarta.mail.MessagingException;
//import jakarta.mail.internet.MimeMessage;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.mail.javamail.JavaMailSender;
//import org.springframework.mail.javamail.MimeMessageHelper;
//import org.springframework.scheduling.annotation.Async;
//import org.springframework.stereotype.Service;
//
//@Service
//public class EmailService {
//
//    private final JavaMailSender mailSender;
//
//    @Autowired
//    public EmailService(JavaMailSender mailSender) {
//        this.mailSender = mailSender;
//    }
//
//    @Async
//    public void sendVerificationEmail(String to, String code) throws MessagingException {
//        MimeMessage message = mailSender.createMimeMessage();
//        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
//
//        helper.setTo(to);
//        helper.setSubject("NeoEvents Email Verification");
//
//        String htmlContent =
//                "<html><body>" +
//                        "<h2>Email Verification</h2>" +
//                        "<p>Your verification code is: <strong>" + code + "</strong></p>" +
//                        "<p>This code will expire in 15 minutes.</p>" +
//                        "<p>If you did not request this change, please ignore this email.</p>" +
//                        "</body></html>";
//
//        helper.setText(htmlContent, true);
//
//        mailSender.send(message);
//    }
//}