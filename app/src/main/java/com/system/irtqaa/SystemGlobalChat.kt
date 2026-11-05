
package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// بيانات حساب اللاعب
data class GlobalChatUser(
    val userId: String,
    val displayName: String,
    val avatarUrl: String = "",
    val isOnline: Boolean = false
)

// بيانات الرسالة
data class GlobalChatMessage(
    val messageId: String,
    val sender: GlobalChatUser,
    val text: String = "",
    val imageUrl: String? = null,
    val timestamp: Long = 0L
)

// طلب الصداقة
data class GlobalFriendRequest(
    val requestId: String,
    val sender: GlobalChatUser
)

// صديق اللاعب
data class GlobalFriend(
    val user: GlobalChatUser,
    val addedAt: Long = 0L
)

// أقسام الدردشة
private enum class GlobalChatTab {
    WORLD,
    FRIENDS,
    PRIVATE,
    GROUPS
}

@Composable
fun SystemGlobalChatScreen(
    currentUser: GlobalChatUser,
    messages: List<GlobalChatMessage>,
    friends: List<GlobalFriend>,
    requests: List<GlobalFriendRequest>,
    onSendMessage: (String) -> Unit,
    onSendImage: () -> Unit,
    onSendFriendRequest: (String) -> Unit,
    onAcceptFriendRequest: (String) -> Unit,
    onOpenPrivateChat: (String) -> Unit,
    onOpenGroups: () -> Unit
) {
    var selectedTab by remember {
        mutableStateOf(GlobalChatTab.WORLD)
    }

    var messageText by remember {
        mutableStateOf("")
    }

    var targetPlayerId by remember {
        mutableStateOf("")
    }

    val background = Color(0xFF080F1D)
    val panel = Color(0xFF14243A)
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(background)
            .padding(14.dp)
    ) {

        // العنوان
        Text(
            text = "SYSTEM WORLD",
            color = gold,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            text = "الدردشة العالمية",
            color = Color.White,
            fontSize = 21.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            text = "مرحباً ${currentUser.displayName}",
            color = cyan,
            fontSize = 13.sp
        )

        Spacer(Modifier.height(16.dp))

        // التنقل بين أقسام التواصل
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            val tabs = listOf(
                GlobalChatTab.WORLD to "العالمية",
                GlobalChatTab.FRIENDS to "الأصدقاء",
                GlobalChatTab.PRIVATE to "الخاصة",
                GlobalChatTab.GROUPS to "المجموعات"
            )

            tabs.forEach { (tab, title) ->
                Button(
                    onClick = {
                        selectedTab = tab

                        if (tab == GlobalChatTab.GROUPS) {
                            onOpenGroups()
                        }
                    },
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(
                        horizontal = 3.dp,
                        vertical = 8.dp
                    ),
                    colors = ButtonDefaults.buttonColors(
                        containerColor =
                            if (selectedTab == tab) gold else panel,
                        contentColor =
                            if (selectedTab == tab)
                                Color.Black
                            else
                                Color.White
                    ),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Text(
                        title,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        when (selectedTab) {

            // الدردشة العالمية
            GlobalChatTab.WORLD -> {

                Text(
                    "المحادثة العالمية",
                    color = gold,
                    fontWeight = FontWeight.Bold
                )

                Spacer(Modifier.height(10.dp))

                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    items(
                        messages,
                        key = { it.messageId }
                    ) { message ->

                        GlobalMessageItem(
                            message = message,
                            panel = panel,
                            gold = gold,
                            cyan = cyan
                        )
                    }
                }

                // كتابة الرسالة وإرسال الصور
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = onSendImage
                    ) {
                        Text("📷")
                    }

                    Spacer(Modifier.width(6.dp))

                    OutlinedTextField(
                        value = messageText,
                        onValueChange = {
                            messageText = it
                        },
                        modifier = Modifier.weight(1f),
                        placeholder = {
                            Text("اكتب رسالتك...")
                        },
                        singleLine = true,
                        shape = RoundedCornerShape(14.dp)
                    )

                    Spacer(Modifier.width(6.dp))

                    Button(
                        onClick = {
                            val text = messageText.trim()

                            if (text.isNotEmpty()) {
                                onSendMessage(text)
                                messageText = ""
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = gold,
                            contentColor = Color.Black
                        )
                    ) {
                        Text("إرسال")
                    }
                }
            }

            // قائمة الأصدقاء وطلبات الصداقة
            GlobalChatTab.FRIENDS -> {

                Text(
                    "إضافة صديق",
                    color = gold,
                    fontWeight = FontWeight.Bold
                )

                Spacer(Modifier.height(8.dp))

                OutlinedTextField(
                    value = targetPlayerId,
                    onValueChange = {
                        targetPlayerId = it
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = {
                        Text("أدخل رقم أو معرف اللاعب")
                    },
                    singleLine = true
                )

                Button(
                    onClick = {
                        val id = targetPlayerId.trim()

                        if (id.isNotEmpty()) {
                            onSendFriendRequest(id)
                            targetPlayerId = ""
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = gold,
                        contentColor = Color.Black
                    )
                ) {
                    Text("إرسال دعوة صداقة")
                }

                Spacer(Modifier.height(16.dp))

                Text(
                    "طلبات الصداقة (${requests.size})",
                    color = cyan,
                    fontWeight = FontWeight.Bold
                )

                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        requests,
                        key = { it.requestId }
                    ) { request ->

                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = panel
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                GlobalAvatar(
                                    request.sender,
                                    gold
                                )

                                Spacer(Modifier.width(10.dp))

                                Text(
                                    request.sender.displayName,
                                    color = Color.White,
                                    modifier = Modifier.weight(1f)
                                )

                                Button(
                                    onClick = {
                                        onAcceptFriendRequest(
                                            request.requestId
                                        )
                                    }
                                ) {
                                    Text("قبول")
                                }
                            }
                        }
                    }

                    item {
                        Spacer(Modifier.height(8.dp))

                        Text(
                            "أصدقائي (${friends.size})",
                            color = cyan,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    items(
                        friends,
                        key = { it.user.userId }
                    ) { friend ->

                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = panel
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                GlobalAvatar(
                                    friend.user,
                                    gold
                                )

                                Spacer(Modifier.width(10.dp))

                                Column(
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(
                                        friend.user.displayName,
                                        color = Color.White
                                    )

                                    Text(
                                        if (friend.user.isOnline)
                                            "متصل الآن"
                                        else
                                            "غير متصل",
                                        color = if (friend.user.isOnline)
                                            cyan
                                        else
                                            Color.Gray,
                                        fontSize = 11.sp
                                    )
                                }

                                TextButton(
                                    onClick = {
                                        onOpenPrivateChat(
                                            friend.user.userId
                                        )
                                    }
                                ) {
                                    Text("محادثة")
                                }
                            }
                        }
                    }
                }
            }

            // المحادثات الخاصة
            GlobalChatTab.PRIVATE -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("💬", fontSize = 48.sp)

                    Text(
                        "المحادثات الخاصة",
                        color = gold,
                        fontSize = 21.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "اختر صديقاً من قائمة الأصدقاء لفتح محادثته الخاصة.",
                        color = Color.LightGray,
                        fontSize = 14.sp
                    )
                }
            }

            // المجموعات
            GlobalChatTab.GROUPS -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("🌐", fontSize = 48.sp)

                    Text(
                        "مجموعات SYSTEM WORLD",
                        color = gold,
                        fontSize = 21.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "مجموعات للمهمات والبوابات والأراضي والتجارة والمغامرات.",
                        color = Color.LightGray,
                        fontSize = 14.sp
                    )
                }
            }
        }
    }
}

// عرض صورة الحساب والاسم بجانب الرسالة
@Composable
private fun GlobalAvatar(
    user: GlobalChatUser,
    gold: Color
) {
    Box(
        modifier = Modifier
            .size(42.dp)
            .background(
                Color(0xFF263B56),
                CircleShape
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            user.displayName.take(1),
            color = gold,
            fontSize = 19.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

// بطاقة الرسالة
@Composable
private fun GlobalMessageItem(
    message: GlobalChatMessage,
    panel: Color,
    gold: Color,
    cyan: Color
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(15.dp),
        colors = CardDefaults.cardColors(
            containerColor = panel
        )
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                GlobalAvatar(
                    message.sender,
                    gold
                )

                Spacer(Modifier.width(9.dp))

                Column {
                    Text(
                        message.sender.displayName,
                        color = gold,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        if (message.sender.isOnline)
                            "متصل"
                        else
                            "لاعب",
                        color = cyan,
                        fontSize = 10.sp
                    )
                }
            }

            if (message.text.isNotBlank()) {
                Spacer(Modifier.height(9.dp))

                Text(
                    message.text,
                    color = Color.White,
                    fontSize = 14.sp
                )
            }

            if (message.imageUrl != null) {
                Spacer(Modifier.height(8.dp))

                Text(
                    "📷 صورة مرفقة",
                    color = cyan
                )
            }
        }
    }
}
