package com.tradeflow.tradeflow.service;


import com.tradeflow.tradeflow.dto.stock.CreateStockRequest;
import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

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
}
