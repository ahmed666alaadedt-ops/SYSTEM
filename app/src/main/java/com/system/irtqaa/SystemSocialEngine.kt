package com.system.irtqaa

object SystemSocialEngine {

    fun sendFriendRequest(
        requests: List<FriendRequest>,
        senderId: String,
        receiverId: String,
        settings: SocialPrivacySettings
    ): List<FriendRequest> {

        if (senderId.isBlank() || receiverId.isBlank()) {
            return requests
        }

        if (senderId == receiverId) return requests
        if (!settings.allowFriendRequests) return requests

        val alreadyExists = requests.any {
            it.senderId == senderId &&
            it.receiverId == receiverId &&
            it.status == FriendRequestStatus.PENDING
        }

        if (alreadyExists) return requests

        val request = FriendRequest(
            id = "${senderId}_${receiverId}_${requests.size}",
            senderId = senderId,
            receiverId = receiverId
        )

        return requests + request
    }

    fun respondToRequest(
        requests: List<FriendRequest>,
        requestId: String,
        accept: Boolean
    ): List<FriendRequest> {

        return requests.map { request ->
            if (
                request.id == requestId &&
                request.status == FriendRequestStatus.PENDING
            ) {
                request.copy(
                    status = if (accept)
                        FriendRequestStatus.ACCEPTED
                    else
                        FriendRequestStatus.REJECTED
                )
            } else {
                request
            }
        }
    }

    fun getFriends(
        requests: List<FriendRequest>,
        playerId: String
    ): List<String> {

        return requests
            .filter {
                it.status == FriendRequestStatus.ACCEPTED
            }
            .mapNotNull { request ->
                when (playerId) {
                    request.senderId -> request.receiverId
                    request.receiverId -> request.senderId
                    else -> null
                }
            }
            .distinct()
    }

    fun blockPlayer(
        blocks: List<SystemBlock>,
        blockerId: String,
        blockedPlayerId: String
    ): List<SystemBlock> {

        if (
            blockerId.isBlank() ||
            blockedPlayerId.isBlank() ||
            blockerId == blockedPlayerId
        ) {
            return blocks
        }

        val exists = blocks.any {
            it.blockerId == blockerId &&
            it.blockedPlayerId == blockedPlayerId
        }

        if (exists) return blocks

        return blocks + SystemBlock(
            blockerId = blockerId,
            blockedPlayerId = blockedPlayerId
        )
    }

    fun isBlocked(
        blocks: List<SystemBlock>,
        playerId: String,
        otherPlayerId: String
    ): Boolean {

        return blocks.any {
            (it.blockerId == playerId &&
             it.blockedPlayerId == otherPlayerId) ||
            (it.blockerId == otherPlayerId &&
             it.blockedPlayerId == playerId)
        }
    }

    fun sendMessage(
        messages: List<SystemChatMessage>,
        senderId: String,
        receiverId: String,
        message: String,
        settings: SocialPrivacySettings,
        blocks: List<SystemBlock>
    ): List<SystemChatMessage> {

        if (
            senderId.isBlank() ||
            receiverId.isBlank() ||
            message.isBlank() ||
            senderId == receiverId
        ) {
            return messages
        }

        if (!settings.allowMessages) return messages

        if (isBlocked(blocks, senderId, receiverId)) {
            return messages
        }

        val newMessage = SystemChatMessage(
            id = "${senderId}_${receiverId}_${messages.size}",
            senderId = senderId,
            receiverId = receiverId,
            message = message.trim()
        )

        return messages + newMessage
    }

    fun getConversation(
        messages: List<SystemChatMessage>,
        playerId: String,
        otherPlayerId: String
    ): List<SystemChatMessage> {

        return messages.filter {
            (it.senderId == playerId &&
             it.receiverId == otherPlayerId) ||
            (it.senderId == otherPlayerId &&
             it.receiverId == playerId)
        }
    }
}
