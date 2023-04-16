package com.example.youtube_test

import android.content.Intent
import android.media.MediaScannerConnection
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle;
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.io.File
import android.net.Uri
import android.provider.DocumentsContract

class MainActivity: FlutterActivity() {
    companion object {
        const val channel="com.flutter.epic/mp3"
    }
    fun scanning(path: String){
        val file = File(path)
        MediaScannerConnection.scanFile(context, arrayOf(file.toString()), null, null)
    }
    fun openFolder(folderPath: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        val uri = Uri.parse("$folderPath")
        intent.setDataAndType(uri, "*/*")
        startActivity(intent)
    }

    fun update(filePath: String){
        val file = File(filePath)
        MediaScannerConnection.scanFile(context, arrayOf(file.toString()),
            null, null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,channel).setMethodCallHandler{
            call,result->
            if(call.method=="open"){
                print("niggaaaaaaaaaaaa")
                call.argument<String>("path")?.let { openFolder(it)
                print(it)}
                result.success("hi from java nigga")
            }else if(call.method=="update"){
                call.argument<String>("update")?.let {update(it) }

            }
        }
    }

}
