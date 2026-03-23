package com.sundeefundee.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Tertiary

/**
 * Reusable loading indicator/spinner.
 */
@Composable
fun LoadingIndicator(
    modifier: Modifier = Modifier,
    message: String? = null,
    color: Color = Tertiary
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(48.dp),
                color = color,
                strokeWidth = 4.dp
            )

            if (message != null) {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

/**
 * Full screen loading state with app branding.
 */
@Composable
fun FullScreenLoading(
    message: String = "Loading..."
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(32.dp)
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(64.dp),
                color = Tertiary,
                strokeWidth = 4.dp
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Sundee Fundee",
                style = MaterialTheme.typography.headlineSmall,
                color = Primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * Inline loading indicator for smaller spaces.
 */
@Composable
fun InlineLoadingIndicator(
    modifier: Modifier = Modifier,
    size: Int = 24
) {
    CircularProgressIndicator(
        modifier = modifier.size(size.dp),
        color = Tertiary,
        strokeWidth = 2.dp
    )
}

/**
 * Loading state for lists.
 */
@Composable
fun ListLoadingIndicator(
    modifier: Modifier = Modifier,
    itemCount: Int = 3
) {
    Column(
        modifier = modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        repeat(itemCount) {
            LoadingListItem()
        }
    }
}

/**
 * Placeholder loading item for lists.
 */
@Composable
private fun LoadingListItem() {
    androidx.compose.foundation.shape.RoundedCornerShape
    Box(
        modifier = Modifier
            .fillMaxSize()
            .height(80.dp)
            .padding(vertical = 4.dp)
    ) {
        androidx.compose.material3.Card(
            modifier = Modifier.fillMaxSize(),
            colors = androidx.compose.material3.CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            )
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                androidx.compose.foundation.layout.Row {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .padding(4.dp)
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = Tertiary.copy(alpha = 0.5f),
                            strokeWidth = 2.dp
                        )
                    }

                    Spacer(modifier = Modifier.size(16.dp))

                    Column {
                        Box(
                            modifier = Modifier
                                .height(16.dp)
                                .fillMaxSize()
                        ) {
                            // Title placeholder
                            androidx.compose.material3.Text(
                                text = "",
                                style = MaterialTheme.typography.titleMedium
                            )
                        }
                    }
                }
            }
        }
    }
}
