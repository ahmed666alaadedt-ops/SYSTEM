
package com.system.irtqaa

import android.content.Context
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private object SystemCompanionGenderSettings {

    private const val PREFS = "system_companion_settings"
    private const val KEY_GENDER = "player_gender"

    fun load(context: Context): SystemPlayerGender? {
        val value = context.getSharedPreferences(
            PREFS,
            Context.MODE_PRIVATE
        ).getString(KEY_GENDER, null)

        return when (value) {
            "male" -> SystemPlayerGender.MALE
            "female" -> SystemPlayerGender.FEMALE
            else -> null
        }
    }

    fun save(
        context: Context,
        gender: SystemPlayerGender
    ): Boolean {
        return context.getSharedPreferences(
            PREFS,
            Context.MODE_PRIVATE
        ).edit()
            .putString(KEY_GENDER, gender.storageValue)
            .commit()
    }

    fun clear(context: Context): Boolean {
        return context.getSharedPreferences(
            PREFS,
            Context.MODE_PRIVATE
        ).edit()
            .remove(KEY_GENDER)
            .commit()
    }
}

@Composable
fun SystemMiyarWelcomeCard(
    onExplainClick: () -> Unit,
    onTalkClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    var playerGender by remember(context) {
        mutableStateOf(
            SystemCompanionGenderSettings.load(context)
        )
    }

    val world = SystemWorldThemeRuntime.currentWorld
        ?: SystemWorldKind.MODERN_REALISTIC

    val primary = when (world) {
        SystemWorldKind.MODERN_REALISTIC ->
            Color(0xFF35D9F2)

        SystemWorldKind.MYTHOLOGY_HISTORY ->
            Color(0xFFE6B65C)

        SystemWorldKind.FANTASY ->
            Color(0xFFB69BFF)

        SystemWorldKind.GREED_ISLAND ->
            Color(0xFF65E6A6)
    }

    val background = when (world) {
        SystemWorldKind.MODERN_REALISTIC -> listOf(
            Color(0xFF101827),
            Color(0xFF172B42),
            Color(0xFF211B36)
        )

        SystemWorldKind.MYTHOLOGY_HISTORY -> listOf(
            Color(0xFF28170F),
            Color(0xFF49301B),
            Color(0xFF21150F)
        )

        SystemWorldKind.FANTASY -> listOf(
            Color(0xFF100D25),
            Color(0xFF29234B),
            Color(0xFF17132F)
        )

        SystemWorldKind.GREED_ISLAND -> listOf(
            Color(0xFF062019),
            Color(0xFF123C35),
            Color(0xFF08251F)
        )
    }

    val appearance = playerGender?.let {
        SystemCompanionAppearanceEngine.create(it, world)
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6101828)
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 8.dp
        )
    ) {
        Box(
            modifier = Modifier
                .background(Brush.linearGradient(background))
                .padding(16.dp)
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {

                    Box(
                        modifier = Modifier
                            .size(112.dp, 150.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        if (appearance != null) {
                            SystemCompanionAnimatedAvatar(
                                appearance = appearance,
                                modifier = Modifier.fillMaxSize()
                            )
                        } else {
                            Image(
                                painter = painterResource(
                                    id = R.drawable.ic_system_foreground
                                ),
                                contentDescription = "شعار SYSTEM",
                                modifier = Modifier.size(66.dp)
                            )
                        }
                    }

                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(7.dp)
                    ) {
                        Text(
                            text = appearance?.name ?: "المرافق الذكي",
                            color = primary,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black
                        )

                        Text(
                            text = appearance?.worldTitle
                                ?: "اختيار هوية المرافق",
                            color = Color(0xFFD7E2F0),
                            fontSize = 13.sp
                        )

                        Text(
                            text = "● متصل بالنظام",
                            color = Color(0xFF4ADE80),
                            fontSize = 12.sp
                        )
                    }
                }

                if (playerGender == null) {

                    Text(
                        text = "حتى أختار لك المرافق المناسب، حدد ملف اللاعب:",
                        color = Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {

                        Button(
                            onClick = {
                                if (
                                    SystemCompanionGenderSettings.save(
                                        context,
                                        SystemPlayerGender.MALE
                                    )
                                ) {
                                    playerGender =
                                        SystemPlayerGender.MALE
                                }
                            },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = primary,
                                contentColor = Color.Black
                            )
                        ) {
                            Text("لاعب")
                        }

                        Button(
                            onClick = {
                                if (
                                    SystemCompanionGenderSettings.save(
                                        context,
                                        SystemPlayerGender.FEMALE
                                    )
                                ) {
                                    playerGender =
                                        SystemPlayerGender.FEMALE
                                }
                            },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFF18364A),
                                contentColor = Color.White
                            )
                        ) {
                            Text("لاعبة")
                        }
                    }

                } else {

                    Text(
                        text = if (
                            playerGender == SystemPlayerGender.MALE
                        ) {
                            "مرافقتك الذكية: ميار"
                        } else {
                            "مرافقك الذكي: آدم"
                        },
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = appearance?.outfitName.orEmpty(),
                        color = primary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )

                    Text(
                        text = appearance?.outfitDescription.orEmpty(),
                        color = Color(0xFFB9C7D9),
                        fontSize = 13.sp,
                        lineHeight = 20.sp
                    )

                    Text(
                        text = "يتغير مظهر وألوان المرافق حسب العالم المختار.",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )

                    Button(
                        onClick = {
                            if (
                                SystemCompanionGenderSettings.clear(context)
                            ) {
                                playerGender = null
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF18364A),
                            contentColor = primary
                        )
                    ) {
                        Text("تغيير ملف اللاعب")
                    }

                    Button(
                        onClick = onExplainClick,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = primary,
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            "اشرحي لي SYSTEM",
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Button(
                        onClick = onTalkClick,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF18364A),
                            contentColor = primary
                        )
                    ) {
                        Text("تحدث مع المرافق")
                    }
                }
            }
        }
    }
}
