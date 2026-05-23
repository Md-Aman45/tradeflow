package com.tradeflow.tradeflow.controller;

import com.tradeflow.tradeflow.dto.portfolio.PortfolioResponse;
import com.tradeflow.tradeflow.dto.portfolio.TradeRequest;
import com.tradeflow.tradeflow.dto.portfolio.TransactionResponse;
import com.tradeflow.tradeflow.service.PortfolioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/portfolio")
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;

    // POST /api/portfolio/buy
    @PostMapping("/buy")
    public ResponseEntity<String> buyStock(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody TradeRequest request
    ) {
        return ResponseEntity.ok(portfolioService.buyStock(email, request));
    }

    // POST /api/portfolio/sell
    @PostMapping("/sell")
    public ResponseEntity<String> sellStock(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody TradeRequest request
    ) {
        return ResponseEntity.ok(portfolioService.sellStock(email, request));
    }

    // GET /api/portfolio
    @GetMapping
    public ResponseEntity<List<PortfolioResponse>> getMyPortfolio(
            @AuthenticationPrincipal String email
    ) {
        return ResponseEntity.ok(portfolioService.getMyPortfolio(email));
    }

    // GET /api/portfolio/transactions
    @GetMapping("/transactions")
    public ResponseEntity<List<TransactionResponse>> getMyTransactions(
            @AuthenticationPrincipal String email
    ) {
        return ResponseEntity.ok(portfolioService.getMyTransactions(email));
    }
}