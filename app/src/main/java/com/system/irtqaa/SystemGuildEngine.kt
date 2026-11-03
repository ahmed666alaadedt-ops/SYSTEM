package com.system.irtqaa

object SystemGuildEngine {

    fun createGuild(
        id: String,
        name: String,
        description: String,
        leader: GuildMember
    ): SystemGuild? {

        if (name.isBlank()) return null
        if (leader.playerId.isBlank()) return null

        val guildLeader = leader.copy(
            rank = GuildRank.LEADER
        )

        return SystemGuild(
            id = id,
            name = name,
            description = description,
            leaderId = leader.playerId,
            members = listOf(guildLeader)
        )
    }

    fun joinGuild(
        guild: SystemGuild,
        member: GuildMember
    ): SystemGuild? {

        if (!guild.isRecruiting) return null

        if (guild.members.size >= guild.maxMembers) {
            return null
        }

        if (guild.members.any {
                it.playerId == member.playerId
            }) {
            return null
        }

        return guild.copy(
            members = guild.members + member.copy(
                rank = GuildRank.BEGINNER
            )
        )
    }

    fun leaveGuild(
        guild: SystemGuild,
        playerId: String
    ): SystemGuild? {

        if (playerId == guild.leaderId) return null

        val memberExists = guild.members.any {
            it.playerId == playerId
        }

        if (!memberExists) return null

        return guild.copy(
            members = guild.members.filterNot {
                it.playerId == playerId
            }
        )
    }

    fun addContribution(
        guild: SystemGuild,
        playerId: String,
        points: Int
    ): SystemGuild? {

        if (points <= 0) return null

        val memberExists = guild.members.any {
            it.playerId == playerId
        }

        if (!memberExists) return null

        val updatedMembers = guild.members.map { member ->
            if (member.playerId == playerId) {
                member.copy(
                    contributionPoints =
                        member.contributionPoints + points
                )
            } else {
                member
            }
        }

        val newExperience = guild.experience + points
        val newLevel = 1 + (newExperience / 500)

        return guild.copy(
            members = updatedMembers,
            experience = newExperience,
            level = newLevel
        )
    }

    fun getGuildMembers(
        guild: SystemGuild
    ): List<GuildMember> {
        return guild.members.sortedByDescending {
            it.contributionPoints
        }
    }

    fun getMemberCount(
        guild: SystemGuild
    ): Int {
        return guild.members.size
    }
}
