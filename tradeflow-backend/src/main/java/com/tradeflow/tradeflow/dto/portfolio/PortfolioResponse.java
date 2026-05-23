package com.tradeflow.tradeflow.dto.portfolio;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class PortfolioResponse {

    private Long portfolioId;
    private String stockSymbol;
    private String companyName;
    private Integer quantity;
    private BigDecimal averageBuyPrice;
    private BigDecimal currentPrice;
    private BigDecimal totalValue;      // quantity × currentPrice
    private BigDecimal profitOrLoss;    // totalValue - (quantity × averageBuyPrice)
}