package com.microsoft.cse.cargoprocessing.api.chaos.impl;

public class ChaosMonkeyException extends RuntimeException {
    public ChaosMonkeyException(String chaosType) {
        super(String.format("%s Chaos Monkey reeking havoc.", chaosType));
    }
}
