package com.system.irtqaa

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Runtime bridge between GDScript and the authenticated Android Firebase
 * marketplace. It accepts only the versioned, allowlisted protocol.
 */
class SystemAndroidHostPlugin(godot: Godot) : GodotPlugin(godot) {
    private val router = SystemGodotMessageRouter(
        authenticatedPlayerId = {
            FirebaseAuth.getInstance().currentUser?.uid
        },
        sendRawToGodot = { rawMessage ->
            emitSignal(MESSAGE_FROM_ANDROID.name, rawMessage)
            true
        }
    )

    private val marketplaceHandler = SystemMarketplaceGodotBridgeHandler(
        FirebaseArtifactMarketplaceRepository(),
        router
    )

    override fun getPluginName(): String = PLUGIN_NAME

    override fun getPluginSignals(): Set<SignalInfo> = setOf(MESSAGE_FROM_ANDROID)

    @UsedByGodot
    fun speak_arabic(text: String) {
        val activity = godot.getActivity() ?: return
        SystemMiyarSpeech.speak(activity, text)
    }

    @UsedByGodot
    fun stop_arabic_speech() {
        SystemMiyarSpeech.stop()
    }

    @UsedByGodot
    fun send_to_android(rawMessage: String) {
        val envelope = SystemGodotMessageContract.decode(rawMessage)
        if (!router.receiveFromGodot(rawMessage, marketplaceHandler)) {
            Log.w(TAG, "Rejected an invalid or disallowed Godot bridge message.")
            return
        }
        if (envelope?.type == SystemGodotMessageContract.Type.BRIDGE_READY) {
            router.sendPlayerContext(FirebaseAuth.getInstance().currentUser?.displayName)
        }
    }

    companion object {
        private const val TAG = "SYSTEMAndroidHost"
        private const val PLUGIN_NAME = "SYSTEMAndroidHost"
        private val MESSAGE_FROM_ANDROID = SignalInfo(
            "message_from_android",
            String::class.java
        )
    }
}
