# Stepordle 🏥

An iPhone game that helps medical students master USMLE Step 1 high-yield topics through progressive clinical case reveals.

## Overview

Stepordle is inspired by Doctordle - a medical diagnosis guessing game where players are presented with clinical cases and must guess the correct diagnosis. With each incorrect guess, a new clinical clue is progressively revealed, helping guide the player toward the answer.

## Features

### 🎮 Core Gameplay
- **Progressive Hint System**: Start with basic patient presentation, unlock more detailed clues
- **5 Guesses**: Players have 5 attempts to diagnose the case correctly
- **5 Clinical Clues**: Up to 5 progressive hints reveal more details about the case
- **Smart Scoring**: Points based on efficiency (fewer guesses and hints = higher score)
  - Base: 500 points
  - -100 points per guess
  - -50 points per extra hint (first hint is free)

### 📊 Game Modes
1. **Daily Case**: Same case for everyone each day (seeded by date)
2. **Random Case**: Practice with random cases anytime
3. **Browse Cases**: Explore all available cases by category

### 📈 Statistics & Progress
- Win percentage tracking
- Current and maximum streaks
- Total and average scores
- Guess distribution chart
- Games played counter

### 🏥 Medical Categories
- **Cardiology**: MI, Heart Failure, Arrhythmias
- **Neurology**: MS, Stroke, Seizures
- **Pulmonology**: Pneumothorax, COPD, Pneumonia
- **Gastroenterology**: Pancreatitis, IBD, GI Bleeds
- **Endocrinology**: DKA, Thyroid disorders
- **Nephrology**: AKI, CKD, Nephrotic syndrome
- **Hematology**: Anemias, Coagulopathies, Sickle Cell
- **Infectious Disease**: Meningitis, Sepsis
- **Rheumatology**: Lupus, RA, Vasculitis
- **Psychiatry**: Depression, Bipolar, Schizophrenia

## Architecture

### SwiftData Models

#### `MedicalCase`
- Stores diagnosis, alternative names, hints, category, and difficulty
- Methods for validating diagnosis guesses

#### `GameSession`
- Tracks current game state, guesses, and hints revealed
- Handles game logic and scoring calculations

#### `PlayerStats`
- Persistent player statistics
- Win rate, streaks, score tracking
- Guess distribution data

### Views

#### `ContentView`
Main menu with:
- Daily case button
- Random case button
- Browse cases button
- Stats and About buttons
- Quick stats display

#### `GameView`
Main gameplay interface featuring:
- Progressive hint cards (locked/unlocked states)
- Diagnosis input with autocomplete suggestions
- Previous guesses display
- Win/loss result screens
- Score calculation

#### `StatsView`
Comprehensive statistics display:
- Performance grid with key metrics
- Guess distribution bar chart
- Win percentage and streaks

#### `CaseBrowserView`
Browse and filter medical cases:
- Category filter chips
- Search functionality
- Difficulty indicators
- Preview of first hint

#### `AboutView`
App information and instructions:
- How to play guide
- Scoring explanation
- Categories covered
- App version and credits

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent data storage
- **Swift 6**: Latest Swift language features
- **iOS 18+**: Target platform

## Key Features to Extend

### Future Enhancements
1. **More Cases**: Add hundreds of USMLE Step 1 high-yield cases
2. **Image Support**: Include diagnostic images (X-rays, CT scans, lab results)
3. **Explanations**: Post-game educational explanations
4. **Multiplayer**: Compete with friends
5. **Timed Mode**: Speed diagnosis challenges
6. **Spaced Repetition**: Review cases you've missed
7. **Custom Decks**: Create and share case collections
8. **Leaderboards**: Global and friend rankings
9. **Study Mode**: See all hints upfront for learning
10. **Audio Clues**: Heart sounds, breath sounds, etc.

### Content Expansion
- Add 500+ cases covering all Step 1 topics
- Include rare but testable conditions
- Add difficulty tiers (easy, medium, hard)
- Subspecialty categories
- Board-style integrated cases

### UX Improvements
- Haptic feedback on guesses
- Animated hint reveals
- Share results to social media
- Dark mode optimization
- Accessibility features (VoiceOver, Dynamic Type)

## Installation

1. Open the project in Xcode 16+
2. Select an iPhone simulator or device (iOS 18+)
3. Build and run

## Adding New Cases

All playable cases are hard-coded in `CaseLibrary.swift`. The app no longer autogenerates placeholder cases (e.g., those with hints like “Clinical scenario suggests …”). If you want to add or edit cases, do it directly in `CaseLibrary.swift`.

Edit `CaseLibrary.swift` and add cases using this format:

```swift
MedicalCase(
    diagnosis: "Condition Name",
    alternativeNames: ["Alternative", "Abbreviation"],
    hints: [
        "Initial presentation with basic demographics",
        "Key symptoms and history",
        "Physical exam findings",
        "Lab or imaging results",
        "Definitive diagnostic clue"
    ],
    category: "Medical Specialty",
    difficulty: 1-5
)
