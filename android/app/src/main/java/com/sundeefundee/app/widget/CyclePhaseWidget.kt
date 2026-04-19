package com.sundeefundee.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import com.sundeefundee.core.data.cache.SharedSnapshotStore

class CyclePhaseWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = SharedSnapshotStore(context).readCyclePhase()
        provideContent {
            CycleWidgetContent(snapshot)
        }
    }

    @Composable
    private fun CycleWidgetContent(snapshot: com.sundeefundee.core.data.cache.CyclePhaseSnapshot?) {
        val phaseColor = when (snapshot?.phase) {
            "MENSTRUAL" -> Color(0xFFE53935)
            "FOLLICULAR" -> Color(0xFFD4A520)
            "OVULATION" -> Color(0xFFF27319)
            "LUTEAL" -> Color(0xFF5C6BC0)
            else -> Color(0xFF0D1A40)
        }

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(day = Color(0xFFF4F0DF), night = Color(0xFF1A1A2E))
                .padding(16.dp)
        ) {
            Column(
                modifier = GlanceModifier.fillMaxSize(),
                verticalAlignment = Alignment.Vertical.CenterVertically,
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally
            ) {
                if (snapshot != null) {
                    Text(
                        text = "Cycle Phase",
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(phaseColor))
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = snapshot.phase.lowercase().replaceFirstChar { it.uppercase() },
                        style = TextStyle(fontSize = 20.sp, color = ColorProvider(Color(0xFF0D1A40)))
                    )
                    Text(
                        text = "Day ${snapshot.day} of ${snapshot.cycleLength}",
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color(0xFF666666)))
                    )
                } else {
                    Text(
                        text = "Sundee Fundee",
                        style = TextStyle(fontSize = 14.sp, color = ColorProvider(Color(0xFF0D1A40)))
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = "Open app to see cycle phase",
                        style = TextStyle(fontSize = 11.sp, color = ColorProvider(Color(0xFF999999)))
                    )
                }
            }
        }
    }
}

class CyclePhaseWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CyclePhaseWidget()
}
