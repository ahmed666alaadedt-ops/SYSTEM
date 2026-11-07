package com.system.irtqaa

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember

/**
 * استرجاع حساب Firebase الحالي.
 * إذا لم يوجد حساب مسجل، يستمر التطبيق بوضع الضيف
 * مع الحفاظ على معرّف الضيف القديم.
 */
@Composable
fun SystemAccountGate(
    content: @Composable (SystemFirebaseAccount) -> Unit
) {
    val repository = remember {
        FirebaseSystemAccountRepository()
    }

    val firebaseUser = remember {
        repository.currentUser()
    }

    val account = remember(firebaseUser) {
        if (firebaseUser != null) {
            SystemFirebaseAccount(
                userId = firebaseUser.uid,
                displayName = firebaseUser.displayName
                    ?: firebaseUser.email?.substringBefore("@")
                    ?: "لاعب",
                email = firebaseUser.email.orEmpty(),
                avatarUrl = firebaseUser.photoUrl?.toString().orEmpty()
            )
        } else {
            SystemFirebaseAccount(
                userId = "system_guest_local",
                displayName = "لاعب",
                email = "",
                avatarUrl = ""
            )
        }
    }

    content(account)
}
