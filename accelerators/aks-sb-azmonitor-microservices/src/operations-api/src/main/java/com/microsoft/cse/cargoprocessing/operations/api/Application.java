package com.microsoft.cse.cargoprocessing.operations.api;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;

import com.microsoft.cse.cargoprocessing.operations.api.services.StateProcessor;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@EventListener
	@Async
	public void StartListening(ApplicationReadyEvent event) {
		ExecutorService executor = Executors.newSingleThreadExecutor();
		StateProcessor runnable = event.getApplicationContext().getBean(StateProcessor.class);
		executor.execute(runnable);
	}

}
