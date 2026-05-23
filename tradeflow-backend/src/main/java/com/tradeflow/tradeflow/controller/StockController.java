package com.tradeflow.tradeflow.controller;

import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.service.StockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
public class StockController {

    private final StockService stockService;

    @PostMapping
    public String createStock(@Valid @RequestBody CreateStockRequest request) {
        return stockService.createStock(request);
    }

    @GetMapping
    public List<Stock> getAllStocks() {
        return stockService.getAllStocks();
    }

    @GetMapping("/{id}")
    public Stock getStockById(@PathVariable Long id) {
        return stockService.getStockById(id);
    }

    @PutMapping("/{id}")
    public Stock updateStock(
            @PathVariable Long id,
            @Valid @RequestBody CreateStockRequest request 
    ) {
        return stockService.updateStock(id, request);
    }

    @DeleteMapping("/{id}")
    public String deleteStock(@PathVariable Long id) {
        return stockService.deleteStock(id);
    }
}