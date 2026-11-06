
package com.system.irtqaa

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator

class SystemWorldAudioEngine(
    context: Context
) : AutoCloseable {

    private val appContext = context.applicationContext

    private var toneGenerator: ToneGenerator? =
        createToneGenerator()

    private var enabled = true

    private fun createToneGenerator(): ToneGenerator? {
        return try {
            ToneGenerator(
                AudioManager.STREAM_MUSIC,
                75
            )
        } catch (_: Exception) {
            null
        }
    }

    fun setEnabled(value: Boolean) {
        enabled = value
    }

    fun playButtonClick() {
        play(
            ToneGenerator.TONE_PROP_BEEP,
            65
        )
    }

    fun playPortalOpen() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ),
            140
        )
    }

    fun playWorldSelection() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ),
            180
        )
    }

    fun playTransition() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK
            ),
            220
        )
    }

    fun playReward() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2
            ),
            170
        )
    }

    fun playWarning() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_NACK,
                ToneGenerator.TONE_PROP_NACK
            ),
            230
        )
    }

    fun playLevelUp() {
        playSequence(
            listOf(
                ToneGenerator.TONE_PROP_BEEP,
                ToneGenerator.TONE_PROP_ACK,
                ToneGenerator.TONE_PROP_BEEP2,
                ToneGenerator.TONE_PROP_ACK
            ),
            190
        )
    }

    private fun play(
        tone: Int,
        duration: Int
    ) {
        if (!enabled) return

        try {
            toneGenerator?.startTone(
                tone,
                duration
            )
        } catch (_: Exception) {
            toneGenerator = createToneGenerator()
        }
    }

    private fun playSequence(
        tones: List<Int>,
        duration: Int
    ) {
        if (!enabled) return

        tones.forEachIndexed { index, tone ->
            val delay = index * (duration + 55L)

            android.os.Handler(
                android.os.Looper.getMainLooper()
            ).postDelayed({
                if (enabled) {
                    play(tone, duration)
                }
            }, delay)
        }
    }

    override fun close() {
        try {
            toneGenerator?.release()
        } catch (_: Exception) {
        }

        toneGenerator = null
    }
}
