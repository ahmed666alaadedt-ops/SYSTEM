package com.system.irtqaa

import android.content.pm.ActivityInfo
import android.os.Bundle
import androidx.fragment.app.FragmentActivity

/**
 * Hosts the single embedded Godot runtime. The main Compose Activity remains
 * the account/startup surface and launches this Activity only for 3D gameplay.
 */
class SystemGodotActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE

        val request = SystemGodotRuntimeContract.readWorldRequest(intent)
        val worldId = request?.worldId ?: SystemGodotRuntimeContract.WorldId.MODERN
        if (worldId != SystemGodotRuntimeContract.WorldId.MODERN) {
            finish()
            return
        }

        setContentView(R.layout.activity_system_godot)
        if (savedInstanceState == null) {
            supportFragmentManager.beginTransaction()
                .replace(
                    R.id.system_godot_container,
                    SystemGodotFragment.newInstance(worldId.wireValue)
                )
                .commitNow()
        }
    }
}
