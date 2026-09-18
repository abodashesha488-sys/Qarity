package com.example.qarity

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.qarity/update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("QURITY_UPDATE", "MethodCall: ${call.method}")
            when (call.method) {
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath == null) {
                        result.error("INVALID_ARGUMENT", "apkPath is required", null)
                        return@setMethodCallHandler
                    }
                    installApk(apkPath, result)
                }
                "canInstallPackages" -> {
                    result.success(canInstallPackages())
                }
                "openInstallPermissionSettings" -> {
                    openInstallPermissionSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(apkPath: String, result: MethodChannel.Result) {
        Log.d("QURITY_UPDATE", "installApk called: apkPath=$apkPath")
        val file = File(apkPath)
        if (!file.exists()) {
            Log.e("QURITY_UPDATE", "FILE_NOT_FOUND: $apkPath")
            result.error("FILE_NOT_FOUND", "APK file does not exist", null)
            return
        }
        if (!file.canRead()) {
            Log.e("QURITY_UPDATE", "FILE_NOT_READABLE: $apkPath")
            result.error("FILE_NOT_READABLE", "APK file is not readable", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !canInstallPackages()) {
            Log.e("QURITY_UPDATE", "PERMISSION_DENIED")
            result.error("PERMISSION_DENIED", "User has not granted install permission", null)
            return
        }
        try {
            Log.d("QURITY_UPDATE", "Starting install activity")
            val authority = "${applicationContext.packageName}.fileprovider"
            val contentUri = FileProvider.getUriForFile(this, authority, file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.d("QURITY_UPDATE", "startActivity succeeded")
            result.success(null)
        } catch (e: Exception) {
            Log.e("QURITY_UPDATE", "INSTALL_FAILED: ${e.message}", e)
            result.error("INSTALL_FAILED", e.message ?: "Unknown error", null)
        }
    }

    private fun canInstallPackages(): Boolean {
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
        Log.d("QURITY_UPDATE", "canInstallPackages: $result")
        return result
    }

    private fun openInstallPermissionSettings() {
        Log.d("QURITY_UPDATE", "openInstallPermissionSettings called")
        try {
            val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:${applicationContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.d("QURITY_UPDATE", "startActivity succeeded for settings")
        } catch (e: Exception) {
            Log.e("QURITY_UPDATE", "openInstallPermissionSettings failed: ${e.message}", e)
        }
    }
}
