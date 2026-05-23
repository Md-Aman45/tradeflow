package com.tradeflow.tradeflow.controller;

import com.tradeflow.tradeflow.dto.wallet.WalletRequest;
import com.tradeflow.tradeflow.dto.wallet.WalletResponse;
import com.tradeflow.tradeflow.service.WalletService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;

    // GET /api/wallet — view my wallet
    @GetMapping
    public ResponseEntity<WalletResponse> getMyWallet(
            @AuthenticationPrincipal String email
    ) {
        return ResponseEntity.ok(walletService.getMyWallet(email));
    }

    // POST /api/wallet/add — add money
    @PostMapping("/add")
    public ResponseEntity<WalletResponse> addBalance(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody WalletRequest request
    ) {
        return ResponseEntity.ok(walletService.addBalance(email, request));
    }

    // POST /api/wallet/deduct — deduct money
    @PostMapping("/deduct")
    public ResponseEntity<WalletResponse> deductBalance(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody WalletRequest request
    ) {
        return ResponseEntity.ok(walletService.deductBalance(email, request));
    }
}