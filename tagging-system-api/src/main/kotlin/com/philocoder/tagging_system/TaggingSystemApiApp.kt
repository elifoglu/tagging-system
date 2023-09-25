package com.philocoder.tagging_system

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.ConfigurableApplicationContext


@SpringBootApplication
open class TaggingSystemApiApp

fun main(args: Array<String>) {
    print("hi! tagging-system-api is started")

    val context: ConfigurableApplicationContext =
        runApplication<TaggingSystemApiApp>(*args)
}