package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore

@Composable
fun SystemAccountGate(
    content: @Composable (SystemFirebaseAccount) -> Unit
) {
    val repository = remember {
        FirebaseSystemAccountRepository()
    }

    val auth = remember {
        FirebaseAuth.getInstance()
    }

    val firestore = remember {
        FirebaseFirestore.getInstance()
    }

    var account by remember {
        mutableStateOf<SystemFirebaseAccount?>(null)
    }

    var checkingSession by remember {
        mutableStateOf(true)
    }

    var isRegisterMode by remember {
        mutableStateOf(false)
    }

    var email by remember {
        mutableStateOf("")
    }

    var password by remember {
        mutableStateOf("")
    }

    var displayName by remember {
        mutableStateOf("")
    }

    var loading by remember {
        mutableStateOf(false)
    }

    var errorMessage by remember {
        mutableStateOf<String?>(null)
    }

    var successMessage by remember {
        mutableStateOf<String?>(null)
    }

    fun restoreAccount() {
        val user = auth.currentUser

        if (user == null) {
            account = null
            checkingSession = false
            return
        }

        firestore.collection("players")
            .document(user.uid)
            .get()
            .addOnSuccessListener { document ->

                if (document.exists()) {
                    account = SystemFirebaseAccount(
                        userId = user.uid,
                        displayName =
                            document.getString("displayName")
                                ?: user.email?.substringBefore("@")
                                ?: "لاعب",
                        email =
                            document.getString("email")
                                ?: user.email.orEmpty(),
                        avatarUrl =
                            document.getString("avatarUrl").orEmpty()
                    )

                    errorMessage = null
                } else {
                    errorMessage =
                        "حسابك موجود، لكن ملف اللاعب غير موجود. سجّل الخروج وحاول تسجيل الدخول مجدداً."
                }

                checkingSession = false
            }
            .addOnFailureListener { error ->
                errorMessage =
                    error.localizedMessage
                        ?: "تعذر تحميل ملف اللاعب."

                checkingSession = false
            }
    }

    LaunchedEffect(Unit) {
        restoreAccount()
    }

    if (account != null) {
        SystemProgressSyncGate(account = account!!) {
            content(account!!)
        }
        return
    }

    val background = Brush.verticalGradient(
        colors = listOf(
            Color(0xFF050914),
            Color(0xFF101D32),
            Color(0xFF050914)
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(background)
            .padding(22.dp),
        contentAlignment = Alignment.Center
    ) {

        if (checkingSession) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator(
                    color = Color(0xFF45D6E8)
                )

                Spacer(Modifier.height(16.dp))

                Text(
                    "جاري التحقق من حساب SYSTEM...",
                    color = Color.White
                )
            }

            return@Box
        }

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color(0xFF131D30)
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {

                Text(
                    "SYSTEM",
                    color = Color(0xFFFFC857),
                    fontSize = 34.sp,
                    fontWeight = FontWeight.Black
                )

                Spacer(Modifier.height(6.dp))

                Text(
                    "الإنسان نحو الارتقاء",
                    color = Color.LightGray,
                    fontSize = 14.sp
                )

                Spacer(Modifier.height(25.dp))

                Text(
                    if (isRegisterMode)
                        "إنشاء حساب لاعب"
                    else
                        "تسجيل الدخول",
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(Modifier.height(20.dp))

                if (isRegisterMode) {
                    OutlinedTextField(
                        value = displayName,
                        onValueChange = {
                            displayName = it
                        },
                        modifier = Modifier.fillMaxWidth(),
                        label = {
                            Text("اسم اللاعب")
                        },
                        singleLine = true,
                        enabled = !loading
                    )

                    Spacer(Modifier.height(12.dp))
                }

                OutlinedTextField(
                    value = email,
                    onValueChange = {
                        email = it
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = {
                        Text("البريد الإلكتروني")
                    },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Email
                    ),
                    enabled = !loading
                )

                Spacer(Modifier.height(12.dp))

                OutlinedTextField(
                    value = password,
                    onValueChange = {
                        password = it
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = {
                        Text("كلمة المرور")
                    },
                    singleLine = true,
                    visualTransformation =
                        PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password
                    ),
                    enabled = !loading
                )

                if (errorMessage != null) {
                    Spacer(Modifier.height(14.dp))

                    Text(
                        errorMessage!!,
                        color = Color(0xFFFF7777),
                        fontSize = 13.sp
                    )
                }

                if (successMessage != null) {
                    Spacer(Modifier.height(14.dp))

                    Text(
                        successMessage!!,
                        color = Color(0xFF65E6A5),
                        fontSize = 13.sp
                    )
                }

                Spacer(Modifier.height(22.dp))

                Button(
                    onClick = {
                        if (loading) return@Button

                        loading = true
                        errorMessage = null
                        successMessage = null

                        val callback:
                            (Result<SystemFirebaseAccount>) -> Unit =
                            { result ->

                                loading = false

                                result.onSuccess {
                                    account = it
                                    errorMessage = null
                                }

                                result.onFailure { error ->
                                    errorMessage =
                                        error.localizedMessage
                                            ?: "تعذر إكمال العملية."
                                }
                            }

                        if (isRegisterMode) {
                            repository.register(
                                email = email,
                                password = password,
                                displayName = displayName,
                                callback = callback
                            )
                        } else {
                            repository.signIn(
                                email = email,
                                password = password,
                                callback = callback
                            )
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    enabled = !loading,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFFC857),
                        contentColor = Color.Black
                    ),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    if (loading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(22.dp),
                            color = Color.Black,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(
                            if (isRegisterMode)
                                "إنشاء الحساب"
                            else
                                "دخول إلى SYSTEM",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(Modifier.height(14.dp))

                TextButton(
                    onClick = {
                        isRegisterMode = !isRegisterMode
                        errorMessage = null
                        successMessage = null
                    },
                    enabled = !loading
                ) {
                    Text(
                        if (isRegisterMode)
                            "لديك حساب؟ سجّل الدخول"
                        else
                            "ليس لديك حساب؟ أنشئ حساباً"
                    )
                }

                if (auth.currentUser != null &&
                    account == null
                ) {
                    TextButton(
                        onClick = {
                            repository.signOut()
                            account = null
                            errorMessage = null
                            successMessage = null
                        }
                    ) {
                        Text(
                            "تسجيل الخروج من الحساب الحالي",
                            color = Color(0xFFFF9999)
                        )
                    }
                }
            }
        }
    }
}
