package com.system.irtqaa

enum class FriendRequestStatus {
    PENDING,
    ACCEPTED,
    REJECTED
}

data class SystemFriend(
    val playerId: String,
    val playerName: String,
    val playerLevel: Int,
    val isOnline: Boolean = false,
    val lastSeen: Long = 0L
)

data class FriendRequest(
    val id: String,
    val senderId: String,
    val receiverId: String,
    val status: FriendRequestStatus =
        FriendRequestStatus.PENDING,
    val createdAt: Long = 0L
)

data class SystemChatMessage(
    val id: String,
    val senderId: String,
    val receiverId: String,
    val message: String,
    val sentAt: Long = 0L,
    val isRead: Boolean = false
)

data class SocialPrivacySettings(
    val allowFriendRequests: Boolean = true,
    val allowMessages: Boolean = true,
    val showOnlineStatus: Boolean = true,
    val allowVoiceChat: Boolean = false
)

data class SystemBlock(
    val blockerId: String,
    val blockedPlayerId: String,
    val createdAt: Long = 0L
)
