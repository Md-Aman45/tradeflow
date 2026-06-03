package com.tradeflow.tradeflow.service;

import com.tradeflow.tradeflow.dto.admin.UserResponse;
import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.entity.User;
import com.tradeflow.tradeflow.exception.BadRequestException;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.StockRepository;
import com.tradeflow.tradeflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final StockRepository stockRepository;

    // ── USER MANAGEMENT ──────────────────────────────────────────

    // Get all users
    public List<UserResponse> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(u -> new UserResponse(u.getId(), u.getName(), u.getEmail(), u.getRole()))
                .collect(Collectors.toList());
    }

    // Promote user to ADMIN
    public String makeAdmin(Long userId) {
        User user = getUserById(userId);
        if (user.getRole().equals("ADMIN")) {
            throw new BadRequestException("User is already an ADMIN");
        }
        user.setRole("ADMIN");
        userRepository.save(user);
        return user.getName() + " is now an ADMIN";
    }

    // Demote admin back to USER
    public String makeUser(Long userId) {
        User user = getUserById(userId);
        if (user.getRole().equals("USER")) {
            throw new BadRequestException("User already has USER role");
        }
        user.setRole("USER");
        userRepository.save(user);
        return user.getName() + " is now a USER";
    }

    // Delete user
    public String deleteUser(Long userId) {
        User user = getUserById(userId);
        userRepository.delete(user);
        return "User " + user.getEmail() + " deleted successfully";
    }

    // ── STOCK MANAGEMENT ─────────────────────────────────────────

    // Admin create stock
    public String createStock(CreateStockRequest request) {
        Stock stock = Stock.builder()
                .symbol(request.getSymbol())
                .companyName(request.getCompanyName())
                .price(request.getPrice())
                .changePercent(request.getChangePercent())
                .marketStatus(request.getMarketStatus())
                .build();
        stockRepository.save(stock);
        return "Stock " + request.getSymbol() + " created successfully";
    }

    // Admin update stock
    public Stock updateStock(Long stockId, CreateStockRequest request) {
        Stock stock = stockRepository.findById(stockId)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", stockId));
        stock.setSymbol(request.getSymbol());
        stock.setCompanyName(request.getCompanyName());
        stock.setPrice(request.getPrice());
        stock.setChangePercent(request.getChangePercent());
        stock.setMarketStatus(request.getMarketStatus());
        return stockRepository.save(stock);
    }

    // Admin delete stock
    public String deleteStock(Long stockId) {
        Stock stock = stockRepository.findById(stockId)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", stockId));
        stockRepository.delete(stock);
        return "Stock " + stock.getSymbol() + " deleted successfully";
    }

    // ── PRIVATE HELPERS ──────────────────────────────────────────

    private User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", id));
    }
}