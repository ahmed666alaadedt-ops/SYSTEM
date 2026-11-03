
package com.system.irtqaa

object SystemVoiceChatEngine {

    fun createRoom(
        roomId: String,
        roomName: String,
        roomType: VoiceRoomType,
        ownerId: String,
        maxParticipants: Int = 10
    ): SystemVoiceRoom? {

        if (
            roomId.isBlank() ||
            roomName.isBlank() ||
            ownerId.isBlank() ||
            maxParticipants < 2
        ) {
            return null
        }

        return SystemVoiceRoom(
            roomId = roomId,
            roomName = roomName,
            roomType = roomType,
            ownerId = ownerId,
            maxParticipants = maxParticipants,
            isActive = true,
            isPrivate = roomType == VoiceRoomType.PRIVATE
        )
    }

    fun joinRoom(
        room: SystemVoiceRoom,
        participant: VoiceParticipant,
        settings: VoicePrivacySettings,
        hasInvitation: Boolean = false
    ): SystemVoiceRoom {

        if (participant.playerId.isBlank()) return room

        if (room.participants.any {
                it.playerId == participant.playerId
            }
        ) return room

        if (room.participants.size >= room.maxParticipants) {
            return room
        }

        val allowed = when (room.roomType) {
            VoiceRoomType.PRIVATE ->
                settings.allowPrivateCalls && hasInvitation

            VoiceRoomType.FRIENDS ->
                settings.allowGroupCalls

            VoiceRoomType.PUBLIC ->
                settings.allowPublicRooms

            VoiceRoomType.GUILD ->
                settings.allowGuildVoice
        }

        if (!allowed) return room

        return room.copy(
            participants = room.participants + participant,
            isActive = true
        )
    }

    fun leaveRoom(
        room: SystemVoiceRoom,
        playerId: String
    ): SystemVoiceRoom {

        val remaining = room.participants.filterNot {
            it.playerId == playerId
        }

        return room.copy(
            participants = remaining,
            isActive = remaining.isNotEmpty()
        )
    }

    fun setMicrophone(
        room: SystemVoiceRoom,
        playerId: String,
        enabled: Boolean,
        permissionGranted: Boolean
    ): SystemVoiceRoom {

        if (enabled && !permissionGranted) return room

        return room.copy(
            participants = room.participants.map { participant ->
                if (participant.playerId == playerId) {
                    participant.copy(
                        isMicrophoneEnabled = enabled,
                        isMuted = !enabled
                    )
                } else {
                    participant
                }
            }
        )
    }

    fun setSpeaking(
        room: SystemVoiceRoom,
        playerId: String,
        speaking: Boolean
    ): SystemVoiceRoom {

        return room.copy(
            participants = room.participants.map { participant ->
                if (
                    participant.playerId == playerId &&
                    participant.isMicrophoneEnabled &&
                    !participant.isMuted
                ) {
                    participant.copy(isSpeaking = speaking)
                } else {
                    participant
                }
            }
        )
    }

    fun createInvitation(
        invitationId: String,
        roomId: String,
        senderId: String,
        receiverId: String
    ): VoiceCallInvitation? {

        if (
            invitationId.isBlank() ||
            roomId.isBlank() ||
            senderId.isBlank() ||
            receiverId.isBlank() ||
            senderId == receiverId
        ) {
            return null
        }

        return VoiceCallInvitation(
            invitationId = invitationId,
            roomId = roomId,
            senderId = senderId,
            receiverId = receiverId,
            createdAt = System.currentTimeMillis()
        )
    }

    fun respondToInvitation(
        invitation: VoiceCallInvitation,
        playerId: String,
        accept: Boolean
    ): VoiceCallInvitation {

        if (
            invitation.receiverId != playerId ||
            invitation.isAccepted
        ) {
            return invitation
        }

        return invitation.copy(
            isAccepted = accept
        )
    }

    fun getActiveParticipants(
        room: SystemVoiceRoom
    ): List<VoiceParticipant> {
        return room.participants
    }

    fun closeRoom(
        room: SystemVoiceRoom,
        requesterId: String
    ): SystemVoiceRoom {

        if (room.ownerId != requesterId) return room

        return room.copy(
            participants = emptyList(),
            isActive = false
        )
    }
}
