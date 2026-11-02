package com.sjtechnovation.focusjoy.android.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.Display
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.sjtechnovation.focusjoy.MainActivity
import com.sjtechnovation.focusjoy.R
import kotlin.math.abs

/** A small touchable window, independent of the Flutter Activity's lifetime. */
class FocusShortcutService : Service() {
    private lateinit var windows: WindowManager
    private lateinit var overlayContext: Context
    private var button: View? = null
    private var layout: WindowManager.LayoutParams? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        val display = (getSystemService(DISPLAY_SERVICE) as DisplayManager).getDisplay(Display.DEFAULT_DISPLAY)
        overlayContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && display != null)
            createDisplayContext(display).createWindowContext(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, null)
            else this
        windows = overlayContext.getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_DISABLE) {
            preferences(this).edit().putBoolean("enabled", false).apply()
        }
        if (!isEnabled(this) || !Settings.canDrawOverlays(this)) {
            removeButton()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                CHANNEL_ID, "Floating Focus shortcut", NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Keeps your movable Focus shortcut available over other apps" })
        }
        val open = PendingIntent.getActivity(this, 1, openFocusIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val hide = PendingIntent.getService(this, 2,
            Intent(this, FocusShortcutService::class.java).setAction(ACTION_DISABLE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_focus_mode)
            .setContentTitle("Floating Focus is available")
            .setContentText("Drag the shortcut anywhere. Tap it to open Focus.")
            .setContentIntent(open)
            .setOngoing(true)
            .setSilent(true)
            .addAction(0, "Hide shortcut", hide)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (error: RuntimeException) {
            lastError = "Android could not keep the shortcut running. Reopen FocusJoy and retry."
            Log.e(TAG, "Cannot promote overlay service", error)
            stopSelf()
            return START_NOT_STICKY
        }
        lastError = null
        refreshVisibility()
        onStateChanged?.invoke()
        return START_STICKY
    }

    fun refreshVisibility() {
        if (!Settings.canDrawOverlays(this) || !isEnabled(this)) {
            removeButton()
            stopSelf()
        } else if (hostForeground && !inAppVisible) {
            removeButton()
        } else if (button == null) {
            addButton()
        } else {
            restorePosition()
        }
    }

    private fun dp(value: Int) = (value * overlayContext.resources.displayMetrics.density).toInt()

    @Suppress("DEPRECATION")
    private fun safeArea(): Rect {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = windows.currentWindowMetrics
            val insets = metrics.windowInsets.getInsetsIgnoringVisibility(
                WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            return Rect(insets.left, insets.top,
                metrics.bounds.width() - insets.right, metrics.bounds.height() - insets.bottom)
        }
        val metrics = android.util.DisplayMetrics()
        windows.defaultDisplay.getRealMetrics(metrics)
        val insets = button?.rootWindowInsets
        return Rect(insets?.systemWindowInsetLeft ?: 0, insets?.systemWindowInsetTop ?: dp(24),
            metrics.widthPixels - (insets?.systemWindowInsetRight ?: 0),
            metrics.heightPixels - (insets?.systemWindowInsetBottom ?: dp(24)))
    }

    private fun bounds(): Rect {
        val area = safeArea()
        val left = area.left + dp(8)
        val top = area.top + dp(8)
        return Rect(left, top, maxOf(left, area.right - dp(124) - dp(8)),
            maxOf(top, area.bottom - dp(52) - dp(8)))
    }

    private fun addButton() {
        val view = LinearLayout(overlayContext).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(12), 0, dp(12), 0)
            background = GradientDrawable().apply {
                setColor(Color.rgb(124, 77, 255))
                cornerRadius = dp(28).toFloat()
                setStroke(dp(1), Color.rgb(179, 157, 255))
            }
            elevation = dp(6).toFloat()
            contentDescription = "Open Focus. Drag to move the shortcut."
            isClickable = true
            isFocusable = true
        }
        view.addView(ImageView(overlayContext).apply {
            setImageResource(R.drawable.ic_focus_mode)
            setColorFilter(Color.WHITE)
        }, LinearLayout.LayoutParams(dp(24), dp(24)))
        view.addView(TextView(overlayContext).apply {
            text = "Focus"
            setTextColor(Color.WHITE)
            textSize = 15f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(8), 0, 0, 0)
        })
        @Suppress("DEPRECATION")
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
        val params = WindowManager.LayoutParams(dp(124), dp(52), type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.LEFT }
        button = view
        layout = params
        restorePosition(updateWindow = false)
        view.setOnClickListener {
            try { startActivity(openFocusIntent(this)) }
            catch (error: RuntimeException) { Log.e(TAG, "Unable to open Focus", error) }
        }
        val slop = ViewConfiguration.get(this).scaledTouchSlop
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false
        view.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX; downY = event.rawY
                    startX = params.x; startY = params.y; dragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (abs(dx) > slop || abs(dy) > slop) dragging = true
                    if (dragging) {
                        val safe = bounds()
                        params.x = (startX + dx.toInt()).coerceIn(safe.left, safe.right)
                        params.y = (startY + dy.toInt()).coerceIn(safe.top, safe.bottom)
                        updateWindow()
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) savePosition()
                    else if (event.actionMasked == MotionEvent.ACTION_UP) view.performClick()
                    true
                }
                else -> false
            }
        }
        try { windows.addView(view, params) }
        catch (error: RuntimeException) {
            button = null; layout = null
            lastError = "Android could not show the shortcut. Check Display over other apps, then retry."
            Log.e(TAG, "Cannot add Focus overlay", error)
            stopSelf()
        }
    }

    private fun savePosition() {
        val params = layout ?: return
        val safe = bounds()
        setPosition(this,
            if (safe.width() > 0) (params.x - safe.left).toFloat() / safe.width() else 0f,
            if (safe.height() > 0) (params.y - safe.top).toFloat() / safe.height() else 0f)
    }

    private fun restorePosition(updateWindow: Boolean = true) {
        val params = layout ?: return
        val safe = bounds()
        val prefs = preferences(this)
        params.x = safe.left + (prefs.getFloat("x", 1f).coerceIn(0f, 1f) * safe.width()).toInt()
        params.y = safe.top + (prefs.getFloat("y", 0.5f).coerceIn(0f, 1f) * safe.height()).toInt()
        if (updateWindow) updateWindow()
    }

    private fun updateWindow() {
        val view = button ?: return
        val params = layout ?: return
        try { windows.updateViewLayout(view, params) }
        catch (error: RuntimeException) { Log.e(TAG, "Cannot move Focus overlay", error); stopSelf() }
    }

    private fun removeButton() {
        button?.let { try { windows.removeViewImmediate(it) } catch (_: RuntimeException) { } }
        button = null; layout = null
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        restorePosition()
    }
    override fun onTaskRemoved(rootIntent: Intent?) {
        // Swiping away the Flutter task does not stop the user-enabled shortcut.
        hostForeground = false
        refreshVisibility()
        super.onTaskRemoved(rootIntent)
    }
    override fun onDestroy() {
        removeButton()
        if (instance === this) instance = null
        onStateChanged?.invoke()
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val METHOD_CHANNEL = "focusjoy/floating_focus"
        const val ACTION_OPEN_FOCUS = "com.sjtechnovation.focusjoy.OPEN_FOCUS"
        private const val ACTION_DISABLE = "com.sjtechnovation.focusjoy.HIDE_FOCUS_SHORTCUT"
        private const val CHANNEL_ID = "focusjoy_focus_shortcut"
        private const val NOTIFICATION_ID = 19001
        private const val TAG = "FocusJoy.FocusShortcut"
        private var instance: FocusShortcutService? = null
        private var hostForeground = false
        private var inAppVisible = false
        private var lastError: String? = null
        var onStateChanged: (() -> Unit)? = null

        private fun preferences(context: Context) = context.getSharedPreferences("FocusShortcut", Context.MODE_PRIVATE)
        fun isEnabled(context: Context) = preferences(context).getBoolean("enabled", true)
        fun state(context: Context): Map<String, Any?> = mapOf(
            "enabled" to isEnabled(context), "permission" to Settings.canDrawOverlays(context),
            "running" to (instance != null), "x" to preferences(context).getFloat("x", 1f).toDouble(),
            "y" to preferences(context).getFloat("y", 0.5f).toDouble(), "error" to lastError)

        fun start(context: Context) {
            if (!isEnabled(context) || !Settings.canDrawOverlays(context)) {
                context.stopService(Intent(context, FocusShortcutService::class.java))
                return
            }
            if (instance != null) { instance?.refreshVisibility(); return }
            try {
                val intent = Intent(context, FocusShortcutService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent)
                else context.startService(intent)
            } catch (error: RuntimeException) {
                lastError = "Android could not start the floating shortcut. Reopen FocusJoy and retry."
                Log.e(TAG, "Cannot start overlay service", error)
            }
        }
        fun setEnabled(context: Context, enabled: Boolean) {
            preferences(context).edit().putBoolean("enabled", enabled).apply()
            if (enabled) start(context)
            else context.stopService(Intent(context, FocusShortcutService::class.java))
        }
        fun setPosition(context: Context, x: Float, y: Float) {
            preferences(context).edit().putFloat("x", if (x.isFinite()) x.coerceIn(0f, 1f) else 1f)
                .putFloat("y", if (y.isFinite()) y.coerceIn(0f, 1f) else 0.5f).apply()
        }
        fun updatePosition(context: Context, x: Float, y: Float) {
            setPosition(context, x, y)
            instance?.restorePosition()
        }
        fun setHostForeground(context: Context, foreground: Boolean) {
            hostForeground = foreground
            if (foreground) start(context)
            instance?.refreshVisibility()
        }
        fun setInAppVisible(visible: Boolean) {
            inAppVisible = visible
            instance?.refreshVisibility()
        }
        private fun openFocusIntent(context: Context) = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN_FOCUS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }
}
