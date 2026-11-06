package com.system.irtqaa

enum class SystemPlayerGender(
    val storageValue: String
) {
    MALE("male"),
    FEMALE("female");

    companion object {
        fun fromStorage(value: String?): SystemPlayerGender {
            return when (value?.lowercase()?.trim()) {
                "female" -> FEMALE
                else -> MALE
            }
        }
    }
}

enum class SystemCompanionGender {
    MALE,
    FEMALE
}

data class SystemCompanionAppearance(
    val name: String,
    val gender: SystemCompanionGender,
    val world: SystemWorldKind,
    val worldTitle: String,
    val outfitName: String,
    val outfitDescription: String,
    val voiceStyle: String,
    val animationStyle: String
)

object SystemCompanionAppearanceEngine {

    fun create(
        playerGender: SystemPlayerGender,
        world: SystemWorldKind
    ): SystemCompanionAppearance {

        val companionGender =
            when (playerGender) {
                SystemPlayerGender.MALE ->
                    SystemCompanionGender.FEMALE

                SystemPlayerGender.FEMALE ->
                    SystemCompanionGender.MALE
            }

        val worldAppearance = when (world) {

            SystemWorldKind.MODERN_REALISTIC -> {
                WorldAppearance(
                    title = "العالم الحديث",
                    femaleOutfit = "الزي التقني المستقبلي",
                    maleOutfit = "الزي التقني الرجالي",
                    femaleDescription =
                        "ملابس عصرية مستقبلية أنيقة بتفاصيل هولوغرافية",
                    maleDescription =
                        "ملابس مستقبلية رجالية بتفاصيل تقنية وهولوغرافية"
                )
            }

            SystemWorldKind.MYTHOLOGY_HISTORY -> {
                WorldAppearance(
                    title = "عالم الحضارات التاريخية",
                    femaleOutfit = "الملابس التاريخية الملكية",
                    maleOutfit = "الملابس التاريخية الرجالية",
                    femaleDescription =
                        "ملابس مستوحاة من حضارات سومر وبابل ومصر القديمة وغيرها",
                    maleDescription =
                        "أزياء تاريخية رجالية تناسب الحضارة والعصر"
                )
            }

            SystemWorldKind.FANTASY -> {
                WorldAppearance(
                    title = "عالم الفانتازيا",
                    femaleOutfit = "الزي السحري",
                    maleOutfit = "زي الساحر والمرافق",
                    femaleDescription =
                        "ملابس سحرية أنيقة مع تفاصيل طاقة وتعويذات",
                    maleDescription =
                        "ملابس فانتازية مع عباءة وتفاصيل سحرية"
                )
            }

            SystemWorldKind.GREED_ISLAND -> {
                WorldAppearance(
                    title = "جزيرة الطمع",
                    femaleOutfit = "زي مستكشفة الكنوز",
                    maleOutfit = "زي مستكشف الكنوز",
                    femaleDescription =
                        "ملابس مغامرة مع أدوات وقطع كنوز نادرة",
                    maleDescription =
                        "ملابس استكشاف ومغامرات مع أدوات الكنوز"
                )
            }
        }

        val isFemale =
            companionGender == SystemCompanionGender.FEMALE

        return SystemCompanionAppearance(
            name = "ميار",
            gender = companionGender,
            world = world,
            worldTitle = worldAppearance.title,
            outfitName =
                if (isFemale) {
                    worldAppearance.femaleOutfit
                } else {
                    worldAppearance.maleOutfit
                },
            outfitDescription =
                if (isFemale) {
                    worldAppearance.femaleDescription
                } else {
                    worldAppearance.maleDescription
                },
            voiceStyle =
                if (isFemale) "FEMALE" else "MALE",
            animationStyle =
                if (isFemale) "FEMALE_MOTION" else "MALE_MOTION"
        )
    }

    private data class WorldAppearance(
        val title: String,
        val femaleOutfit: String,
        val maleOutfit: String,
        val femaleDescription: String,
        val maleDescription: String
    )
}
