package com.sundeefundee.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sundeefundee.domain.model.EntitlementChecker
import com.sundeefundee.domain.model.Feature
import com.sundeefundee.domain.model.SubscriptionTier

/**
 * A modal bottom sheet that prompts the user to upgrade when they try to access
 * a premium feature they don't have access to.
 */
@Composable
fun PaywallDialog(
    feature: Feature,
    currentTier: SubscriptionTier,
    onUpgrade: () -> Unit,
    onDismiss: () -> Unit,
    onShowFullPaywall: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState()
    val requiredTier = EntitlementChecker.getRequiredTier(feature)
    val featureName = EntitlementChecker.getFeatureName(feature)
    val featureDescription = EntitlementChecker.getFeatureDescription(feature)
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Lock icon
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = null,
                    modifier = Modifier
                        .padding(16.dp)
                        .size(48.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Title
            Text(
                text = "$featureName Locked",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Description
            Text(
                text = featureDescription,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Tier requirement card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(32.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Requires ${requiredTier.displayName}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = getUpgradeMessage(requiredTier, currentTier),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Buttons
            Button(
                onClick = onUpgrade,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Upgrade to ${requiredTier.displayName}",
                    fontWeight = FontWeight.SemiBold
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedButton(
                onClick = onShowFullPaywall,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("See All Plans")
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            TextButton(onClick = onDismiss) {
                Text("Maybe Later")
            }
        }
    }
}

private fun getUpgradeMessage(requiredTier: SubscriptionTier, currentTier: SubscriptionTier): String {
    return when {
        currentTier == SubscriptionTier.FREE -> "Upgrade to unlock this feature"
        currentTier == SubscriptionTier.PLUS && requiredTier == SubscriptionTier.PREMIUM -> 
            "Upgrade to Premium for more features"
        currentTier.rank < requiredTier.rank -> 
            "Upgrade to unlock this feature"
        else -> "You have access to this feature"
    }
}

/**
 * Shows the PaywallDialog when triggered by accessing a premium feature
 */
@Composable
fun PremiumFeatureGate(
    feature: Feature,
    currentTier: SubscriptionTier,
    onUpgrade: () -> Unit,
    content: @Composable () -> Unit
) {
    if (EntitlementChecker.hasAccess(currentTier, feature)) {
        content()
    } else {
        // In a real app, this would show a gate or trigger the dialog
        // For now, we just show locked content
        LockedContent(
            feature = feature,
            onUnlock = onUpgrade
        )
    }
}

@Composable
private fun LockedContent(
    feature: Feature,
    onUnlock: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Lock,
            contentDescription = "Locked",
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = EntitlementChecker.getFeatureName(feature),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Medium
        )
        Text(
            text = "Premium Feature",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onUnlock) {
            Text("Unlock")
        }
    }
}
