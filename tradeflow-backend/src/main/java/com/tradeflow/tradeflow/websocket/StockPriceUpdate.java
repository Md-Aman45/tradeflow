package com.tradeflow.tradeflow.websocket;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class StockPriceUpdate {

    private Long stockId;
    private String symbol;
    private String companyName;
    private BigDecimal price;
    private Double changePercent;
    private String marketStatus;
    private LocalDateTime updatedAt;
}