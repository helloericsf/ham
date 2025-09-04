# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Ham - LLM Token Usage Menu Bar Monitor

**Ham** is a macOS menu bar application featuring an animated hamster that runs at different speeds based on LLM API token usage across Anthropic, OpenAI, and Google APIs.

### Project Requirements

#### Core Features
- **Animated Hamster**: Sprite-based hamster wheel animation in menu bar
- **Multi-API Support**: Anthropic Claude, OpenAI, Google AI/Gemini APIs
- **Token Usage Monitoring**: Real-time tracking with API key integration
- **Usage Analytics**: Daily/weekly/monthly summaries and cost calculations
- **Menu Interface**: Click for detailed stats and settings

#### Technical Constraints
- **Platform**: macOS only (menu bar app)
- **Data Storage**: Local-only for privacy
- **Distribution**: Free and open source
- **Performance**: Lightweight, minimal battery impact
- **Authentication**: Direct API key integration for usage monitoring

### Technology Stack

**Language**: Swift (native macOS development)
**UI Framework**: SwiftUI + AppKit for menu bar integration
**Data Storage**: Core Data/UserDefaults (local-only)
**Animation**: Core Animation with sprite frames
**API Integration**: URLSession for HTTP requests
**Security**: Keychain for API key storage

### Architecture Overview

#### Core Components
1. **Menu Bar Manager**: NSStatusItem with animated hamster rendering
2. **API Monitors**: Individual monitors for Anthropic, OpenAI, Google APIs
3. **Usage Calculator**: Token rate calculation and animation speed mapping
4. **Data Layer**: Local storage and secure keychain management
5. **Animation Engine**: Variable-speed sprite-based hamster animation

#### Data Flow
```
API Keys (Keychain) → API Monitors → Usage Calculator → Animation Speed → Menu Bar Display
                                         ↓
                                 Local Storage (History)
```

### Development Commands

**Setup**: `xcodebuild -version` (verify Xcode installation)
**Build**: `xcodebuild -scheme Ham build`
**Test**: `xcodebuild -scheme Ham test`
**Archive**: `xcodebuild -scheme Ham archive`