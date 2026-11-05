package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalContext

@Composable
fun SystemProgressSyncGate(
    account: SystemFirebaseAccount,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current.applicationContext

    var ready by remember(account.userId) {
        mutableStateOf(false)
    }

    var errorMessage by remember(account.userId) {
        mutableStateOf<String?>(null)
    }

    var retryKey by remember(account.userId) {
        mutableIntStateOf(0)
    }

    LaunchedEffect(account.userId, retryKey) {
        ready = false
        errorMessage = null

        FirebaseSystemProgressSync(context).synchronize(
            account.userId
        ) { progressSuccess, progressError ->

            if (!progressSuccess) {
                errorMessage = progressError?.localizedMessage
                    ?: "تعذرت مزامنة تقدمك."
                return@synchronize
            }

            FirebaseSystemTaskSync(context).synchronize(
                account.userId
            ) { taskSuccess, taskError ->

                if (taskSuccess) {
                    ready = true
                    errorMessage = null
                } else {
                    errorMessage = taskError?.localizedMessage
                        ?: "تعذرت مزامنة مهامك."
                }
            }
        }
    }

    if (ready) {
        content()
        return
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF050914))
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "SYSTEM",
                color = Color(0xFFFFC857),
                fontSize = 32.sp
            )

            Spacer(Modifier.height(20.dp))

            if (errorMessage == null) {
                CircularProgressIndicator(
                    color = Color(0xFF45D6E8)
                )

                Spacer(Modifier.height(16.dp))

                Text(
                    "جاري مزامنة تقدمك ومهامك...",
                    color = Color.White
                )
            } else {
                Text(
                    "تعذرت المزامنة",
                    color = Color(0xFFFF7777),
                    fontSize = 19.sp
                )

                Spacer(Modifier.height(10.dp))

                Text(
                    errorMessage!!,
                    color = Color.LightGray
                )

                Spacer(Modifier.height(18.dp))

                Button(
                    onClick = {
                        retryKey++
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFFC857),
                        contentColor = Color.Black
                    )
                ) {
                    Text("إعادة المحاولة")
                }
            }
        }
    }
}
