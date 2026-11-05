package com.system.irtqaa

import android.content.Context
import com.google.firebase.firestore.FirebaseFirestore

class FirebaseSystemTaskSync(context: Context) {

    private val storage = SystemTaskStorage(context.applicationContext)
    private val firestore = FirebaseFirestore.getInstance()

    fun synchronize(
        userId: String,
        onComplete: (Boolean, Exception?) -> Unit
    ) {
        if (userId.isBlank()) {
            onComplete(
                false,
                IllegalArgumentException("User ID cannot be blank")
            )
            return
        }

        val tasksReference = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("tasks")
            .collection("items")

        tasksReference.get()
            .addOnSuccessListener { documents ->

                try {
                    val localTasks = storage.loadTasks(userId)

                    val cloudTasks = documents.documents.mapNotNull {
                        document ->

                        try {
                            val domain = SystemDevelopmentDomain.valueOf(
                                document.getString("domain")
                                    ?: return@mapNotNull null
                            )

                            SystemTaskDefinition(
                                taskId = document.getString("taskId")
                                    ?: document.id,
                                title = document.getString("title")
                                    ?: return@mapNotNull null,
                                description = document.getString("description")
                                    .orEmpty(),
                                domain = domain,
                                experienceReward =
                                    (document.getLong("experienceReward")
                                        ?: 10L).toInt(),
                                priority = runCatching {
                                    SystemTaskPriority.valueOf(
                                        document.getString("priority")
                                            ?: "NORMAL"
                                    )
                                }.getOrDefault(SystemTaskPriority.NORMAL),
                                repeat = runCatching {
                                    SystemTaskRepeat.valueOf(
                                        document.getString("repeat")
                                            ?: "NONE"
                                    )
                                }.getOrDefault(SystemTaskRepeat.NONE),
                                status = runCatching {
                                    SystemTaskStatus.valueOf(
                                        document.getString("status")
                                            ?: "PENDING"
                                    )
                                }.getOrDefault(SystemTaskStatus.PENDING),
                                createdAt = document.getLong("createdAt")
                                    ?: 0L,
                                dueAt = document.getLong("dueAt"),
                                completedAt = document.getLong("completedAt")
                            )
                        } catch (error: Exception) {
                            null
                        }
                    }

                    val mergedTasks = mergeTasks(
                        localTasks,
                        cloudTasks
                    )

                    storage.saveTasks(userId, mergedTasks)

                    if (mergedTasks.isEmpty()) {
                        onComplete(true, null)
                        return@addOnSuccessListener
                    }

                    val batch = firestore.batch()

                    mergedTasks.forEach { task ->
                        val document = tasksReference.document(task.taskId)

                        batch.set(
                            document,
                            mapOf(
                                "taskId" to task.taskId,
                                "title" to task.title,
                                "description" to task.description,
                                "domain" to task.domain.name,
                                "experienceReward" to task.experienceReward,
                                "priority" to task.priority.name,
                                "repeat" to task.repeat.name,
                                "status" to task.status.name,
                                "createdAt" to task.createdAt,
                                "dueAt" to task.dueAt,
                                "completedAt" to task.completedAt
                            )
                        )
                    }

                    batch.commit()
                        .addOnSuccessListener {
                            onComplete(true, null)
                        }
                        .addOnFailureListener { error ->
                            onComplete(false, error)
                        }

                } catch (error: Exception) {
                    onComplete(false, error)
                }
            }
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    private fun mergeTasks(
        localTasks: List<SystemTaskDefinition>,
        cloudTasks: List<SystemTaskDefinition>
    ): List<SystemTaskDefinition> {

        val merged = linkedMapOf<String, SystemTaskDefinition>()

        (cloudTasks + localTasks).forEach { task ->

            val existing = merged[task.taskId]

            if (existing == null) {
                merged[task.taskId] = task
            } else {
                merged[task.taskId] = chooseTaskVersion(
                    existing,
                    task
                )
            }
        }

        return merged.values.sortedBy { it.createdAt }
    }

    private fun chooseTaskVersion(
        first: SystemTaskDefinition,
        second: SystemTaskDefinition
    ): SystemTaskDefinition {

        if (first.status == SystemTaskStatus.COMPLETED) {
            return first
        }

        if (second.status == SystemTaskStatus.COMPLETED) {
            return second
        }

        if (first.status == SystemTaskStatus.CANCELLED) {
            return first
        }

        if (second.status == SystemTaskStatus.CANCELLED) {
            return second
        }

        return second
    }
}
