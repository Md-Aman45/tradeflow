package com.tradeflow.tradeflow.service;

import com.tradeflow.tradeflow.dto.admin.UserResponse;
import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.entity.User;
import com.tradeflow.tradeflow.exception.BadRequestException;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final StockService stockService; // delegate stock work here so Redis cache evicts correctly

    // ── USER MANAGEMENT ──────────────────────────────────────────

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(u -> new UserResponse(u.getId(), u.getName(), u.getEmail(), u.getRole()))
                .collect(Collectors.toList());
    }

    public String makeAdmin(Long userId) {
        User user = getUserById(userId);
        if (user.getRole().equals("ADMIN")) {
            throw new BadRequestException("User is already an ADMIN");
        }
        user.setRole("ADMIN");
        userRepository.save(user);
        return user.getName() + " is now an ADMIN";
    }

    public String makeUser(Long userId) {
        User user = getUserById(userId);
        if (user.getRole().equals("USER")) {
            throw new BadRequestException("User already has USER role");
        }
        user.setRole("USER");
        userRepository.save(user);
        return user.getName() + " is now a USER";
    }

    public String deleteUser(Long userId) {
        User user = getUserById(userId);
        userRepository.delete(user);
        return "User " + user.getEmail() + " deleted successfully";
    }

    // ── STOCK MANAGEMENT ─────────────────────────────────────────
    // All three now delegate to StockService, which has @CacheEvict
    // on create/update/delete — this is what was missing before,
    // causing newly added stocks to not appear due to stale Redis cache.

    public String createStock(CreateStockRequest request) {
        return stockService.createStock(request);
    }

    public Stock updateStock(Long stockId, CreateStockRequest request) {
        return stockService.updateStock(stockId, request);
    }

    public String deleteStock(Long stockId) {
        return stockService.deleteStock(stockId);
    }

    // ── PRIVATE HELPERS ──────────────────────────────────────────

    private User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", id));
    }
}