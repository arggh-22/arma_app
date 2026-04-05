package com.arma.vpn.core

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean
import libv2ray.CoreCallbackHandler
import libv2ray.CoreController
import libv2ray.Libv2ray

/**
 * Singleton manager for Xray-core Go runtime initialization and controller creation.
 *
 * Handles:
 * - Go runtime JNI context setup (go.Seq.setContext)
 * - Geo asset copying from APK assets to internal storage
 * - Xray-core environment initialization (Libv2ray.initCoreEnv)
 * - CoreController factory method
 *
 * All code runs in the :vpn_process (separate from Flutter main process).
 */
object XrayCoreManager {

    private val initialized = AtomicBoolean(false)
    private const val TAG = "XrayCoreManager"

    /**
     * Initialize the Xray-core Go runtime. Safe to call multiple times —
     * only the first call performs initialization.
     *
     * Must be called before [createController] or any Libv2ray function.
     *
     * @param context Android context (applicationContext will be used)
     * @throws RuntimeException if initialization fails
     */
    fun initialize(context: Context) {
        if (initialized.compareAndSet(false, true)) {
            try {
                Log.w(TAG, "Initializing Xray-core Go runtime...")
                go.Seq.setContext(context.applicationContext)
                Log.w(TAG, "Go runtime context set")

                val assetPath = copyAssetsToInternal(context)
                Log.w(TAG, "Geo assets copied to: $assetPath")

                // List files in asset directory
                val assetDir = File(assetPath)
                assetDir.listFiles()?.forEach { f ->
                    Log.w(TAG, "Asset: ${f.name} (${f.length()} bytes)")
                }

                Libv2ray.initCoreEnv(assetPath, "")
                Log.w(TAG, "initCoreEnv completed, version=${Libv2ray.checkVersionX()}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Xray core", e)
                initialized.set(false)
                throw RuntimeException("Failed to initialize Xray core", e)
            }
        }
    }

    /**
     * Create a new CoreController with the given callback handler.
     *
     * @param callback Handler for core status events
     * @return A new [CoreController] instance
     */
    fun createController(callback: CoreCallbackHandler): CoreController {
        return Libv2ray.newCoreController(callback)
    }

    /**
     * Get the Xray-core version string.
     */
    fun getVersion(): String = Libv2ray.checkVersionX()

    /**
     * Copy geoip.dat and geosite.dat from APK assets to internal storage.
     * Only copies if the target file doesn't already exist (first launch).
     *
     * @return Absolute path to the directory containing geo assets
     */
    private fun copyAssetsToInternal(context: Context): String {
        val targetDir = File(context.filesDir, "xray-assets")
        targetDir.mkdirs()
        for (file in listOf("geoip.dat", "geosite.dat")) {
            val target = File(targetDir, file)
            if (!target.exists()) {
                context.assets.open(file).use { input ->
                    FileOutputStream(target).use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }
        return targetDir.absolutePath
    }
}
