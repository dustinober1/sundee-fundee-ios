package com.sundeefundee.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import com.sundeefundee.core.data.cache.SharedSnapshotStore

class RecoveryScoreWidget : GlanceAppWidget() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        val snapshot = remember { SharedSnapshotStore(context).readRecovery() }

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(day = 0xFFF4F0DF.toInt(), night = 0xFF1A1A2E.toInt())
                .padding(16.dp)
                .cornerRadius(16.dp)
        ) {
            Column(
                modifier = GlanceModifier.fillMaxSize(),
                verticalAlignment = Alignment.Vertical.CenterHorizontally,
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally
            ) {
                if (snapshot != null) {
                    Text(
                        text = "Recovery Score",
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(day = 0xFFD4A520.toInt()))
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = "${snapshot.total}",
                        style = TextStyle(fontSize = 36.sp, color = ColorProvider(day = 0xFF0D1A40.toInt()))
                    )
                    Text(
                        text = snapshot.recommendation.replaceFirstChar { it.uppercase() },
                        style = TextStyle(fontSize = 11.sp, color = ColorProvider(day = 0xFF666666.toInt()))
                    )
                } else {
                    Text(
                        text = "Sundee Fundee",
                        style = TextStyle(fontSize = 14.sp, color = ColorProvider(day = 0xFF0D1A40.toInt()))
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = "Open app to see recovery score",
                        style = TextStyle(fontSize = 11.sp, color = ColorProvider(day = 0xFF999999.toInt()))
                    )
                }
            }
        }
    }
}

class RecoveryScoreWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = RecoveryScoreWidget()
}
