package com.philocoder.tagging_system.config

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.ObjectReader
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class JacksonConfig {

    @Bean
    open fun objectMapper(): ObjectMapper =
        ObjectMapper().registerKotlinModule()

    @Bean
    @Qualifier("contentObjectReader")
    open fun contentObjectReader(objectMapper: ObjectMapper): ObjectReader =
        objectMapper.readerFor(Content::class.java)

    @Bean
    @Qualifier("tagObjectReader")
    open fun tagObjectReader(objectMapper: ObjectMapper): ObjectReader =
        objectMapper.readerFor(Tag::class.java)

}