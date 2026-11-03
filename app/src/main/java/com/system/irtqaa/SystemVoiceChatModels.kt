package com.system.irtqaa

enum class VoiceRoomType {
    PRIVATE,
    FRIENDS,
    PUBLIC,
    GUILD
}

enum class VoiceParticipantStatus {
    CONNECTED,
    MUTED,
    SPEAKING,
    DISCONNECTED
}

data class VoiceParticipant(
    val playerId: String,
    val playerName: String,
    val isMicrophoneEnabled: Boolean = false,
    val isMuted: Boolean = false,
    val isSpeaking: Boolean = false,
    val joinedAt: Long = 0L
)

data class SystemVoiceRoom(
    val roomId: String,
    val roomName: String,
    val roomType: VoiceRoomType,
    val ownerId: String,
    val participants: List<VoiceParticipant> = emptyList(),
    val maxParticipants: Int = 10,
    val isActive: Boolean = false,
    val isPrivate: Boolean = false
)

data class VoicePrivacySettings(
    val allowPrivateCalls: Boolean = true,
    val allowGroupCalls: Boolean = true,
    val allowPublicRooms: Boolean = true,
    val allowGuildVoice: Boolean = true,
    val microphonePermissionGranted: Boolean = false
)

data class VoiceCallInvitation(
    val invitationId: String,
    val roomId: String,
    val senderId: String,
    val receiverId: String,
    val isAccepted: Boolean = false,
    val createdAt: Long = 0L
)
