package com.tradeflow.tradeflow.repository;

import com.tradeflow.tradeflow.entity.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WalletRepository extends JpaRepository<Wallet, Long> {
}
