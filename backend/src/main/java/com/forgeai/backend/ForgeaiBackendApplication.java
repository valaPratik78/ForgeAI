package com.forgeai.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@org.springframework.scheduling.annotation.EnableAsync
public class ForgeaiBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(ForgeaiBackendApplication.class, args);
	}

}
