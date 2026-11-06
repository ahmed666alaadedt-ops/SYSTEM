package com.system.irtqaa

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember

/**
 * دخول تجريبي بدون بريد إلكتروني.
 * الحساب الحقيقي وFirebase يبقيان محفوظين
 * حتى مرحلة تفعيل الحسابات النهائية.
 */
@Composable
fun SystemAccountGate(
    content: @Composable (SystemFirebaseAccount) -> Unit
) {
    val guestAccount = remember {
        SystemFirebaseAccount(
            userId = "system_guest_local",
            displayName = "لاعب",
            email = "",
            avatarUrl = ""
        )
    }

    content(guestAccount)
}
