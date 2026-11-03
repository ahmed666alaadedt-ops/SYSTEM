package com.system.irtqaa

enum class GuildRank {
    LEADER,
    OFFICER,
    MEMBER,
    BEGINNER
}

data class GuildMember(
    val playerId: String,
    val playerName: String,
    val playerLevel: Int,
    val rank: GuildRank = GuildRank.BEGINNER,
    val contributionPoints: Int = 0
)

data class SystemGuild(
    val id: String,
    val name: String,
    val description: String,
    val leaderId: String,
    val members: List<GuildMember> = emptyList(),
    val level: Int = 1,
    val experience: Int = 0,
    val maxMembers: Int = 20,
    val isRecruiting: Boolean = true
)

data class GuildInvitation(
    val id: String,
    val guildId: String,
    val invitedPlayerId: String,
    val message: String,
    val isAccepted: Boolean = false
)

data class GuildActivity(
    val id: String,
    val guildId: String,
    val title: String,
    val description: String,
    val requiredMembers: Int,
    val xpReward: Int,
    val coinReward: Int
)
