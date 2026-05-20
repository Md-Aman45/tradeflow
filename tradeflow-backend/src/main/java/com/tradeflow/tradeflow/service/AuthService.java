package com.tradeflow.tradeflow.service;


import com.tradeflow.tradeflow.dto.auth.LoginRequest;
import com.tradeflow.tradeflow.dto.auth.RegisterRequest;
import com.tradeflow.tradeflow.entity.User;
import com.tradeflow.tradeflow.entity.Wallet;
import com.tradeflow.tradeflow.repository.UserRepository;
import com.tradeflow.tradeflow.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final PasswordEncoder passwordEncoder;

    public String register(RegisterRequest request) {

        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .build();

        userRepository.save(user);

        Wallet wallet = Wallet.builder()
                .user(user)
                .balance(new BigDecimal("100000"))
                .build();
        
        walletRepository.save(wallet);

        return "User registered successfully";
    }



    public String login(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        boolean matches = passwordEncoder.matches(
            request.getPassword(),
            user.getPassword()
        );

        if (!matches) {
            throw new RuntimeException("Invalid credentials");
        }

        return "Login successful";
    }
}
