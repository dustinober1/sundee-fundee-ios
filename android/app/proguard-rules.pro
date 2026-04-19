# Sundee Fundee Android — ProGuard/R8 Rules

# Keep serialization annotations
-keepattributes *Annotation*, InnerClasses, Signature
-dontnote kotlinx.serialization.AnnotationsKt

# Keep domain models (used with kotlinx.serialization)
-keepclassmembers class com.sundeefundee.core.model.** {
    *** Companion;
}
-keepclasseswithmembers class com.sundeefundee.core.model.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep sealed class subclasses for serialization
-keep class * extends com.sundeefundee.core.domain.exercise.ExerciseValue { *; }

# Room entities
-keep class com.sundeefundee.core.data.room.entity.** { *; }

# kotlinx.serialization
-keep class kotlinx.serialization.** { *; }

# Supabase SDK
-keep class io.github.jan.supabase.** { *; }

# Health Connect
-keep class androidx.health.connect.client.** { *; }

# Kotlinx datetime
-keep class kotlinx.datetime.** { *; }
