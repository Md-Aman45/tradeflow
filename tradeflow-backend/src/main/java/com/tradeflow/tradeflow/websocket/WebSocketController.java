package com.tradeflow.tradeflow.websocket;

import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Controller
@RequiredArgsConstructor
public class WebSocketController {

    private final StockRepository stockRepository;

    @MessageMapping("/subscribe-stocks")
    @SendTo("/topic/stocks")
    public List<StockPriceUpdate> subscribeToStocks() {
        List<Stock> stocks = stockRepository.findAll();
        return stocks.stream().map(stock -> new StockPriceUpdate(
                stock.getId(),
                stock.getSymbol(),
                stock.getCompanyName(),
                stock.getPrice(),
                stock.getChangePercent(),
                stock.getMarketStatus(),
                LocalDateTime.now()
        )).collect(Collectors.toList());
    }
}