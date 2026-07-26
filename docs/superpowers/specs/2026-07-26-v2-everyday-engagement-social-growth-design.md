# Sundee Fundee 2.0 Everyday Engagement and Social Growth Design

**Date:** 2026-07-26  
**Status:** Approved for implementation planning  
**Target:** Version 2.0

## Goal

Make Sundee Fundee useful every day, improve training consistency, and create privacy-safe organic growth through private buddies, small invite-only groups, encouragement, and selective sharing.

The core product loop is:

1. Open the daily plan.
2. Optionally check in.
3. Train, recover intentionally, or rest.
4. Share a safe update or encourage someone.
5. Return the next day.

Version 2.0 rewards showing up without demanding perfect workout streaks. Its promise is: **Show up today, do what fits, and stay connected.**

## Product Principles

- Opening the app must provide value within seconds and require no interaction.
- Presence is positive, but workouts and intentional recovery remain more meaningful.
- Rest and active recovery are successful outcomes when they fit the user's needs.
- Missed days do not erase broader consistency.
- Social participation is private, optional, and controlled by the user.
- Sensitive health and training context is private by default.
- Cooperative goals replace public rankings and competitive volume comparisons.
- Training intelligence remains deterministic and separate from engagement mechanics.
- Guest mode retains the solo experience; social relationships require Apple Sign-In.
- All features remain free, with no paywalls or paid engagement mechanics.

## Everyday Engagement Loop

### Today Experience

The Today screen is the daily home. Opening it records one private presence event for the current local calendar day and immediately presents:

- today's readiness and recommended action;
- an optional one-tap status;
- the next scheduled or suggested workout;
- buddy and group activity that needs attention;
- current weekly momentum.

The one-tap statuses are:

- Ready
- Tired
- Sore
- Resting
- Trained

Selecting a status is optional. The existing richer recovery and symptom check-in remains available when the user wants to provide more context.

### Participation Levels

Daily participation has three distinct levels:

1. **Showed up:** the user opened the app.
2. **Checked in:** the user selected a status or completed a richer check-in.
3. **Took action:** the user trained, performed intentional active recovery, rested intentionally, or supported another user.

All levels contribute positively to consistency, but the UI preserves their meaning rather than collapsing them into one score. A presence event is recorded no more than once per local calendar day.

### Tone

The product uses language such as:

- “4 days present this week”
- “Welcome back”
- “Recovery was the plan today”

It does not use lost-streak warnings, countdown pressure, guilt-based reminders, or language implying that a rest day is a failure.

## Consistency Momentum

Version 2.0 replaces brittle workout streaks with a descriptive Consistency Momentum system.

The primary momentum view includes:

- days present this week;
- check-ins completed;
- training and intentional-recovery days;
- encouragement given and received;
- a rolling four-week consistency trend.

Momentum is not a spendable currency. The app does not add XP, loot mechanics, paid boosts, or competitive point farming.

Achievements celebrate:

- a first consistent week;
- returning after time away;
- completing planned workouts;
- choosing recovery when recommended;
- encouraging a buddy;
- helping every group member participate;
- reaching a cooperative group goal.

## Buddies and Private Groups

### Relationship Model

Version 2.0 supports:

- one primary private accountability buddy;
- small invite-only groups capped at eight members.

The initial release does not include public profiles, follower counts, a public feed, direct-message inboxes, a friend graph, or global leaderboards.

### Visibility Controls

For each relationship or group, a user can share:

- presence only;
- a chosen daily status;
- a completed workout summary;
- a selected achievement or progress card;
- nothing.

Cycle data, pain data, HealthKit inputs, readiness scores, and readiness drivers are never shared by default. Users do not receive a control that silently exposes these raw categories; only deliberately constructed, privacy-safe derived statements may be shared.

Revoking a visibility choice deletes the corresponding shared snapshot instead of only hiding it locally.

### Social Actions

The social experience emphasizes lightweight support:

- react with a preset encouragement;
- send a private “thinking of you” nudge;
- share today's workout or intentional rest;
- see who has checked in recently;
- participate in a cooperative weekly goal.

Preset interactions are used instead of free-form direct messaging in version 2.0. This limits moderation and safety risk while keeping encouragement fast.

### Cooperative Goals

Example goals include:

- “Collectively show up 20 times this week.”
- “Everyone completes one intentional movement day.”
- “Encourage every group member once.”

Goals never rank members by weight lifted, readiness, cycle phase, workout volume, or health signals.

### Invitations and Membership Safety

Invitations use private CloudKit share links. The first social release includes:

- invitation acceptance;
- invitation expiration;
- invitation revocation;
- leaving a group;
- removing a member;
- blocking a user;
- owner continuity rules;
- clear handling for invalid or previously used links.

A sole owner must transfer ownership before leaving a group that still has members. If the group has no other members, leaving may delete the group after explicit confirmation.

## Organic Sharing and Growth

Users may create external share cards for:

- consistency milestones;
- completed workouts;
- group goals;
- encouragement milestones;
- selected progress achievements.

Every card is previewed before sharing and contains only user-approved information. External cards may contain an app invitation link. Invitation attribution records only the campaign or share-card type and the accepted invitation; it does not attach private health or training content.

The app does not automatically post activity or expose in-app group membership publicly.

## Architecture

The training-intelligence system remains the authority for readiness, safety, workout adaptation, progression, pain substitutions, and deload decisions. The engagement layer consumes safe outcomes and never changes training prescriptions.

### `DailyPresenceService`

Responsibilities:

- record one presence event per local calendar day;
- preserve the time-zone identifier used when the event is created;
- derive weekly presence and rolling consistency summaries;
- support local-first writes and later synchronization.

It depends on a small presence store abstraction, not on SwiftUI or HealthKit.

### `AccountabilityService`

Responsibilities:

- create and manage buddy relationships and groups;
- manage roles and membership;
- create, accept, revoke, and validate invitations;
- leave, remove, and block;
- coordinate CloudKit share access.

It does not build UI summaries or expose private training records.

### `SocialSnapshotBuilder`

Responsibilities:

- accept an explicit visibility policy and private source outcome;
- construct a minimal, sanitized shared snapshot;
- reject fields outside the approved shared schema;
- delete obsolete snapshots when visibility is reduced.

This is the sole path from private activity into a shared record zone.

### `EncouragementService`

Responsibilities:

- create preset reactions and nudges;
- deduplicate repeated actions;
- queue offline actions;
- enforce blocking and membership rules.

### `GroupGoalService`

Responsibilities:

- evaluate cooperative goals from sanitized participation records;
- produce group progress and milestone events;
- avoid access to raw HealthKit, cycle, pain, or readiness inputs.

### `EngagementNotificationService`

Responsibilities:

- schedule an optional daily-plan reminder;
- deliver direct encouragement notifications;
- bundle group activity into a digest;
- announce group milestones;
- schedule a gentle return reminder after inactivity;
- redact sensitive content from all notification text.

## CloudKit and Persistence

### Private Records

Presence, detailed check-ins, readiness assessments, cycle data, pain data, HealthKit-derived context, and full workout records stay in the user's private or local store.

A daily presence record uses a stable identifier based on the local day and stores:

- record identifier;
- local day key;
- time-zone identifier;
- first-open date;
- most recent open date;
- participation level;
- optional selected status;
- date created;
- date updated;
- model version.

Dates use ISO8601 string encoding and CloudKit-safe field names.

### Shared Records

Each buddy relationship or group uses a dedicated CloudKit custom record zone with a `CKShare`. Sanitized records in that zone may include:

- member identity reference and safe display name;
- presence day;
- selected status when authorized;
- safe workout-completion summary when authorized;
- preset encouragement;
- cooperative goal contribution;
- selected share-card metadata.

No raw HealthKit samples are copied into CloudKit. No private readiness, pain, cycle, symptom, or detailed check-in record is copied into a shared zone.

New record types require CloudKit schema validation, queryable record-identifier indexes where queried, Development testing, and Production deployment before release.

### Guest Mode

Guests receive local presence, check-ins, momentum, and achievements. Creating or joining a buddy relationship or group requires Apple Sign-In. The sign-in prompt explains that shared CloudKit access is required for the selected social action; it does not block solo features.

### Offline Behavior

Presence and private check-ins write locally first. Social actions use an engagement-specific retry queue with stable mutation identifiers and idempotent processing.

The UI distinguishes:

- synced;
- pending;
- retrying;
- action required.

A social sync failure never blocks the daily plan, check-in, or workout.

## Notifications

Notification categories are independently configurable:

- daily plan;
- direct encouragement;
- group digest;
- group milestones;
- return reminder.

Users can configure quiet hours. Group updates are bundled rather than delivered individually. Lock-screen text does not mention cycle phase, pain, readiness scores, HealthKit details, or private recovery drivers.

Notification denial is handled gracefully and does not reduce product functionality.

## Error Handling and Safety

- User-facing errors use actionable product copy and never expose raw CloudKit errors.
- Expired and revoked invitations explain how to request a new invitation.
- Pending shared actions remain visible and retryable.
- Removing or blocking a member updates local access immediately, then retries CloudKit revocation until confirmed.
- A revocation failure is surfaced to the initiating user as an action-required privacy issue.
- All shared views revalidate membership and blocking state before presenting cached data.
- HealthKit denial does not affect presence, momentum, or social features.
- Account deletion revokes owned shares, leaves joined shares, and removes locally cached social data.

## Privacy-Safe Measurement

Version 2.0 measures product behavior without recording sensitive content. Initial aggregate events cover:

- daily and weekly active use;
- users present on at least three days in a week;
- daily-plan opens that lead to a check-in or action;
- workout and intentional-recovery completion;
- buddy connections;
- group joins;
- encouragement sent and received;
- four-week retention for solo, buddy, and group cohorts;
- external share invitations that are accepted.

Events may include a feature version, surface, and coarse participation type. They must not include health samples, cycle details, pain details, check-in answers, readiness drivers, workout notes, generated text, or shared-card content.

## Testing

### Unit Tests

- local-day and time-zone presence boundaries;
- one-presence-per-day idempotency;
- participation-level transitions;
- rolling consistency calculations;
- group-goal calculations;
- visibility-policy filtering;
- rejection of sensitive shared fields;
- notification redaction;
- invitation and role-state transitions;
- backward-compatible record decoding.

### Integration Tests

- CloudKit share creation and acceptance;
- member removal, blocking, and access revocation;
- invitation expiration and revocation;
- offline queue replay and deduplication;
- local-first presence synchronization;
- visibility reduction deleting shared snapshots;
- guest-to-signed-in migration;
- account deletion cleanup.

An explicit privacy test must prove that every supported private input fails to serialize into a shared record.

### UI and Manual Verification

- Today provides value without a required tap;
- opening records presence only once;
- rest and active recovery appear as successful actions;
- missed days use non-punitive language;
- social features remain understandable with no connections;
- pending and failed actions are visually distinct;
- Dynamic Type and VoiceOver cover all social actions;
- blocking and leaving flows are accessible;
- notifications remain useful with sensitive previews disabled;
- HealthKit and notification denial never create a dead end.

## Delivery Phases

### Phase 1: Daily Presence and Momentum

Deliver the solo everyday loop, one-tap statuses, presence records, consistency summaries, achievements, and optional daily reminder.

### Phase 2: One-to-One Buddies

Deliver sign-in gating, CloudKit sharing, buddy invitations, visibility controls, sanitized snapshots, encouragement, blocking, and removal.

### Phase 3: Small Groups

Deliver groups of up to eight members, roles, invite lifecycle, bundled activity, cooperative goals, group digests, and owner continuity.

### Phase 4: External Growth

Deliver milestone share cards, privacy previews, invitation links, and privacy-safe invitation attribution.

Each phase must be independently useful and pass its privacy, accessibility, offline, and CloudKit release gates before the next phase begins.

## Success Criteria

- The Today screen provides a useful daily decision without mandatory interaction.
- An app open counts once as daily presence.
- Check-ins, workouts, recovery, rest, and encouragement remain meaningfully distinct.
- Missed days never reset or erase the rolling consistency record.
- Users can connect privately with a buddy and join groups of no more than eight members.
- Every social field is user-controlled and sanitized before sharing.
- No HealthKit, cycle, pain, or private readiness details enter shared record zones.
- Solo features work for guests and when social sync is unavailable.
- Social actions work offline and converge without duplicates.
- Cooperative goals do not rank sensitive or performance data.
- External sharing requires preview and explicit user action.
- Aggregate measurement contains no sensitive content.

## Out of Scope

- Public profiles or public activity feeds;
- follower or friend graphs;
- free-form direct messaging;
- public leaderboards;
- groups larger than eight members;
- automatic social posting;
- competitive workout-volume rankings;
- points economies, paid boosts, or engagement paywalls;
- external backends or third-party dependencies;
- App Store upload or submission;
- replacing deterministic training decisions with engagement logic.
