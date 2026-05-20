package com.tradeflow.tradeflow.controller;


import com.tradeflow.tradeflow.dto.auth.LoginRequest;
import com.tradeflow.tradeflow.dto.auth.RegisterRequest;
import com.tradeflow.tradeflow.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;

    @PostMapping("/register")
    public String register(@RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public String login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }
}
