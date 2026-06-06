package com.tradeflow.tradeflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class TradeflowApplication {

	public static void main(String[] args) {
		SpringApplication.run(TradeflowApplication.class, args);
	}

}
