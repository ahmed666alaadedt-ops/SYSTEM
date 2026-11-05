package com.system.irtqaa

import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import com.google.firebase.Timestamp

/**
 * ربط الدردشة العالمية مع Firebase.
 */
class FirebaseGlobalChatRepository {

    private val functions: FirebaseFunctions =
        FirebaseFunctions.getInstance()

    private val firestore: FirebaseFirestore =
        FirebaseFirestore.getInstance()

    /**
     * إرسال رسالة للمراجعة قبل نشرها.
     */
    fun submitGlobalMessage(
        text: String,
        callback: (Result<String>) -> Unit
    ) {
        val cleanText = text.trim()

        if (cleanText.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException("اكتب رسالة قبل الإرسال.")
                )
            )
            return
        }

        if (cleanText.length > 1000) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "الرسالة يجب ألا تتجاوز 1000 حرف."
                    )
                )
            )
            return
        }

        functions
            .getHttpsCallable("submitGlobalMessage")
            .call(mapOf("text" to cleanText))
            .addOnSuccessListener { result ->

                val data = result.data as? Map<*, *>
                val messageId =
                    data?.get("messageId") as? String

                if (messageId.isNullOrBlank()) {
                    callback(
                        Result.failure(
                            Exception("لم يصل معرّف الرسالة من الخادم.")
                        )
                    )
                } else {
                    callback(Result.success(messageId))
                }
            }
            .addOnFailureListener { error ->
                callback(Result.failure(error))
            }
    }

    /**
     * استقبال الرسائل التي وافق عليها المشرف مباشرة.
     */
    fun listenToApprovedGlobalMessages(
        callback: (Result<List<GlobalChatMessage>>) -> Unit
    ): ListenerRegistration {

        return firestore
            .collection("globalMessages")
            .whereEqualTo("moderationStatus", "approved")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(100)
            .addSnapshotListener { snapshot, error ->

                if (error != null) {
                    callback(Result.failure(error))
                    return@addSnapshotListener
                }

                if (snapshot == null) {
                    callback(
                        Result.failure(
                            Exception("تعذر تحميل رسائل الدردشة.")
                        )
                    )
                    return@addSnapshotListener
                }

                val messages = snapshot.documents.mapNotNull { document ->

                    val data = document.data ?: return@mapNotNull null

                    val senderId =
                        data["senderId"] as? String
                            ?: return@mapNotNull null

                    val senderName =
                        data["senderName"] as? String ?: "لاعب"

                    val text =
                        data["text"] as? String ?: ""

                    val imageUrl =
                        data["imageUrl"] as? String

                    val timestamp =
                        (data["createdAt"] as? Timestamp)
                            ?.toDate()
                            ?.time ?: 0L

                    GlobalChatMessage(
                        messageId = document.id,
                        sender = GlobalChatUser(
                            userId = senderId,
                            displayName = senderName
                        ),
                        text = text,
                        imageUrl = imageUrl,
                        timestamp = timestamp
                    )
                }

                callback(Result.success(messages))
            }
    }
}
