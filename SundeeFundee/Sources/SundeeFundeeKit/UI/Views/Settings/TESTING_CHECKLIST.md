# Testing Checklist for UX Improvements

## 🎯 Quick Start Testing Guide

Use this checklist to systematically test all the new features.

---

## ✅ **Pre-Testing Setup**

### **1. Build the Project**
- [ ] Clean build folder (`Cmd+Shift+K`)
- [ ] Build project (`Cmd+B`)
- [ ] Verify 0 errors in Issue Navigator

### **2. Launch the App**
- [ ] Select simulator (iPhone 15 Pro recommended)
- [ ] Run app (`Cmd+R`)
- [ ] App launches without crashes

---

## 🧪 **Test 1: New User - Complete Onboarding Flow**

### **Reset to New User State:**
1. Go to **Settings** in the app
2. Scroll to **Debug Tools** section (only visible in DEBUG builds)
3. Tap **"Full Reset (Sign Out)"**
4. App should return to login screen

### **Test the Flow:**
- [ ] See authentication screen (Sign In / Guest)
- [ ] Tap "Continue as Guest" or "Sign in with Apple"
- [ ] **Onboarding appears** with progress bar
- [ ] Page 1: Welcome screen with disclaimers
- [ ] Tap "Next"
- [ ] Page 2: Preferences (Goal, Weight Unit, Cycle Tracking, Equipment)
- [ ] **Find "Cycle Tracking" card** - should have toggle + "Learn how this works" button
- [ ] Tap **"Learn how this works"**
  - [ ] Cycle education sheet appears
  - [ ] Can scroll through all sections
  - [ ] Can expand phase cards (Menstrual, Follicular, Ovulation, Luteal)
  - [ ] Can expand FAQ items
  - [ ] Tap "Done" to dismiss
- [ ] Back on onboarding page 2
- [ ] Enable/disable cycle tracking toggle (test it works)
- [ ] Tap "Start First Workout" OR "Not now - go to dashboard"

### **Expected: Feature Tour Appears**
- [ ] **Feature Tour automatically launches** after onboarding
- [ ] Progress indicator shows 3 dots (first one highlighted)
- [ ] **Page 1: Your Dashboard**
  - [ ] Calendar icon with bounce animation
  - [ ] 3 bullet points about dashboard features
  - [ ] "Skip Tour" button visible
  - [ ] "Next" button visible
- [ ] Tap "Next"
- [ ] **Page 2: Cycle-Aware Training**
  - [ ] 4 cycle phase icons with pulse animation
  - [ ] 3 bullet points about cycle training
  - [ ] If cycle tracking OFF: See note "You can enable cycle tracking anytime in Settings"
  - [ ] "Skip Tour" and "Next" buttons visible
- [ ] Tap "Next"
- [ ] **Page 3: Track Your Wins**
  - [ ] Trophy icon with bounce animation
  - [ ] 3 bullet points about progress tracking
  - [ ] "Ready to get started?" message at bottom
  - [ ] "Skip Tour" button NOT visible
  - [ ] "Get Started" button visible
- [ ] Tap "Get Started"
- [ ] **Dashboard appears** - onboarding complete!

### **Verify Dashboard State:**
- [ ] If cycle tracking enabled: Cycle phase banner visible
- [ ] If cycle tracking disabled: No cycle banner
- [ ] Other dashboard content loads normally

---

## 🧪 **Test 2: Feature Tour - Skip Functionality**

### **Reset:**
1. Settings → Debug Tools → "Reset Onboarding"
2. App should show onboarding again

### **Test Skip:**
- [ ] Complete onboarding quickly (any preferences)
- [ ] Feature tour appears
- [ ] On Page 1, tap **"Skip Tour"**
- [ ] Should immediately go to dashboard (tour skipped)

### **Test Skip on Page 2:**
- [ ] Settings → Debug Tools → "Reset Feature Tour"
- [ ] Complete onboarding
- [ ] Feature tour appears
- [ ] Swipe/tap to Page 2
- [ ] Tap **"Skip Tour"**
- [ ] Should go to dashboard

**Expected:** Tour can be skipped from pages 1 and 2, but not page 3

---

## 🧪 **Test 3: Cycle Phase Education - Dashboard Access**

### **Prerequisites:**
- [ ] User has completed onboarding with **cycle tracking enabled**
- [ ] Dashboard is visible

### **Test Info Button:**
- [ ] Scroll to find **Cycle Phase Banner** on dashboard
- [ ] Banner shows current phase (e.g., "Follicular Phase")
- [ ] Banner shows phase description
- [ ] Banner shows confidence percentage with colored dot
- [ ] **Divider line visible** below confidence
- [ ] **Info button visible** below divider: "ⓘ Learn about cycle-aware training"
- [ ] Tap the info button
- [ ] **Cycle Education view appears**

### **Test Education Content:**
- [ ] Hero section with 4 cycle icons visible
- [ ] "Train Smarter with Your Cycle" heading
- [ ] "Why It Matters" section with 4 bullets
- [ ] **4 Phase Cards visible** (collapsed by default):
  - [ ] Menstrual Phase (red icon)
  - [ ] Follicular Phase (gold icon)
  - [ ] Ovulation Phase (orange icon)
  - [ ] Luteal Phase (gray icon)
- [ ] Tap **Menstrual Phase card**
  - [ ] Card expands smoothly
  - [ ] Shows "What's Happening" section
  - [ ] Shows "Training Approach" section
  - [ ] Shows "Key Hormones" with emoji indicators
- [ ] Tap same card again → Should collapse
- [ ] Tap **Follicular Phase card**
  - [ ] Previous card collapses
  - [ ] Follicular card expands
  - [ ] Content is different from Menstrual
- [ ] Test all 4 phase cards work
- [ ] Scroll to "How We Adapt Your Workouts" section
  - [ ] 4 adaptation bullets visible
  - [ ] Each has icon, title, description
- [ ] Scroll to "Understanding Confidence" section
  - [ ] 3 confidence levels shown with colored dots
  - [ ] Green (70-100%), Gold (40-69%), Orange (0-39%)
- [ ] Scroll to "Common Questions" section
  - [ ] 4 FAQ cards visible
- [ ] Tap first FAQ: "What if my cycle is irregular?"
  - [ ] Expands with answer
- [ ] Tap same FAQ → Collapses
- [ ] Test all FAQ cards expand/collapse
- [ ] Tap "Done" button in navigation bar
- [ ] Returns to dashboard

---

## 🧪 **Test 4: Cycle Education - Context Menu Access**

### **Test Long Press (iOS only):**
- [ ] On dashboard, **long-press** the cycle phase banner
- [ ] Context menu appears with:
  - [ ] "Share insight" option
  - [ ] "Learn more" option
- [ ] Tap **"Learn more"**
- [ ] Cycle education view opens
- [ ] Tap "Done" to dismiss

---

## 🧪 **Test 5: Settings Access - Help & Learning**

### **Test Feature Tour Re-watch:**
- [ ] Go to **Settings**
- [ ] Scroll to **"Help & Learning"** section
- [ ] Should see 2 items:
  - [ ] "Feature Tour" with map icon
  - [ ] "Cycle Phase Guide" with calendar icon
- [ ] Tap **"Feature Tour"**
- [ ] Feature tour opens as a sheet
- [ ] Can navigate through all 3 pages
- [ ] Tap "Get Started" or swipe down to dismiss
- [ ] Returns to Settings

### **Test Cycle Education:**
- [ ] Still in Settings → Help & Learning
- [ ] Tap **"Cycle Phase Guide"**
- [ ] Cycle education view opens
- [ ] Tap "Done" to return to Settings

---

## 🧪 **Test 6: Onboarding Cycle Education Link**

### **Reset:**
- [ ] Settings → Debug Tools → "Reset Onboarding"

### **Test:**
- [ ] Complete authentication
- [ ] Onboarding appears
- [ ] Navigate to Page 2 (Preferences)
- [ ] Find "Cycle Tracking" card
- [ ] Tap **"Learn how this works"** button
- [ ] Cycle education opens **as a sheet** (onboarding still visible behind it)
- [ ] Tap "Done" to dismiss
- [ ] **Still on onboarding** page 2 (not interrupted)
- [ ] Can continue with onboarding normally

---

## 🧪 **Test 7: Analytics Verification**

### **Enable Console Logging:**
1. In Xcode, open the **Console** (`Cmd+Shift+C`)
2. Filter for "Growth" or "Analytics"

### **Test Events:**
- [ ] Reset onboarding
- [ ] Complete onboarding
- [ ] Feature tour appears → Check console for `feature_tour_started`
- [ ] Complete tour → Check console for `feature_tour_completed`
- [ ] OR skip tour → Check console for `feature_tour_skipped` with page number

### **Cycle Education Events:**
- [ ] Open cycle education from dashboard
- [ ] Check console for `cycle_education_opened`
- [ ] Expand a phase card (e.g., Follicular)
- [ ] Check console for `cycle_education_phase_expanded` with `phase: "follicular"`
- [ ] Expand different phases
- [ ] Each should fire the event with correct phase name

---

## 🧪 **Test 8: Accessibility (VoiceOver)**

### **Enable VoiceOver:**
- iOS Simulator: Settings → Accessibility → VoiceOver → ON
- OR use **Accessibility Inspector** in Xcode

### **Test Feature Tour:**
- [ ] Reset and trigger feature tour
- [ ] VoiceOver announces page number: "Page 1 of 3"
- [ ] Reads button labels correctly ("Skip Tour", "Next")
- [ ] Icons are hidden from VoiceOver (shouldn't read icon names)
- [ ] Bullet points are readable

### **Test Cycle Education:**
- [ ] Open cycle education
- [ ] VoiceOver can navigate all sections
- [ ] Phase cards are tappable and announce state (collapsed/expanded)
- [ ] FAQ cards work with VoiceOver
- [ ] "Done" button is accessible

---

## 🧪 **Test 9: Edge Cases**

### **Cycle Tracking Disabled:**
- [ ] Reset onboarding
- [ ] Complete onboarding with **cycle tracking OFF**
- [ ] Feature tour page 2 shows: "You can enable cycle tracking anytime in Settings"
- [ ] On dashboard, **no cycle banner** should appear
- [ ] Settings → Help & Learning → "Cycle Phase Guide" should **still be accessible**
- [ ] Education view works normally (users can learn even if not using feature)

### **Multiple Tour Views:**
- [ ] Open feature tour from Settings
- [ ] While tour is open, try opening it again
- [ ] Should not create duplicate sheets

### **Rapid Tapping:**
- [ ] On feature tour, rapidly tap "Next" button
- [ ] Should not skip pages or crash
- [ ] Animation should complete smoothly

---

## 🧪 **Test 10: Different Device Sizes**

### **Test on Multiple Simulators:**
- [ ] iPhone SE (small screen)
  - [ ] Feature tour pages readable
  - [ ] Cycle education scrollable
  - [ ] No text truncation
- [ ] iPhone 15 Pro Max (large screen)
  - [ ] Layouts scale appropriately
  - [ ] No excessive white space
- [ ] iPad (if supported)
  - [ ] Navigation works correctly
  - [ ] Sheets present appropriately

---

## 🧪 **Test 11: Dark Mode**

### **Switch to Dark Mode:**
- Simulator: Settings → Developer → Dark Appearance

### **Verify:**
- [ ] Feature tour readable in dark mode
- [ ] Cycle education readable
- [ ] Colors maintain good contrast
- [ ] Gold accents still visible
- [ ] Icons and bullets look good

---

## 🐛 **Bug Tracking Template**

If you find issues, document them like this:

```
**Issue:** [Brief description]
**Steps to Reproduce:**
1. 
2. 
3. 

**Expected:** 
**Actual:** 
**Severity:** Critical / High / Medium / Low
**Screenshot:** [Attach if possible]
```

---

## ✅ **Testing Complete!**

Once all tests pass:
- [ ] All features work as expected
- [ ] No crashes or errors
- [ ] Accessibility works
- [ ] Analytics events fire correctly
- [ ] Ready for code review / QA

---

## 🎉 **Bonus: User Testing Script**

Give this to a colleague or user for feedback:

```
Hi! We've added new onboarding features. Can you:

1. Delete the app and reinstall it
2. Complete the sign-up process
3. Notice anything different? (They should see the tour)
4. If you enabled cycle tracking, tap the info button on the cycle banner
5. Tell me: Was this helpful? Confusing? Too long?

Thanks!
```

---

**Happy Testing! 🚀**
