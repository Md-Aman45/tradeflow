package com.tradeflow.tradeflow.service;

import com.tradeflow.tradeflow.dto.portfolio.PortfolioResponse;
import com.tradeflow.tradeflow.dto.portfolio.TradeRequest;
import com.tradeflow.tradeflow.dto.portfolio.TransactionResponse;
import com.tradeflow.tradeflow.entity.*;
import com.tradeflow.tradeflow.entity.Transaction.TransactionType;
import com.tradeflow.tradeflow.exception.BadRequestException;
import com.tradeflow.tradeflow.exception.InsufficientBalanceException;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PortfolioService {

    private final PortfolioRepository portfolioRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final StockRepository stockRepository;
    private final WalletRepository walletRepository;

    // ── BUY STOCK ────────────────────────────────────────────────
    @Transactional
    public String buyStock(String email, TradeRequest request) {

        User user = getUserByEmail(email);
        Stock stock = getStockById(request.getStockId());
        Wallet wallet = getWalletByUserId(user.getId());

        BigDecimal totalCost = stock.getPrice()
                .multiply(BigDecimal.valueOf(request.getQuantity()));

        // Check wallet balance
        if (wallet.getBalance().compareTo(totalCost) < 0) {
            throw new InsufficientBalanceException(
                "Insufficient balance. Required: " + totalCost + ", Available: " + wallet.getBalance()
            );
        }

        // Deduct from wallet
        wallet.setBalance(wallet.getBalance().subtract(totalCost));
        walletRepository.save(wallet);

        // Add to portfolio (or update if already owns this stock)
        var existingPortfolio = portfolioRepository.findByUserIdAndStockId(user.getId(), stock.getId());

        if (existingPortfolio.isPresent()) {
            // Update existing — recalculate average buy price
            Portfolio portfolio = existingPortfolio.get();
            int newQuantity = portfolio.getQuantity() + request.getQuantity();
            BigDecimal totalPaid = portfolio.getAverageBuyPrice()
                    .multiply(BigDecimal.valueOf(portfolio.getQuantity()))
                    .add(totalCost);
            BigDecimal newAvgPrice = totalPaid.divide(
                    BigDecimal.valueOf(newQuantity), 2, RoundingMode.HALF_UP);

            portfolio.setQuantity(newQuantity);
            portfolio.setAverageBuyPrice(newAvgPrice);
            portfolioRepository.save(portfolio);
        } else {
            // Create new portfolio entry
            Portfolio portfolio = Portfolio.builder()
                    .user(user)
                    .stock(stock)
                    .quantity(request.getQuantity())
                    .averageBuyPrice(stock.getPrice())
                    .build();
            portfolioRepository.save(portfolio);
        }

        // Save transaction history
        saveTransaction(user, stock, TransactionType.BUY, request.getQuantity(), stock.getPrice(), totalCost);

        return "Successfully bought " + request.getQuantity() + " shares of " + stock.getSymbol();
    }

    // ── SELL STOCK ───────────────────────────────────────────────
    @Transactional
    public String sellStock(String email, TradeRequest request) {

        User user = getUserByEmail(email);
        Stock stock = getStockById(request.getStockId());
        Wallet wallet = getWalletByUserId(user.getId());

        // Check if user owns this stock
        Portfolio portfolio = portfolioRepository.findByUserIdAndStockId(user.getId(), stock.getId())
                .orElseThrow(() -> new BadRequestException(
                    "You don't own any shares of " + stock.getSymbol()
                ));

        // Check if user has enough shares
        if (portfolio.getQuantity() < request.getQuantity()) {
            throw new BadRequestException(
                "Insufficient shares. You own " + portfolio.getQuantity() +
                " shares but tried to sell " + request.getQuantity()
            );
        }

        BigDecimal totalEarned = stock.getPrice()
                .multiply(BigDecimal.valueOf(request.getQuantity()));

        // Add money back to wallet
        wallet.setBalance(wallet.getBalance().add(totalEarned));
        walletRepository.save(wallet);

        // Update portfolio
        int remainingShares = portfolio.getQuantity() - request.getQuantity();

        if (remainingShares == 0) {
            portfolioRepository.delete(portfolio); // remove if sold all shares
        } else {
            portfolio.setQuantity(remainingShares);
            portfolioRepository.save(portfolio);
        }

        // Save transaction history
        saveTransaction(user, stock, TransactionType.SELL, request.getQuantity(), stock.getPrice(), totalEarned);

        return "Successfully sold " + request.getQuantity() + " shares of " + stock.getSymbol();
    }

    // ── VIEW PORTFOLIO ───────────────────────────────────────────
    public List<PortfolioResponse> getMyPortfolio(String email) {
        User user = getUserByEmail(email);
        List<Portfolio> portfolios = portfolioRepository.findByUserId(user.getId());

        return portfolios.stream().map(p -> {
            BigDecimal currentPrice = p.getStock().getPrice();
            BigDecimal totalValue = currentPrice.multiply(BigDecimal.valueOf(p.getQuantity()));
            BigDecimal invested = p.getAverageBuyPrice().multiply(BigDecimal.valueOf(p.getQuantity()));
            BigDecimal profitOrLoss = totalValue.subtract(invested);

            return new PortfolioResponse(
                    p.getId(),
                    p.getStock().getSymbol(),
                    p.getStock().getCompanyName(),
                    p.getQuantity(),
                    p.getAverageBuyPrice(),
                    currentPrice,
                    totalValue,
                    profitOrLoss
            );
        }).collect(Collectors.toList());
    }

    // ── TRANSACTION HISTORY ──────────────────────────────────────
    public List<TransactionResponse> getMyTransactions(String email) {
        User user = getUserByEmail(email);
        List<Transaction> transactions = transactionRepository
                .findByUserIdOrderByCreatedAtDesc(user.getId());

        return transactions.stream().map(t -> new TransactionResponse(
                t.getId(),
                t.getType(),
                t.getStock() != null ? t.getStock().getSymbol() : "WALLET",
                t.getQuantity(),
                t.getPrice(),
                t.getTotalAmount(),
                t.getCreatedAt()
        )).collect(Collectors.toList());
    }

    // ── PRIVATE HELPERS ──────────────────────────────────────────
    private void saveTransaction(User user, Stock stock, TransactionType type,
                                  Integer quantity, BigDecimal price, BigDecimal total) {
        Transaction transaction = Transaction.builder()
                .user(user)
                .stock(stock)
                .type(type)
                .quantity(quantity)
                .price(price)
                .totalAmount(total)
                .build();
        transactionRepository.save(transaction);
    }

    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }

    private Stock getStockById(Long id) {
        return stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id));
    }

    private Wallet getWalletByUserId(Long userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found for user: " + userId));
    }
}