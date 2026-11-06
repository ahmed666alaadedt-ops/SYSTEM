
package com.system.irtqaa

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

object SystemWorldThemeRuntime {
    var currentWorld by mutableStateOf<SystemWorldKind?>(null)
}
