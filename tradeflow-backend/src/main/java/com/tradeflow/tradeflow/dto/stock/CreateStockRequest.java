package com.tradeflow.tradeflow.dto.stock;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateStockRequest {
    
    private String symbol;

    private String companyName;

    private BigDecimal price;

    private Double changePercent;

    private String marketStatus;
}
