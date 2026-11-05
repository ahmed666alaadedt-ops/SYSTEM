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

        val tasksDocument = firestore
            .collection("players")
            .document(userId)
            .collection("systemData")
            .document("tasks")

        val tasksReference = tasksDocument.collection("items")
        val deletedReference = tasksDocument.collection("deletedItems")

        deletedReference.get()
            .addOnSuccessListener { deletedDocuments ->

                tasksReference.get()
                    .addOnSuccessListener { taskDocuments ->

                        try {
                            val localTasks = storage.loadTasks(userId)
                            val localDeletedIds =
                                storage.loadDeletedTaskIds(userId)

                            val cloudDeletedIds =
                                deletedDocuments.documents
                                    .map { it.id }
                                    .toSet()

                            // وجود المهمة محلياً بعد إزالة علامة حذفها
                            // يعني أن المستخدم أعاد إضافتها.
                            val restoredIds = localTasks
                                .map { it.taskId }
                                .toSet()

                            val deletedIds = (
                                localDeletedIds + cloudDeletedIds
                            ) - restoredIds

                            val cloudTasks = taskDocuments.documents
                                .mapNotNull { document ->

                                    // لا نستعيد أي مهمة عليها علامة حذف.
                                    if (document.id in deletedIds) {
                                        return@mapNotNull null
                                    }

                                    try {
                                        val domain =
                                            SystemDevelopmentDomain.valueOf(
                                                document.getString("domain")
                                                    ?: return@mapNotNull null
                                            )

                                        SystemTaskDefinition(
                                            taskId =
                                                document.getString("taskId")
                                                    ?: document.id,

                                            title =
                                                document.getString("title")
                                                    ?: return@mapNotNull null,

                                            description =
                                                document.getString("description")
                                                    .orEmpty(),

                                            domain = domain,

                                            experienceReward =
                                                (document.getLong(
                                                    "experienceReward"
                                                ) ?: 10L).toInt(),

                                            priority = runCatching {
                                                SystemTaskPriority.valueOf(
                                                    document.getString("priority")
                                                        ?: "NORMAL"
                                                )
                                            }.getOrDefault(
                                                SystemTaskPriority.NORMAL
                                            ),

                                            repeat = runCatching {
                                                SystemTaskRepeat.valueOf(
                                                    document.getString("repeat")
                                                        ?: "NONE"
                                                )
                                            }.getOrDefault(
                                                SystemTaskRepeat.NONE
                                            ),

                                            status = runCatching {
                                                SystemTaskStatus.valueOf(
                                                    document.getString("status")
                                                        ?: "PENDING"
                                                )
                                            }.getOrDefault(
                                                SystemTaskStatus.PENDING
                                            ),

                                            createdAt =
                                                document.getLong("createdAt")
                                                    ?: 0L,

                                            dueAt =
                                                document.getLong("dueAt"),

                                            completedAt =
                                                document.getLong("completedAt")
                                        )

                                    } catch (error: Exception) {
                                        null
                                    }
                                }

                            val filteredLocalTasks = localTasks
                                .filterNot {
                                    it.taskId in deletedIds
                                }

                            val mergedTasks = mergeTasks(
                                filteredLocalTasks,
                                cloudTasks
                            )

                            // نحفظ المهام وعلامات الحذف محلياً.
                            storage.saveTasks(
                                userId,
                                mergedTasks
                            )

                            storage.saveDeletedTaskIds(
                                userId,
                                deletedIds
                            )

                            val batch = firestore.batch()

                            // رفع المهام النشطة إلى السحابة.
                            mergedTasks.forEach { task ->

                                val document =
                                    tasksReference.document(task.taskId)

                                batch.set(
                                    document,
                                    mapOf(
                                        "taskId" to task.taskId,
                                        "title" to task.title,
                                        "description" to task.description,
                                        "domain" to task.domain.name,
                                        "experienceReward" to
                                            task.experienceReward,
                                        "priority" to task.priority.name,
                                        "repeat" to task.repeat.name,
                                        "status" to task.status.name,
                                        "createdAt" to task.createdAt,
                                        "dueAt" to task.dueAt,
                                        "completedAt" to task.completedAt
                                    )
                                )
                            }

                            // تسجيل الحذف في مجموعة مستقلة
                            // وحذف مستند المهمة الأصلي.
                            deletedIds.forEach { taskId ->

                                batch.set(
                                    deletedReference.document(taskId),
                                    mapOf(
                                        "taskId" to taskId,
                                        "deleted" to true,
                                        "deletedAt" to
                                            System.currentTimeMillis()
                                    )
                                )

                                batch.delete(
                                    tasksReference.document(taskId)
                                )
                            }

                            // إزالة علامة الحذف السحابية عند
                            // إعادة إضافة المهمة بنفس المعرّف.
                            restoredIds.forEach { taskId ->
                                batch.delete(
                                    deletedReference.document(taskId)
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
            .addOnFailureListener { error ->
                onComplete(false, error)
            }
    }

    private fun mergeTasks(
        localTasks: List<SystemTaskDefinition>,
        cloudTasks: List<SystemTaskDefinition>
    ): List<SystemTaskDefinition> {

        val merged =
            linkedMapOf<String, SystemTaskDefinition>()

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
