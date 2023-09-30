package com.philocoder.tagging_system

import com.google.gson.Gson
import com.philocoder.tagging_system.model.UserConfig
import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.service.DataService
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.context.ConfigurableApplicationContext
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.util.stream.Collectors


@SpringBootApplication
open class TaggingSystemApiApp

@ExperimentalStdlibApi
fun main(args: Array<String>) {
    print("hi! tagging-system-api is started")

    val context: ConfigurableApplicationContext =
        runApplication<TaggingSystemApiApp>(*args)

    val userConfig: UserConfig = context.getBean(UserConfig::class.java)
    val tsDataFilePath = userConfig.dataFilePath
    val f = File(tsDataFilePath);
    val reader = BufferedReader(FileReader(f));
    val jsonData = reader.lines().collect(Collectors.joining())
    val req: AddAllDataRequest = Gson().fromJson(jsonData, AddAllDataRequest::class.java)
    val service: DataService = context.getBean(DataService::class.java)
    service.addAllData(req)
}