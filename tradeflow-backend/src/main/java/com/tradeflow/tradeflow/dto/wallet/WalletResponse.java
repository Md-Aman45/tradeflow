package com.tradeflow.tradeflow.dto.wallet;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class WalletResponse {

    private Long walletId;
    private String userEmail;
    private BigDecimal balance;
}