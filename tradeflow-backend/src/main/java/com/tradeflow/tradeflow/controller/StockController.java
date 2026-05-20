package com.tradeflow.tradeflow.controller;

import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
public class StockController {
    
    private final StockService stockService;

    @PostMapping
    public String createStock(@RequestBody CreateStockRequest request) {
        return stockService.createStock(request);
    }
}
