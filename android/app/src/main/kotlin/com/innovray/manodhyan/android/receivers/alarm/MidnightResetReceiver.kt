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

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.innovray.manodhyan.android.generics.SafeServiceConnection
import com.innovray.manodhyan.android.helpers.AlarmTasksSchedulingHelper.scheduleMidnightResetTask
import com.innovray.manodhyan.android.helpers.storage.SharedPrefsHelper
import com.innovray.manodhyan.android.services.accessibility.ManoDhyanAccessibilityService
import com.innovray.manodhyan.android.services.accessibility.ManoDhyanAccessibilityService.Companion.ACTION_MIDNIGHT_ACCESSIBILITY_RESET
import com.innovray.manodhyan.android.services.tracking.ManoDhyanTrackerService
import com.innovray.manodhyan.android.utils.Utils
import com.innovray.manodhyan.android.workers.FlutterBgExecutionWorker
import com.innovray.manodhyan.android.workers.FlutterBgExecutionWorker.Companion.FLUTTER_TASK_ID

class MidnightResetReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ManoDhyan.MidnightResetReceiver"
        const val ACTION_START_MIDNIGHT_RESET = "com.manodhyan.android.action.startMidnightReset"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_START_MIDNIGHT_RESET) {
            WorkManager.getInstance(context).let {

                /// Enqueue midnight worker for services
                it.enqueueUniqueWork(
                    "ManoDhyan.MidnightResetReceiver.Native",
                    ExistingWorkPolicy.KEEP,
                    OneTimeWorkRequest.Builder(MidnightResetWorker::class.java).build()
                )

                /// Enqueue flutter bg worker to backup apps usage
                it.enqueueUniqueWork(
                    "ManoDhyan.MidnightResetReceiver.FlutterBg",
                    ExistingWorkPolicy.KEEP,
                    OneTimeWorkRequest
                        .Builder(FlutterBgExecutionWorker::class.java)
                        .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                        .setInputData(
                            Data.Builder().putString(FLUTTER_TASK_ID, "onMidnightReset")
                                .build()
                        ).build()
                )
            }
        }
    }

    class MidnightResetWorker(
        private val context: Context,
        params: WorkerParameters,
    ) : Worker(context, params) {
        private val mTrackerServiceConn = SafeServiceConnection(
            context = context,
            serviceClass = ManoDhyanTrackerService::class.java,
        )


        override fun doWork(): Result {
            try {
                // Let tracking service know about midnight reset
                mTrackerServiceConn.setOnConnectedCallback { service: ManoDhyanTrackerService -> service.onMidnightReset() }
                mTrackerServiceConn.bindService()

                // Let accessibility service know about midnight reset
                if (Utils.isServiceRunning(context, ManoDhyanAccessibilityService::class.java)) {
                    val serviceIntent = Intent(
                        context.applicationContext,
                        ManoDhyanAccessibilityService::class.java
                    ).setAction(ACTION_MIDNIGHT_ACCESSIBILITY_RESET)
                    context.startService(serviceIntent)
                } else {
                    // Else at least reset short content screen time
                    SharedPrefsHelper.getSetShortsScreenTimeMs(context, 0L)
                }

                Log.d(TAG, "doWork: Midnight reset work completed successfully")
                return Result.success()
            } catch (e: Exception) {
                Log.e(TAG, "doWork: Error during work execution", e)
                SharedPrefsHelper.insertCrashLogToPrefs(context, e)
                return Result.failure()
            } finally {
                // Unbind service and schedule task for the next day
                mTrackerServiceConn.unBindService()
                scheduleMidnightResetTask(context, false)
            }
        }
    }
}
