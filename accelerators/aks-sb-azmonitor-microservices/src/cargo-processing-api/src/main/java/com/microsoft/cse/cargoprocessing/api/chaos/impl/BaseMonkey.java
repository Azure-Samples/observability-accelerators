package com.microsoft.cse.cargoprocessing.api.chaos.impl;

import java.util.Map;

import com.microsoft.cse.cargoprocessing.api.chaos.ChaosMonkey;
import com.microsoft.cse.cargoprocessing.api.models.Cargo;
import com.microsoft.cse.cargoprocessing.api.models.Port;

abstract public class BaseMonkey implements ChaosMonkey {
    private final String chaosTrigger;
    private final String SERVICE_TRIGGER = "cargo-processing-api";

    public BaseMonkey(String chaosTrigger) {
        this.chaosTrigger = chaosTrigger;
    }

    @Override
    public boolean CanWakeTheMonkey(Cargo cargo) {
        Port portInfo = cargo.getPort();
        return portInfo.getSource().equalsIgnoreCase(SERVICE_TRIGGER) &&
                portInfo.getDestination().equalsIgnoreCase(chaosTrigger);
    }

    @SuppressWarnings("unchecked")
    protected static <T> T getParm(Map<String, Object> map, String key, T defaultValue) {
        return (map.containsKey(key)) ? (T) map.get(key) : defaultValue;
    }

    abstract public void WakeTheMonkey(Map<String, Object> parameters);

    @Override
    public void RattleTheCage(Cargo cargo, Map<String, Object> parameters) {
        if (CanWakeTheMonkey(cargo))
            WakeTheMonkey(parameters);
    }

    @Override
    public void RattleTheCage(Cargo cargo) {
        RattleTheCage(cargo, null);
    }
}
