package com.system.irtqaa

enum class SystemTaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED
}

enum class SystemTaskPriority {
    LOW,
    NORMAL,
    HIGH,
    CRITICAL
}

enum class SystemTaskRepeat {
    NONE,
    DAILY,
    WEEKLY
}

data class SystemTaskDefinition(
    val taskId: String,
    val title: String,
    val description: String = "",
    val domain: SystemDevelopmentDomain,
    val experienceReward: Int = 10,
    val priority: SystemTaskPriority = SystemTaskPriority.NORMAL,
    val repeat: SystemTaskRepeat = SystemTaskRepeat.NONE,
    val status: SystemTaskStatus = SystemTaskStatus.PENDING,
    val createdAt: Long = System.currentTimeMillis(),
    val dueAt: Long? = null,
    val completedAt: Long? = null
) {
    init {
        require(taskId.isNotBlank()) {
            "Task ID cannot be blank"
        }
        require(title.isNotBlank()) {
            "Task title cannot be blank"
        }
        require(experienceReward > 0) {
            "Experience reward must be positive"
        }
    }

    val isCompleted: Boolean
        get() = status == SystemTaskStatus.COMPLETED

    val isOverdue: Boolean
        get() = dueAt != null &&
            dueAt < System.currentTimeMillis() &&
            status != SystemTaskStatus.COMPLETED &&
            status != SystemTaskStatus.CANCELLED
}
