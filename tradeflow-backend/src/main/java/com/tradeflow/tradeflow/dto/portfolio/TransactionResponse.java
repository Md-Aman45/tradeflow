package com.tradeflow.tradeflow.dto.portfolio;

import com.tradeflow.tradeflow.entity.Transaction.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class TransactionResponse {

    private Long transactionId;
    private TransactionType type;
    private String stockSymbol;
    private Integer quantity;
    private BigDecimal price;
    private BigDecimal totalAmount;
    private LocalDateTime createdAt;
}