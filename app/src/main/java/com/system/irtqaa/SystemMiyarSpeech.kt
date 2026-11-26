package com.system.irtqaa

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

/**
 * Owns the Android Arabic speech engine used by Miyar in the embedded Godot stage.
 * The activity shuts it down when the 3D host is destroyed.
 */
object SystemMiyarSpeech {
    private var engine: TextToSpeech? = null
    private var initialized = false
    private var pendingText: String? = null

    @Synchronized
    fun speak(context: Context, text: String) {
        val message = text.trim()
        if (message.isEmpty()) return
        pendingText = message

        if (engine == null) {
            engine = TextToSpeech(context.applicationContext) { status ->
                synchronized(this) {
                    val active = engine ?: return@synchronized
                    if (status != TextToSpeech.SUCCESS) return@synchronized
                    val iraqiArabic = active.setLanguage(Locale("ar", "IQ"))
                    if (iraqiArabic == TextToSpeech.LANG_MISSING_DATA ||
                        iraqiArabic == TextToSpeech.LANG_NOT_SUPPORTED
                    ) {
                        active.setLanguage(Locale("ar"))
                    }
                    initialized = true
                    pendingText?.let(::speakNow)
                    pendingText = null
                }
            }
        } else if (initialized) {
            speakNow(message)
            pendingText = null
        }
    }

    @Synchronized
    fun stop() {
        engine?.stop()
        pendingText = null
    }

    @Synchronized
    fun shutdown() {
        engine?.stop()
        engine?.shutdown()
        engine = null
        initialized = false
        pendingText = null
    }

    private fun speakNow(text: String) {
        engine?.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "miyar_${System.currentTimeMillis()}"
        )
    }
}
