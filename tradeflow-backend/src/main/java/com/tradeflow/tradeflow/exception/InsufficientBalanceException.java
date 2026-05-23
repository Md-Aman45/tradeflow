package com.tradeflow.tradeflow.exception;

public class InsufficientBalanceException extends RuntimeException {
    
    public InsufficientBalanceException() {
        super("Insufficient wallet balance to complete this transaction.");
    }
 
    public InsufficientBalanceException(String message) {
        super(message);
    }
}
