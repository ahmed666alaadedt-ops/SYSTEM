package com.system.irtqaa

class SystemTaskEngine(
    private val progressEngine: SystemProgressEngine
) {
    private val tasks =
        mutableMapOf<String, LinkedHashMap<String, SystemTaskDefinition>>()

    fun addTask(
        userId: String,
        task: SystemTaskDefinition
    ): SystemTaskDefinition {
        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }

        val userTasks = tasks.getOrPut(userId) {
            linkedMapOf()
        }

        require(!userTasks.containsKey(task.taskId)) {
            "Task ID already exists"
        }

        userTasks[task.taskId] = task
        return task
    }

    fun getTasks(userId: String): List<SystemTaskDefinition> {
        return tasks[userId]?.values?.toList() ?: emptyList()
    }

    fun getTask(
        userId: String,
        taskId: String
    ): SystemTaskDefinition? {
        return tasks[userId]?.get(taskId)
    }

    fun updateTaskStatus(
        userId: String,
        taskId: String,
        status: SystemTaskStatus
    ): SystemTaskDefinition? {
        require(status != SystemTaskStatus.COMPLETED) {
            "Use completeTask to complete a task"
        }

        val current = getTask(userId, taskId) ?: return null

        if (current.status == SystemTaskStatus.COMPLETED ||
            current.status == SystemTaskStatus.CANCELLED
        ) {
            return null
        }

        val updated = current.copy(status = status)
        tasks[userId]?.set(taskId, updated)

        return updated
    }

    fun completeTask(
        userId: String,
        taskId: String
    ): SystemTaskDefinition? {
        val current = getTask(userId, taskId) ?: return null

        if (current.status == SystemTaskStatus.COMPLETED ||
            current.status == SystemTaskStatus.CANCELLED
        ) {
            return null
        }

        val now = System.currentTimeMillis()

        val updated = current.copy(
            status = SystemTaskStatus.COMPLETED,
            completedAt = now
        )

        tasks[userId]?.set(taskId, updated)

        progressEngine.addExperience(
            userId = userId,
            domain = current.domain,
            amount = current.experienceReward,
            reason = "Task completed: ${current.title}",
            timestamp = now
        )

        return updated
    }

    fun getTasksByDomain(
        userId: String,
        domain: SystemDevelopmentDomain
    ): List<SystemTaskDefinition> {
        return getTasks(userId).filter {
            it.domain == domain
        }
    }

    fun getTasksByStatus(
        userId: String,
        status: SystemTaskStatus
    ): List<SystemTaskDefinition> {
        return getTasks(userId).filter {
            it.status == status
        }
    }

    fun getOverdueTasks(
        userId: String
    ): List<SystemTaskDefinition> {
        return getTasks(userId).filter {
            it.isOverdue
        }
    }

    fun getCompletedTaskCount(userId: String): Int {
        return getTasksByStatus(
            userId,
            SystemTaskStatus.COMPLETED
        ).size
    }

    fun getPendingTaskCount(userId: String): Int {
        return getTasksByStatus(
            userId,
            SystemTaskStatus.PENDING
        ).size
    }

    fun removeTask(
        userId: String,
        taskId: String
    ): Boolean {
        return tasks[userId]?.remove(taskId) != null
    }
}
