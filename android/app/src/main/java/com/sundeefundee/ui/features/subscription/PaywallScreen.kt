package com.sundeefundee.ui.features.subscription

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.hilt.navigation.compose.hiltViewModel
import com.android.billingclient.api.ProductDetails
import com.sundeefundee.domain.model.SubscriptionTier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(
    viewModel: SubscriptionViewModel = hiltViewModel(),
    onDismiss: () -> Unit,
    canDismiss: Boolean = true
) {
    val currentTier by viewModel.currentTier.collectAsState()
    val availableProducts by viewModel.availableProducts.collectAsState()
    val purchaseInProgress by viewModel.purchaseInProgress.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val selectedBillingPeriod by viewModel.selectedBillingPeriod.collectAsState()
    
    val context = LocalContext.current
    
    LaunchedEffect(Unit) {
        viewModel.loadProducts()
    }
    
    Dialog(
        onDismissRequest = { if (canDismiss) onDismiss() },
        properties = DialogProperties(
            dismissOnBackPress = canDismiss,
            dismissOnClickOutside = canDismiss,
            usePlatformDefaultWidth = false
        )
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(0.dp),
            color = MaterialTheme.colorScheme.background
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Close button
                    if (canDismiss) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.End
                        ) {
                            IconButton(onClick = onDismiss) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Close"
                                )
                            }
                        }
                    } else {
                        Spacer(modifier = Modifier.height(48.dp))
                    }
                    
                    // Header
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Sundee Fundee",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    
                    Text(
                        text = "Unlock Your Full Potential",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    // Benefits section
                    BenefitsSection()
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    // Billing period toggle
                    BillingPeriodToggle(
                        selectedPeriod = selectedBillingPeriod,
                        onPeriodSelected = viewModel::selectBillingPeriod
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Subscription tiers
                    SubscriptionTierCards(
                        currentTier = currentTier,
                        plusProducts = viewModel.getPlusProducts(),
                        premiumProducts = viewModel.getPremiumProducts(),
                        selectedBillingPeriod = selectedBillingPeriod,
                        onPurchasePlus = { product ->
                            viewModel.purchase(product, context as Activity)
                        },
                        onPurchasePremium = { product ->
                            viewModel.purchase(product, context as Activity)
                        }
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Restore purchases
                    TextButton(onClick = { viewModel.restorePurchases() }) {
                        Text("Restore Purchases")
                    }
                    
                    // Error message
                    errorMessage?.let { error ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(32.dp))
                }
                
                // Loading overlay
                if (purchaseInProgress) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.5f)),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Color.White)
                    }
                }
            }
        }
    }
}

@Composable
private fun BenefitsSection() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "What You Get",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Plus benefits
        BenefitItem(
            icon = "✓",
            title = "AI Workout Generation",
            description = "Personalized workouts powered by AI"
        )
        BenefitItem(
            icon = "✓",
            title = "Advanced Analytics",
            description = "Deep insights into your performance"
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Premium benefits
        BenefitItem(
            icon = "★",
            title = "Unlimited Programs",
            description = "Access to all training programs"
        )
        BenefitItem(
            icon = "★",
            title = "Priority Support",
            description = "Get help when you need it most"
        )
    }
}

@Composable
private fun BenefitItem(
    icon: String,
    title: String,
    description: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primaryContainer),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = icon,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun BillingPeriodToggle(
    selectedPeriod: BillingPeriod,
    onPeriodSelected: (BillingPeriod) -> Unit
) {
    Row(
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        FilterChip(
            selected = selectedPeriod == BillingPeriod.MONTHLY,
            onClick = { onPeriodSelected(BillingPeriod.MONTHLY) },
            label = { Text("Monthly") },
            colors = FilterChipDefaults.filterChipColors(
                selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
            )
        )
        Spacer(modifier = Modifier.width(8.dp))
        FilterChip(
            selected = selectedPeriod == BillingPeriod.ANNUAL,
            onClick = { onPeriodSelected(BillingPeriod.ANNUAL) },
            label = { 
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Annual")
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Save 33%",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            colors = FilterChipDefaults.filterChipColors(
                selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
            )
        )
    }
}

@Composable
private fun SubscriptionTierCards(
    currentTier: SubscriptionTier,
    plusProducts: List<ProductDetails>,
    premiumProducts: List<ProductDetails>,
    selectedBillingPeriod: BillingPeriod,
    onPurchasePlus: (ProductDetails) -> Unit,
    onPurchasePremium: (ProductDetails) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        // Plus Tier Card
        SubscriptionTierCard(
            tierName = "Plus",
            tier = SubscriptionTier.PLUS,
            currentTier = currentTier,
            products = plusProducts,
            selectedBillingPeriod = selectedBillingPeriod,
            onPurchase = onPurchasePlus,
            isPremium = false
        )
        
        // Premium Tier Card
        SubscriptionTierCard(
            tierName = "Premium",
            tier = SubscriptionTier.PREMIUM,
            currentTier = currentTier,
            products = premiumProducts,
            selectedBillingPeriod = selectedBillingPeriod,
            onPurchase = onPurchasePremium,
            isPremium = true
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SubscriptionTierCard(
    tierName: String,
    tier: SubscriptionTier,
    currentTier: SubscriptionTier,
    products: List<ProductDetails>,
    selectedBillingPeriod: BillingPeriod,
    onPurchase: (ProductDetails) -> Unit,
    isPremium: Boolean
) {
    val selectedProduct = products.find {
        when (selectedBillingPeriod) {
            BillingPeriod.MONTHLY -> it.productId.contains("monthly")
            BillingPeriod.ANNUAL -> it.productId.contains("annual")
        }
    }
    
    val isCurrentTier = currentTier.rank >= tier.rank
    
    val cardColor = if (isPremium) {
        Brush.linearGradient(
            colors = listOf(
                MaterialTheme.colorScheme.primary,
                MaterialTheme.colorScheme.tertiary
            )
        )
    } else {
        Brush.linearGradient(
            colors = listOf(
                MaterialTheme.colorScheme.secondaryContainer,
                MaterialTheme.colorScheme.secondary
            )
        )
    }
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isPremium) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.secondaryContainer
            }
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Tier badge
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(
                        if (isPremium) MaterialTheme.colorScheme.primary
                        else MaterialTheme.colorScheme.secondary
                    )
                    .padding(horizontal = 12.dp, vertical = 4.dp)
            ) {
                Text(
                    text = tierName,
                    color = if (isPremium) MaterialTheme.colorScheme.onPrimary
                    else MaterialTheme.colorScheme.onSecondary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Price
            selectedProduct?.let { product ->
                val offer = product.subscriptionOfferDetails?.firstOrNull()
                val price = offer?.formattedPrice ?: "N/A"
                
                Text(
                    text = price,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isPremium) MaterialTheme.colorScheme.onPrimaryContainer
                    else MaterialTheme.colorScheme.onSecondaryContainer
                )
                
                val period = when (selectedBillingPeriod) {
                    BillingPeriod.MONTHLY -> "/month"
                    BillingPeriod.ANNUAL -> "/year"
                }
                Text(
                    text = period,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isPremium) MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    else MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Purchase button
            Button(
                onClick = { selectedProduct?.let { onPurchase(it) } },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isCurrentTier && selectedProduct != null,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isPremium) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.secondary,
                    disabledContainerColor = if (isPremium) MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                    else MaterialTheme.colorScheme.secondary.copy(alpha = 0.5f)
                )
            ) {
                Text(
                    text = when {
                        isCurrentTier -> "Current Plan"
                        currentTier.rank > 0 && currentTier.rank < tier.rank -> "Upgrade"
                        else -> "Subscribe"
                    },
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}
