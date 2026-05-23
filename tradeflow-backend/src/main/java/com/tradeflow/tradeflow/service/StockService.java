package com.tradeflow.tradeflow.service;


import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.exception.ResourceNotFoundException;
import com.tradeflow.tradeflow.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StockService {

    private final StockRepository stockRepository;

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

    public List<Stock> getAllStocks() {
        return stockRepository.findAll();
    }

    public Stock getStockById(Long id) {
        return stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id)); // ✅ changed
    }

    public Stock updateStock(Long id, CreateStockRequest request) {

        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id)); // ✅ changed

        stock.setSymbol(request.getSymbol());
        stock.setCompanyName(request.getCompanyName());
        stock.setPrice(request.getPrice());
        stock.setChangePercent(request.getChangePercent());
        stock.setMarketStatus(request.getMarketStatus());

        return stockRepository.save(stock);
    }

    public String deleteStock(Long id) {

        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", id)); // ✅ changed

        stockRepository.delete(stock);

        return "Stock deleted successfully";
    }
}