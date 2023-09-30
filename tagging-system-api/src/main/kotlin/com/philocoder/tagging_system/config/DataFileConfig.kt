package com.philocoder.tagging_system.config

import com.philocoder.tagging_system.model.UserConfig
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class DataFileConfig {

    @Bean
    open fun dataFilePath(): UserConfig =
        //you should use your own json data file here -->
        UserConfig("/home/mert/Desktop/stack/ts_data/data.json")
}