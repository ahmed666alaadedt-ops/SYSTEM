
package com.system.irtqaa

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.UserProfileChangeRequest
import com.google.firebase.firestore.FirebaseFirestore

/**
 * بيانات حساب لاعب SYSTEM WORLD
 */
data class PlayerAccountProfile(
    val userId: String,
    val displayName: String,
    val email: String,
    val avatarUrl: String = "",
    val createdAt: Long = 0L
)

/**
 * إدارة حسابات اللاعبين وربطها بـ Firebase
 */
class FirebasePlayerAuthRepository {

    private val auth: FirebaseAuth =
        FirebaseAuth.getInstance()

    private val firestore: FirebaseFirestore =
        FirebaseFirestore.getInstance()

    private val playersCollection =
        firestore.collection("players")

    /**
     * الحصول على معرّف اللاعب الحالي
     */
    fun currentPlayerId(): String? {
        return auth.currentUser?.uid
    }

    /**
     * الحصول على حساب اللاعب الحالي
     */
    fun currentFirebaseUser(): FirebaseUser? {
        return auth.currentUser
    }

    /**
     * إنشاء حساب لاعب جديد
     */
    fun registerPlayer(
        displayName: String,
        email: String,
        password: String,
        callback: (Result<PlayerAccountProfile>) -> Unit
    ) {
        val cleanName = displayName.trim()
        val cleanEmail = email.trim()

        if (cleanName.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "اسم اللاعب مطلوب"
                    )
                )
            )
            return
        }

        if (cleanEmail.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "البريد الإلكتروني مطلوب"
                    )
                )
            )
            return
        }

        if (password.length < 6) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
                    )
                )
            )
            return
        }

        auth.createUserWithEmailAndPassword(
            cleanEmail,
            password
        )
            .addOnSuccessListener { result ->

                val firebaseUser = result.user

                if (firebaseUser == null) {
                    callback(
                        Result.failure(
                            Exception(
                                "تعذر إنشاء حساب اللاعب"
                            )
                        )
                    )
                    return@addOnSuccessListener
                }

                val profileUpdate =
                    UserProfileChangeRequest.Builder()
                        .setDisplayName(cleanName)
                        .build()

                firebaseUser.updateProfile(profileUpdate)
                    .addOnSuccessListener {

                        val profile =
                            PlayerAccountProfile(
                                userId = firebaseUser.uid,
                                displayName = cleanName,
                                email = cleanEmail,
                                avatarUrl = "",
                                createdAt =
                                    System.currentTimeMillis()
                            )

                        savePlayerProfile(
                            profile,
                            callback
                        )
                    }
                    .addOnFailureListener { error ->
                        callback(
                            Result.failure(error)
                        )
                    }
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * تسجيل دخول لاعب موجود
     */
    fun loginPlayer(
        email: String,
        password: String,
        callback: (Result<PlayerAccountProfile>) -> Unit
    ) {
        val cleanEmail = email.trim()

        if (cleanEmail.isEmpty() || password.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "أدخل البريد الإلكتروني وكلمة المرور"
                    )
                )
            )
            return
        }

        auth.signInWithEmailAndPassword(
            cleanEmail,
            password
        )
            .addOnSuccessListener { result ->

                val firebaseUser = result.user

                if (firebaseUser == null) {
                    callback(
                        Result.failure(
                            Exception(
                                "تعذر العثور على حساب اللاعب"
                            )
                        )
                    )
                    return@addOnSuccessListener
                }

                loadPlayerProfile(
                    firebaseUser,
                    callback
                )
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * تحميل بيانات اللاعب من Firestore
     */
    private fun loadPlayerProfile(
        firebaseUser: FirebaseUser,
        callback: (Result<PlayerAccountProfile>) -> Unit
    ) {
        playersCollection
            .document(firebaseUser.uid)
            .get()
            .addOnSuccessListener { document ->

                if (document.exists()) {

                    val profile =
                        PlayerAccountProfile(
                            userId = firebaseUser.uid,
                            displayName =
                                document.getString("displayName")
                                    ?: firebaseUser.displayName
                                    ?: "Player",
                            email =
                                document.getString("email")
                                    ?: firebaseUser.email
                                    ?: "",
                            avatarUrl =
                                document.getString("avatarUrl")
                                    ?: "",
                            createdAt =
                                document.getLong("createdAt")
                                    ?: 0L
                        )

                    callback(
                        Result.success(profile)
                    )

                } else {

                    val profile =
                        PlayerAccountProfile(
                            userId = firebaseUser.uid,
                            displayName =
                                firebaseUser.displayName
                                    ?: "Player",
                            email =
                                firebaseUser.email ?: "",
                            avatarUrl = "",
                            createdAt =
                                System.currentTimeMillis()
                        )

                    savePlayerProfile(
                        profile,
                        callback
                    )
                }
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * حفظ بيانات اللاعب في قاعدة البيانات
     */
    private fun savePlayerProfile(
        profile: PlayerAccountProfile,
        callback: (Result<PlayerAccountProfile>) -> Unit
    ) {
        val data = mapOf(
            "userId" to profile.userId,
            "displayName" to profile.displayName,
            "email" to profile.email,
            "avatarUrl" to profile.avatarUrl,
            "createdAt" to profile.createdAt
        )

        playersCollection
            .document(profile.userId)
            .set(data)
            .addOnSuccessListener {
                callback(
                    Result.success(profile)
                )
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * تحديث اسم اللاعب
     */
    fun updatePlayerName(
        newName: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        val cleanName = newName.trim()
        val user = auth.currentUser

        if (user == null || cleanName.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "الحساب أو اسم اللاعب غير صالح"
                    )
                )
            )
            return
        }

        val request =
            UserProfileChangeRequest.Builder()
                .setDisplayName(cleanName)
                .build()

        user.updateProfile(request)
            .addOnSuccessListener {

                playersCollection
                    .document(user.uid)
                    .update(
                        "displayName",
                        cleanName
                    )
                    .addOnSuccessListener {
                        callback(
                            Result.success(true)
                        )
                    }
                    .addOnFailureListener { error ->
                        callback(
                            Result.failure(error)
                        )
                    }
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * إرسال رابط إعادة تعيين كلمة المرور
     */
    fun sendPasswordReset(
        email: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        val cleanEmail = email.trim()

        if (cleanEmail.isEmpty()) {
            callback(
                Result.failure(
                    IllegalArgumentException(
                        "أدخل البريد الإلكتروني"
                    )
                )
            )
            return
        }

        auth.sendPasswordResetEmail(cleanEmail)
            .addOnSuccessListener {
                callback(
                    Result.success(true)
                )
            }
            .addOnFailureListener { error ->
                callback(
                    Result.failure(error)
                )
            }
    }

    /**
     * مراقبة حالة تسجيل الدخول
     */
    fun observeAuthState(
        onChanged: (FirebaseUser?) -> Unit
    ): FirebaseAuth.AuthStateListener {

        val listener =
            FirebaseAuth.AuthStateListener { firebaseAuth ->
                onChanged(firebaseAuth.currentUser)
            }

        auth.addAuthStateListener(listener)

        return listener
    }

    /**
     * إيقاف مراقبة حالة الحساب
     */
    fun removeAuthStateListener(
        listener: FirebaseAuth.AuthStateListener
    ) {
        auth.removeAuthStateListener(listener)
    }

    /**
     * تسجيل الخروج
     */
    fun logoutPlayer() {
        auth.signOut()
    }
}
