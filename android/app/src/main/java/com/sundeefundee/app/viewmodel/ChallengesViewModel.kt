package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.challenge.ChallengeEngine
import com.sundeefundee.core.domain.challenge.computeProgress
import com.sundeefundee.core.domain.challenge.updateVolume
import com.sundeefundee.core.model.Challenge
import com.sundeefundee.core.model.ChallengeProgress
import com.sundeefundee.core.model.ChallengeType
import com.sundeefundee.core.model.Workout
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ChallengesViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _challenges = MutableStateFlow<List<Pair<Challenge, ChallengeProgress>>>(emptyList())
    val challenges = _challenges.asStateFlow()

    private val _showCreateDialog = MutableStateFlow(false)
    val showCreateDialog = _showCreateDialog.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val workouts: List<Workout> = dataClientFactory.client.fetchAll("Workout")
                val savedChallenges: List<Challenge> = dataClientFactory.client.fetchAll("Challenge")

                val allChallenges = if (savedChallenges.isEmpty()) {
                    listOf(ChallengeEngine.createLifetimeChallenge())
                } else {
                    savedChallenges
                }

                _challenges.value = allChallenges.map { challenge ->
                    val totalVolume = when (challenge.type) {
                        ChallengeType.LIFETIME -> workouts.sumOf { it.totalVolume }
                        ChallengeType.EXERCISE -> workouts.sumOf { it.totalVolume } // simplified
                        ChallengeType.CUSTOM -> challenge.currentVolume
                    }
                    val progress = computeProgress(challenge, totalVolume)
                    challenge to progress
                }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun createChallenge(title: String, targetVolume: Double, type: ChallengeType) {
        viewModelScope.launch {
            val challenge = when (type) {
                ChallengeType.EXERCISE -> ChallengeEngine.createExerciseChallenge(title)
                ChallengeType.CUSTOM -> ChallengeEngine.createCustomChallenge(title, targetVolume.toLong())
                ChallengeType.LIFETIME -> ChallengeEngine.createLifetimeChallenge()
            }
            try {
                dataClientFactory.client.save(challenge, "Challenge")
                _showCreateDialog.value = false
                loadData()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun showCreate() {
        _showCreateDialog.value = true
    }

    fun dismissCreate() {
        _showCreateDialog.value = false
    }
}
