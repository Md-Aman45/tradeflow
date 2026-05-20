package com.tradeflow.tradeflow.repository;

import com.tradeflow.tradeflow.entity.Stock;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockRepository extends JpaRepository<Stock, Long> {
}
