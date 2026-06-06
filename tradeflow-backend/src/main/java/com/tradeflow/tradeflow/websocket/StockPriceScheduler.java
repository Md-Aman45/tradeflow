package com.tradeflow.tradeflow.websocket;

import com.tradeflow.tradeflow.entity.Stock;
import com.tradeflow.tradeflow.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Component
@RequiredArgsConstructor
@Slf4j
public class StockPriceScheduler {

    private final SimpMessagingTemplate messagingTemplate;
    private final StockRepository stockRepository;
    private final Random random = new Random();

    @Scheduled(fixedRate = 5000)
    public void broadcastStockPrices() {

        List<Stock> stocks = stockRepository.findAll();
        if (stocks.isEmpty()) return;

        for (Stock stock : stocks) {

            double changePercent = (random.nextDouble() * 4) - 2;
            changePercent = Math.round(changePercent * 100.0) / 100.0;

            BigDecimal priceChange = stock.getPrice()
                    .multiply(BigDecimal.valueOf(changePercent / 100));

            BigDecimal newPrice = stock.getPrice()
                    .add(priceChange)
                    .setScale(2, RoundingMode.HALF_UP);

            if (newPrice.compareTo(BigDecimal.ONE) < 0) {
                newPrice = BigDecimal.ONE;
            }

            stock.setPrice(newPrice);
            stock.setChangePercent(changePercent);
            stockRepository.save(stock);

            StockPriceUpdate update = new StockPriceUpdate(
                    stock.getId(),
                    stock.getSymbol(),
                    stock.getCompanyName(),
                    newPrice,
                    changePercent,
                    stock.getMarketStatus(),
                    LocalDateTime.now()
            );

            messagingTemplate.convertAndSend("/topic/stocks", update);
            messagingTemplate.convertAndSend("/topic/stock/" + stock.getId(), update);
        }

        log.info("Prices broadcasted at {}", LocalDateTime.now());
    }
}