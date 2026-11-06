
package com.system.irtqaa

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper

class SystemWorldAudioEngine(context: Context) : AutoCloseable {

    private val appContext = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())

    private var toneGenerator: ToneGenerator? = createToneGenerator()
    private var enabled = true

    private fun createToneGenerator(): ToneGenerator? {
        return try {
            ToneGenerator(AudioManager.STREAM_MUSIC, 75)
        } catch (_: Exception) {
            null
        }
    }

    fun setEnabled(value: Boolean) {
        enabled = value
        if (!value) handler.removeCallbacksAndMessages(null)
    }

    fun playButtonClick() {
        play(ToneGenerator.TONE_PROP_BEEP, 65)
    }

    fun playPortalOpen() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 140
        )
    }

    fun playWorldSelection() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 180
        )
    }

    fun playTransition() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK
            ), 220
        )
    }

    fun playReward() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 170
        )
    }

    fun playWarning() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_NACK,
                ToneGenerator.TONE_PROP_NACK
            ), 230
        )
    }

    fun playLevelUp() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK
            ), 190
        )
    }

    fun playQuestStarted() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK
            ), 160
        )
    }

    fun playQuestCompleted() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK
            ), 160
        )
    }

    fun playQuestFailed() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_NACK,
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_NACK
            ), 210
        )
    }

    fun playCombatStarted() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_BEEP2
            ), 120
        )
    }

    fun playCombatVictory() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 170
        )
    }

    fun playCombatDefeat() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_NACK,
                ToneGenerator.TONE_PROP_NACK,
                ToneGenerator.TONE_PROP_BEEP
            ), 250
        )
    }

    fun playDiscovery() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 200
        )
    }

    fun playHealing() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK
            ), 240
        )
    }

    fun playGreedIslandOpen() {
        sequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ), 230
        )
    }

    private fun play(tone: Int, duration: Int) {
        if (!enabled) return

        try {
            if (toneGenerator == null) {
                toneGenerator = createToneGenerator()
            }

            toneGenerator?.startTone(tone, duration)
        } catch (_: Exception) {
            try {
                toneGenerator?.release()
            } catch (_: Exception) {
            }
            toneGenerator = createToneGenerator()
        }
    }

    private fun sequence(tones: List<Int>, duration: Int) {
        if (!enabled) return

        tones.forEachIndexed { index, tone ->
            val delay = index.toLong() * (duration + 55L)

            handler.postDelayed({
                if (enabled) play(tone, duration)
            }, delay)
        }
    }

    override fun close() {
        handler.removeCallbacksAndMessages(null)

        try {
            toneGenerator?.release()
        } catch (_: Exception) {
        }

        toneGenerator = null
    }
}
