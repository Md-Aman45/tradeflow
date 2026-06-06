package com.tradeflow.tradeflow.service;

import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StockService {

    private final StockRepository stockRepository;

    // ── CREATE ───────────────────────────────────────────────────
    @CacheEvict(value = "stocks", allEntries = true) // clear cache when new stock added
    public String createStock(CreateStockRequest request) {
        Stock stock = Stock.builder()
                .symbol(request.getSymbol())
                .companyName(request.getCompanyName())
                .price(request.getPrice())
                .changePercent(request.getChangePercent())
                .marketStatus(request.getMarketStatus())
                .build();
        stockRepository.save(stock);
        return "Stock created successfully";
    }

    // ── GET ALL ──────────────────────────────────────────────────
    @Cacheable(value = "stocks") // cache all stocks — returns from Redis if available
    public List<Stock> getAllStocks() {
        return stockRepository.findAll();
    }

    // ── GET BY ID ────────────────────────────────────────────────
    @Cacheable(value = "stock", key = "#id") // cache individual stock by id
    public Stock getStockById(Long id) {
        return stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id));
    }

    // ── UPDATE ───────────────────────────────────────────────────
    @CacheEvict(value = {"stocks", "stock"}, allEntries = true) // clear all stock caches
    public Stock updateStock(Long id, CreateStockRequest request) {
        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id));
        stock.setSymbol(request.getSymbol());
        stock.setCompanyName(request.getCompanyName());
        stock.setPrice(request.getPrice());
        stock.setChangePercent(request.getChangePercent());
        stock.setMarketStatus(request.getMarketStatus());
        return stockRepository.save(stock);
    }

    // ── DELETE ───────────────────────────────────────────────────
    @CacheEvict(value = {"stocks", "stock"}, allEntries = true) // clear all stock caches
    public String deleteStock(Long id) {
        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id));
        stockRepository.delete(stock);
        return "Stock deleted successfully";
    }
}