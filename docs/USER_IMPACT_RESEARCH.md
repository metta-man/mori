# Mori User Impact Research

Date: 2026-05-09

## Core Finding

Mori's current premise is strong, but "death someday" is psychologically too distant for most users. The product should stop treating mortality as the main behavior driver and use it as the frame that makes near-term choices matter.

The highest-impact experience is:

> My time is finite -> this week is real -> this person/value matters -> I can do one concrete action today.

## Why The Current Impact Feels Weak

### 1. Distant death is abstract

Construal Level Theory suggests distant events are represented more abstractly, while near events are represented more concretely. A countdown to death can be visually striking, but if the end point is decades away, many users read it as concept art rather than an instruction for today.

Product implication: the app should zoom from lifetime to year to week to today. The LifeGrid should not only say "you have 2,392 weeks left"; it should ask "what would make this week not disappear?"

### 2. Mortality salience can backfire unless paired with values

Terror Management Theory research suggests mortality reminders often push people to defend existing identities, values, and cultural norms. That can produce prosocial behavior when helping, connection, or virtue is made salient, but it can also create avoidance, anxiety, or shallow worldview defense.

Product implication: never leave the user alone with death. Pair the reminder with a chosen value, relationship, or meaningful action.

### 3. Motivation is not enough

The Fogg Behavior Model frames behavior as motivation, ability, and prompt converging at the same moment. Mori already has motivation. The missing pieces are ability and prompt: an action that is small enough to do immediately, shown at the exact moment the user is emotionally open.

Product implication: every intense screen needs a tiny next step, not just reflection.

### 4. Behavior change needs self-monitoring plus feedback

Digital behavior change reviews repeatedly find engagement links with goal setting, self-monitoring, feedback, prompts/cues, rewards, and social support. Mori has tracking primitives, but the feedback should become more personally meaningful.

Product implication: feedback should say "you are becoming the kind of person who..." rather than only "5/7 completed."

## Biggest Product Shift

Move Mori from a "mortality awareness app" to a "finite-life action loop."

The current loop:

1. See life remaining.
2. Feel something.
3. Maybe reflect.

The stronger loop:

1. See finite time.
2. Pick the life domain that matters today.
3. Commit to one tiny action.
4. Complete it.
5. Save proof of meaning.
6. See the LifeGrid update with lived evidence, not just elapsed time.

## Recommended Features

### P0: This Week Must Matter

Replace the generic daily entry point with a weekly intention ritual.

User flow:

1. Sunday or Monday: "This week has one empty square. What would make it worth filling?"
2. User chooses one focus: Health, Love, Craft, Courage, Family, Wonder, Service, Rest.
3. User writes or selects one tiny action.
4. During the week, widgets and reminders refer to that action.
5. At week close, the week cell is marked with a subtle color or symbol based on the chosen focus.

Why it works:

- Turns lifetime abstraction into a near-term decision.
- Connects mortality to identity and values.
- Creates visual evidence in the LifeGrid.

Example copy:

- "One square is being written right now."
- "What would make this week unmistakably yours?"
- "Choose one thing your future self would be glad you did."

### P0: Relationship-Based Prompts

Add a small set of prompts that aim the user toward people, not just self-optimization.

Examples:

- "Who would be warmed by hearing from you today?"
- "What conversation have you been postponing?"
- "Who made your life larger this week?"
- "Send one sentence of gratitude."

Why it works:

- Mortality reminders are more constructive when prosocial norms and connection are salient.
- Relationships create immediate emotional relevance.
- A message can be completed in under two minutes.

Design note: avoid public social features. Use private, local-first nudges: copy a message, open share sheet, or log that the user reached out.

### P1: Future-Self Conversation

Let users write to themselves at 40, 50, 60, or "one year from now." Later, Mori resurfaces the note.

Prompts:

- "What do you hope I did with this season?"
- "What should I stop pretending can wait?"
- "What would make you proud of this year?"

Why it works:

- Future-self continuity is associated with better long-term choices.
- It makes the distant self socially and emotionally closer.
- It fits Mori's contemplative tone.

### P1: Memento To Action

Every quote, countdown, or LifeGrid insight should end with an action chip.

Examples:

- "Call someone"
- "Take a walk"
- "Write 3 lines"
- "Do the hard 10 minutes"
- "Put the phone down"

Rules:

- Actions should take 2-10 minutes.
- The user should be able to complete them without configuring a habit system.
- Completion should add a small "proof" marker to today or this week.

### P1: Life Domains Instead Of Generic Habits

Current habits risk feeling like any tracker. Mori should organize actions by life domains:

- Body
- Mind
- Love
- Work
- Home
- Courage
- Service
- Beauty

This makes the question bigger than "did I meditate?" The real question becomes "what part of my life did I honor today?"

### P2: Legacy Capsule

A private archive for memories, lessons, photos, and notes to people. This is especially valuable for older users, but should be framed softly for everyone.

Features:

- "A lesson I do not want to lose"
- "A story worth preserving"
- "A note for someone I love"
- Export as PDF or plain text

## Onboarding Recommendation

The current onboarding creates emotional connection before data collection, which is right. The missing piece is personal relevance.

Suggested first-session sequence:

1. Show LifeGrid preview.
2. Ask birth date.
3. Reveal personalized grid.
4. Immediately zoom into current week.
5. Ask: "What would make this week worth remembering?"
6. User chooses a life domain.
7. User picks one tiny action.
8. App schedules or surfaces one prompt.

Do not end onboarding on the big countdown. End on a chosen action.

## Copy Direction

Use mortality language sparingly. Make the primary voice tender, concrete, and time-bound.

Prefer:

- "This week is still open."
- "A small proof that you lived today."
- "What deserves your attention before the day closes?"
- "One action. One person. One square."

Avoid:

- "You are running out of time."
- "Death is coming."
- "Make every second count."
- "No excuses."

## Measurement Plan

Track impact with behavior and self-report, not only retention.

### Activation

- User creates first weekly intention.
- User completes first tiny action.
- User adds first relationship/gratitude entry.

### Depth

- Weekly intention completion rate.
- Percentage of weeks with a reflection or action.
- Number of relationship prompts acted on.
- Journal entries revisited after creation.

### Emotional Outcome

Ask one lightweight weekly question:

- "Did Mori help you live more intentionally this week?"
- Scale: Not really / A little / Yes / Strongly
- Optional: "What did it change?"

### Safety

Because mortality content can intensify anxiety, include:

- Countdown hide mode.
- Softer "focus on today" mode.
- Ability to reduce reminder intensity.
- No shame language for missed days.

## Implementation Priority

1. Weekly intention ritual attached to current LifeGrid week.
2. Tiny action chips after all major mortality/reflection surfaces.
3. Relationship prompts and private gratitude/share flow.
4. LifeGrid proof markers by life domain.
5. Future-self letters.
6. Legacy capsule and export.

## Sources

- Trope and Liberman's Construal Level Theory research: distant events are construed more abstractly than near events. See "The effect of temporal distance on level of mental construal" and the overview "Construal Levels and Psychological Distance."
- Terror Management Theory and mortality salience research: mortality reminders can increase adherence to salient values and norms; prosocial effects are stronger when helping/social values are made salient. See Jonas et al., "The Scrooge Effect"; Gailliot et al., "Mortality Salience Increases Adherence to Salient Norms and Values"; and the 2023 meta-analysis on norm salience.
- Fogg Behavior Model: behavior needs motivation, ability, and prompt at the same moment. Mori should reduce action size and prompt at emotionally meaningful moments.
- Behavior Change Technique Taxonomy and mobile health reviews: goal setting, self-monitoring, feedback, prompts/cues, rewards, and social support are repeatedly associated with engagement in behavior-change apps.
- Future-self continuity literature: interventions that make the future self feel closer are used to influence long-term decisions and wellbeing.

