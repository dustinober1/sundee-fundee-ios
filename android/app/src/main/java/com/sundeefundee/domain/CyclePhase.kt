package com.sundeefundee.domain

/**
 * Represents the four phases of the menstrual cycle.
 */
enum class CyclePhase(val displayName: String, val emoji: String) {
    MENSTRUAL("Menstrual", "🌊"),
    FOLLICULAR("Follicular", "🌱"),
    OVULATION("Ovulation", "⚡️"),
    LUTEAL("Luteal", "🌕");

    companion object {
        fun fromString(value: String): CyclePhase {
            return when (value.lowercase()) {
                "menstrual" -> MENSTRUAL
                "follicular" -> FOLLICULAR
                "ovulation" -> OVULATION
                "luteal" -> LUTEAL
                else -> FOLLICULAR
            }
        }
    }
}
