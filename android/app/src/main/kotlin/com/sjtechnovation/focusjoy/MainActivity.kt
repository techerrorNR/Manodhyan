/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */
package com.sjtechnovation.focusjoy

import android.content.Intent
import android.os.Bundle
import android.net.Uri
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.sjtechnovation.focusjoy.android.helpers.AlarmTasksSchedulingHelper.scheduleMidnightResetTask
import com.sjtechnovation.focusjoy.android.helpers.device.NotificationHelper
import com.sjtechnovation.focusjoy.android.helpers.storage.SharedPrefsHelper
import com.sjtechnovation.focusjoy.android.FgMethodCallHandler
import com.sjtechnovation.focusjoy.android.AppConstants
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sjtechnovation.focusjoy.android.services.FocusShortcutService

class MainActivity : FlutterFragmentActivity() {
    private lateinit var fgMethodCallHandler: FgMethodCallHandler
    private lateinit var vpnPermissionLauncher: ActivityResultLauncher<Intent>
    private var focusShortcutChannel: MethodChannel? = null
    private var openFocusRequested = false

    override fun onCreate(savedInstanceState: Bundle?) {
        openFocusRequested = intent.action == FocusShortcutService.ACTION_OPEN_FOCUS

        // Store uncaught exceptions
        Thread.setDefaultUncaughtExceptionHandler { _: Thread?, exception: Throwable ->
            SharedPrefsHelper.insertCrashLogToPrefs(
                this, exception
            )
        }

        // Register notification channels
        NotificationHelper.registerNotificationChannels(this)

        // Register VPN permission launcher
        vpnPermissionLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { }

        // initialize method channel and bind to services
        fgMethodCallHandler = FgMethodCallHandler(
            context = this,
            activity = this,
            vpnPermLauncher = vpnPermissionLauncher
        )

        // Schedule midnight 12 task if already not scheduled
        scheduleMidnightResetTask(this, true)
        super.onCreate(savedInstanceState)
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        focusShortcutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            FocusShortcutService.METHOD_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getState" -> result.success(shortcutState())
                    "setEnabled" -> {
                        FocusShortcutService.setEnabled(this, call.argument<Boolean>("enabled") == true)
                        result.success(shortcutState())
                    }
                    "setPosition" -> {
                        FocusShortcutService.updatePosition(this,
                            call.argument<Number>("x")?.toFloat() ?: 1f,
                            call.argument<Number>("y")?.toFloat() ?: 0.5f)
                        result.success(shortcutState())
                    }
                    "setInAppVisible" -> {
                        FocusShortcutService.setInAppVisible(call.arguments == true)
                        result.success(null)
                    }
                    "requestPermission" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                                .setData(Uri.parse("package:$packageName")))
                            result.success(null)
                        } catch (error: android.content.ActivityNotFoundException) {
                            result.error("overlay_settings_unavailable", "Open Display over other apps in Android Settings.", null)
                        }
                    }
                    "consumeFocusRequest" -> {
                        val requested = openFocusRequested
                        openFocusRequested = false
                        if (intent.action == FocusShortcutService.ACTION_OPEN_FOCUS) intent.action = Intent.ACTION_MAIN
                        result.success(requested)
                    }
                    else -> result.notImplemented()
                }
            }
            FocusShortcutService.onStateChanged = {
                channel.invokeMethod("stateChanged", shortcutState())
            }
        }
        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppConstants.FLUTTER_METHOD_CHANNEL_FG
        )
        methodChannel.setMethodCallHandler(fgMethodCallHandler)

        // Get the self start status
        val isSelfStart =
            intent.getBooleanExtra(AppConstants.INTENT_EXTRA_IS_SELF_RESTART, false)

        // Update self start status on flutter side
        methodChannel.invokeMethod("updateSelfStartStatus", isSelfStart)
        super.configureFlutterEngine(flutterEngine)
    }


    override fun onResume() {
        super.onResume()
        // Start while the Activity is visible, before Android's background-start restrictions apply.
        FocusShortcutService.setHostForeground(this, true)
        focusShortcutChannel?.invokeMethod("stateChanged", shortcutState())
        // The user may have just granted Alarms & reminders in system settings.
        scheduleMidnightResetTask(this, true)
    }

    override fun onPause() {
        FocusShortcutService.setHostForeground(this, false)
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == FocusShortcutService.ACTION_OPEN_FOCUS) {
            openFocusRequested = true
            focusShortcutChannel?.invokeMethod("stateChanged", shortcutState())
        }
    }

    private fun shortcutState(): Map<String, Any?> =
        FocusShortcutService.state(this) + mapOf("openFocusRequested" to openFocusRequested)

    override fun onDestroy() {
        FocusShortcutService.setHostForeground(this, false)
        FocusShortcutService.onStateChanged = null
        focusShortcutChannel?.setMethodCallHandler(null)
        fgMethodCallHandler.dispose()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "ManoDhyan.MainActivity"
    }
}
