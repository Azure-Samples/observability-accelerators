package com.microsoft.cse.cargoprocessing.operations.api.repositories;

import com.microsoft.cse.cargoprocessing.operations.api.models.Operation;
import com.azure.spring.data.cosmos.repository.CosmosRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OperationRepo extends CosmosRepository<Operation, String> {
    
}
