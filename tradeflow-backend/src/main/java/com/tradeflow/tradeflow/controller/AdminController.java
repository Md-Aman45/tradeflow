package com.tradeflow.tradeflow.controller;

import com.tradeflow.tradeflow.dto.admin.UserResponse;
import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')") // entire controller is ADMIN only
public class AdminController {

    private final AdminService adminService;

    // ── USER MANAGEMENT ──────────────────────────────────────────

    // GET /api/admin/users
    @GetMapping("/users")
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    // PUT /api/admin/users/{id}/make-admin
    @PutMapping("/users/{id}/make-admin")
    public ResponseEntity<String> makeAdmin(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.makeAdmin(id));
    }

    // PUT /api/admin/users/{id}/make-user
    @PutMapping("/users/{id}/make-user")
    public ResponseEntity<String> makeUser(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.makeUser(id));
    }

    // DELETE /api/admin/users/{id}
    @DeleteMapping("/users/{id}")
    public ResponseEntity<String> deleteUser(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.deleteUser(id));
    }

    // ── STOCK MANAGEMENT ─────────────────────────────────────────

    // POST /api/admin/stocks
    @PostMapping("/stocks")
    public ResponseEntity<String> createStock(@Valid @RequestBody CreateStockRequest request) {
        return new ResponseEntity<>(adminService.createStock(request), HttpStatus.CREATED);
    }

    // PUT /api/admin/stocks/{id}
    @PutMapping("/stocks/{id}")
    public ResponseEntity<Stock> updateStock(
            @PathVariable Long id,
            @Valid @RequestBody CreateStockRequest request
    ) {
        return ResponseEntity.ok(adminService.updateStock(id, request));
    }

    // DELETE /api/admin/stocks/{id}
    @DeleteMapping("/stocks/{id}")
    public ResponseEntity<String> deleteStock(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.deleteStock(id));
    }
}