package com.system.irtqaa

import android.os.Bundle
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotFragment
import org.godotengine.godot.plugin.GodotPlugin

/**
 * Loads the canonical game pack and registers the authenticated Android
 * marketplace transport with this one Godot engine instance.
 */
class SystemGodotFragment : GodotFragment() {
    override fun getCommandLine(): MutableList<String> {
        val requestedWorld = arguments?.getString(ARG_WORLD_ID)
            ?.takeIf {
                it == SystemGodotRuntimeContract.WorldId.MODERN.wireValue ||
                    it == SystemGodotRuntimeContract.WorldId.SELECTION.wireValue ||
                    it == SystemGodotRuntimeContract.WorldId.NPC_SHOWCASE.wireValue
            } ?: SystemGodotRuntimeContract.WorldId.MODERN.wireValue
        return mutableListOf(
            "--main-pack",
            "res://main.pck",
            "--",
            "--system-world=$requestedWorld"
        )
    }

    override fun getHostPlugins(godot: Godot): Set<GodotPlugin> {
        return setOf(SystemAndroidHostPlugin(godot))
    }

    companion object {
        private const val ARG_WORLD_ID = "system_godot_world_id"

        fun newInstance(worldId: String): SystemGodotFragment {
            return SystemGodotFragment().apply {
                arguments = Bundle().apply {
                    putString(
                        ARG_WORLD_ID,
                        if (worldId == SystemGodotRuntimeContract.WorldId.MODERN.wireValue ||
                            worldId == SystemGodotRuntimeContract.WorldId.SELECTION.wireValue ||
                            worldId == SystemGodotRuntimeContract.WorldId.NPC_SHOWCASE.wireValue
                        ) {
                            worldId
                        } else {
                            SystemGodotRuntimeContract.WorldId.MODERN.wireValue
                        }
                    )
                }
            }
        }
    }
}
