package com.microsoft.cse.cargoprocessing.api.chaos;

import java.util.Map;

import com.microsoft.cse.cargoprocessing.api.models.Cargo;

public interface ChaosMonkey {
    boolean CanWakeTheMonkey(Cargo cargo);

    void WakeTheMonkey(Map<String, Object> parameters);

    void RattleTheCage(Cargo cargo, Map<String, Object> parameters);

    void RattleTheCage(Cargo cargo);
}
