package com.system.irtqaa

import android.speech.tts.TextToSpeech

/**
 * Ensures only one SYSTEM/Miyar TextToSpeech engine speaks at a time.
 * A screen leaving composition stops and releases only its own engine.
 */
object SystemMiyarSpeechCoordinator {
    private var activeEngine: TextToSpeech? = null

    @Synchronized
    fun speak(engine: TextToSpeech?, text: String, utteranceId: String) {
        if (engine == null || text.isBlank()) return

        val previous = activeEngine
        if (previous != null && previous !== engine) {
            runCatching { previous.stop() }
        }

        runCatching {
            engine.stop()
            activeEngine = engine
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
        }
    }

    @Synchronized
    fun stop(engine: TextToSpeech?) {
        if (engine == null) return
        runCatching { engine.stop() }
        if (activeEngine === engine) activeEngine = null
    }

    @Synchronized
    fun release(engine: TextToSpeech?) {
        if (engine == null) return
        runCatching { engine.stop() }
        runCatching { engine.shutdown() }
        if (activeEngine === engine) activeEngine = null
    }
}
