/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */
package com.innovray.manodhyan.android.receivers.alarm

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.innovray.manodhyan.android.AppConstants
import com.innovray.manodhyan.R
import com.innovray.manodhyan.android.enums.DndWakeLock
import com.innovray.manodhyan.android.generics.SafeServiceConnection
import com.innovray.manodhyan.android.helpers.AlarmTasksSchedulingHelper.scheduleBedtimeRoutineTasks
import com.innovray.manodhyan.android.helpers.device.NotificationHelper
import com.innovray.manodhyan.android.helpers.storage.SharedPrefsHelper
import com.innovray.manodhyan.android.models.BedtimeSchedule
import com.innovray.manodhyan.android.services.tracking.ManoDhyanTrackerService
import com.innovray.manodhyan.android.utils.AppUtils
import com.innovray.manodhyan.android.utils.DateTimeUtils
import com.innovray.manodhyan.android.utils.ThreadUtils

class BedtimeRoutineReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ManoDhyan.BedtimeRoutineReceiver"
        const val ACTION_ALERT_BEDTIME: String = "com.manodhyan.android.action.alertBedtime"
        const val ACTION_START_BEDTIME: String = "com.manodhyan.android.action.startBedtime"
        const val ACTION_STOP_BEDTIME: String = "com.manodhyan.android.action.stopBedtime"
        const val EXTRA_BEDTIME_SETTINGS_JSON = "com.manodhyan.android.extra.bedtimeSettingsJson"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_ALERT_BEDTIME, ACTION_START_BEDTIME, ACTION_STOP_BEDTIME -> {
                /// Schedule worker
                WorkManager.getInstance(context).enqueueUniqueWork(
                    TAG,
                    ExistingWorkPolicy.KEEP,
                    OneTimeWorkRequest.Builder(BedtimeRoutineWorker::class.java)
                        .setInputData(
                            Data.Builder()
                                .putString("action", intent.action)
                                .putString(
                                    EXTRA_BEDTIME_SETTINGS_JSON,
                                    intent.extras?.getString(EXTRA_BEDTIME_SETTINGS_JSON) ?: ""
                                )
                                .build()
                        )
                        .build()
                )
            }
        }
    }


    class BedtimeRoutineWorker(
        private val context: Context,
        params: WorkerParameters,
    ) : Worker(context, params) {
        private val jsonBedtimeSettings = inputData.getString(EXTRA_BEDTIME_SETTINGS_JSON) ?: ""
        private val bedtimeSchedule = BedtimeSchedule.fromJson(jsonBedtimeSettings)
        private val canStartRoutineToday: Boolean =
            bedtimeSchedule.scheduleDays[DateTimeUtils.zeroIndexedDayOfWeek()]

        private val trackerServiceConn = SafeServiceConnection(
            context = context,
            serviceClass = ManoDhyanTrackerService::class.java
        )


        override fun doWork(): Result {
            try {
                val action = inputData.getString("action")

                when (action) {
                    ACTION_ALERT_BEDTIME -> pushAlertNotification(context.getString(R.string.bedtime_upcoming_notification_info))
                    ACTION_START_BEDTIME -> startBedtimeRoutine()
                    ACTION_STOP_BEDTIME -> {
                        stopBedtimeRoutine()

                        // Reschedule bedtime tasks for next day
                        ThreadUtils.runOnMainThread(1000L) {
                            scheduleBedtimeRoutineTasks(
                                context,
                                jsonBedtimeSettings
                            )
                        }
                    }
                }
                return Result.success()
            } catch (e: Exception) {
                Log.e(TAG, "doWork: Error during work execution", e)
                SharedPrefsHelper.insertCrashLogToPrefs(context, e)
                return Result.failure()
            } finally {
                // Unbind service
                trackerServiceConn.unBindService()
            }
        }

        private fun startBedtimeRoutine() {
            if (!canStartRoutineToday) return
            trackerServiceConn.setOnConnectedCallback { service: ManoDhyanTrackerService ->
                with(service) {
                    getRestrictionManager.updateBedtimeApps(bedtimeSchedule.distractingApps)
                    getLaunchTrackingManager.detectActiveAppForBedtime()
                }
            }
            trackerServiceConn.startAndBind()

            // Start DND if needed
            if (bedtimeSchedule.shouldStartDnd) NotificationHelper.toggleDnd(
                context,
                DndWakeLock.BEDTIME_MODE,
                true
            )
            pushAlertNotification(context.getString(R.string.bedtime_started_notification_info))
        }

        private fun stopBedtimeRoutine() {
            trackerServiceConn.setOnConnectedCallback { service: ManoDhyanTrackerService ->
                service.getRestrictionManager.updateBedtimeApps(
                    null
                )
            }
            trackerServiceConn.bindService()

            // Stop DND if needed
            if (bedtimeSchedule.shouldStartDnd) NotificationHelper.toggleDnd(
                context,
                DndWakeLock.BEDTIME_MODE,
                false
            )
            pushAlertNotification(context.getString(R.string.bedtime_ended_notification_info))
        }


        private fun pushAlertNotification(alert: String) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(
                AppConstants.BEDTIME_ROUTINE_NOTIFICATION_ID,
                NotificationCompat.Builder(
                    context,
                    NotificationHelper.BEDTIME_CHANNEL_ID
                )
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setOngoing(false)
                    .setOnlyAlertOnce(true)
                    .setContentIntent(
                        AppUtils.getPendingIntentForManoDhyanUri(
                            context,
                            "com.manodhyan.android://open/home?tab=3",
                        )
                    )
                    .setContentTitle(context.getString(R.string.app_name))
                    .setContentText(alert)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(alert))
                    .build()
            )
        }
    }

}
