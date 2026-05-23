package com.tradeflow.tradeflow.service;

import com.tradeflow.tradeflow.dto.wallet.WalletRequest;
import com.tradeflow.tradeflow.dto.wallet.WalletResponse;
import com.tradeflow.tradeflow.entity.User;
import com.tradeflow.tradeflow.entity.Wallet;
import com.tradeflow.tradeflow.exception.InsufficientBalanceException;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.UserRepository;
import com.tradeflow.tradeflow.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;

    // Get wallet of logged-in user
    public WalletResponse getMyWallet(String email) {
        User user = getUserByEmail(email);
        Wallet wallet = getWalletByUserId(user.getId());
        return toResponse(wallet);
    }

    // Add money to wallet
    public WalletResponse addBalance(String email, WalletRequest request) {
        User user = getUserByEmail(email);
        Wallet wallet = getWalletByUserId(user.getId());

        wallet.setBalance(wallet.getBalance().add(request.getAmount()));
        walletRepository.save(wallet);

        return toResponse(wallet);
    }

    // Deduct money from wallet
    public WalletResponse deductBalance(String email, WalletRequest request) {
        User user = getUserByEmail(email);
        Wallet wallet = getWalletByUserId(user.getId());

        if (wallet.getBalance().compareTo(request.getAmount()) < 0) {
            throw new InsufficientBalanceException();
        }

        wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
        walletRepository.save(wallet);

        return toResponse(wallet);
    }

    // ── private helpers ──────────────────────────────────────────

    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));
    }

    private Wallet getWalletByUserId(Long userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found for user id: " + userId));
    }

    private WalletResponse toResponse(Wallet wallet) {
        return new WalletResponse(
                wallet.getId(),
                wallet.getUser().getEmail(),
                wallet.getBalance()
        );
    }
}