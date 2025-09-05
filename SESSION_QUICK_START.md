# 🚀 Ham Development Session Quick Start Guide

This guide helps developers quickly orient and start working on Ham enhancement chunks in new sessions.

## ⚡ 30-Second Status Check

**Current Status**: Chunk 1 ✅ COMPLETE | Chunk 2 🎯 READY TO START
**Last Updated**: September 4, 2024
**Active Branch**: `main` (or current feature branch)

## 🎯 What's Next: Chunk 2 - Cost Calculations

**Objective**: Add real-time cost tracking to the enhanced menu system
**Priority**: High (Score: 20)
**Timeline**: 1 week
**Complexity**: Low-Medium

### Quick Implementation Overview
```
Goal: Transform this...
🐹 Today: 1,247 tokens 📈 (+12%)

Into this...
🐹 Today: 1,247 tokens • $2.34 📈 (+12%)
```

## 🏁 Quick Start Commands

```bash
# Navigate to project
cd "Claude Code 09:25"

# Verify current state
swift build                    # Should build successfully
ls Sources/Ham/                # Should see UsageAnalytics.swift from Chunk 1

# Test current functionality  
./test_launch.sh              # Should show enhanced menu

# Ready to start Chunk 2!
```

## 📋 Implementation Checklist for Chunk 2

### Phase 1: Core Cost Engine (30 min)
- [ ] Create `Sources/Ham/CostCalculator.swift`
- [ ] Create `Sources/Ham/PricingData.swift` with current API pricing
- [ ] Add cost calculation methods for each provider

### Phase 2: Analytics Integration (45 min)
- [ ] Extend `UsageAnalytics` struct to include cost fields
- [ ] Update analytics engine to calculate cost trends
- [ ] Modify data persistence to store cost history

### Phase 3: Menu Integration (30 min)  
- [ ] Update menu display to show costs alongside tokens
- [ ] Enhance provider breakdown with cost information
- [ ] Add cost metrics to activity submenu

### Phase 4: Testing (15 min)
- [ ] Verify cost calculations are accurate
- [ ] Test menu display with cost information
- [ ] Ensure no regressions in existing functionality

## 🛠️ Key Files to Work With

### Files to Create
- `Sources/Ham/CostCalculator.swift` - Core cost calculation engine
- `Sources/Ham/PricingData.swift` - API model pricing database

### Files to Modify  
- `Sources/Ham/UsageAnalytics.swift` - Add cost fields and calculations
- `Sources/Ham/MenuBarManager.swift` - Integrate cost display
- `Sources/Ham/APIMonitor.swift` - Pass model info for cost calculation

### Files to Reference
- `CHUNK_IMPLEMENTATION_PROGRESS.md` - Detailed implementation plan
- `docs/ENHANCEMENT_ROADMAP.md` - Overall project roadmap
- `TEST_ENHANCED_MENU.md` - Testing procedures

## 📊 Current API Pricing (as of Sept 2024)

### Anthropic Claude
- Claude 3.5 Sonnet: $3.00/$15.00 per 1K tokens (input/output)
- Claude 3 Haiku: $0.25/$1.25 per 1K tokens

### OpenAI  
- GPT-4 Turbo: $10.00/$30.00 per 1K tokens
- GPT-3.5 Turbo: $1.50/$2.00 per 1K tokens

### Google AI
- Gemini Pro: $0.50/$1.50 per 1K tokens  
- Gemini Flash: $0.075/$0.30 per 1K tokens

## 🧪 Testing Strategy

### Quick Test
```bash
# Launch Ham with cost calculations
swift build && cp .build/arm64-apple-macosx/debug/Ham Ham.app/Contents/MacOS/Ham
./Ham.app/Contents/MacOS/Ham &

# Verify enhanced menu shows costs
# Click Ham menu bar → Should see "X tokens • $Y.ZZ" format
```

### Success Criteria
- [ ] Menu shows token counts WITH cost information
- [ ] Provider breakdown includes cost percentages
- [ ] Cost trends display properly (📈/📉 for cost changes)
- [ ] Historical cost data persists between sessions
- [ ] No performance regressions

## ⚠️ Common Gotchas

1. **Decimal Precision**: Use `Decimal` type for currency, not `Double`
2. **Model Detection**: Different models have different pricing
3. **Token Direction**: Input vs output tokens have different costs
4. **Currency Formatting**: Use proper currency display ($X.XX)
5. **Zero Costs**: Handle gracefully when no usage/costs

## 🎯 Expected Session Outcome

By end of session, users should see:
```
Enhanced Menu with Costs:
🐹 Today: 1,247 tokens • $2.34 📈 (+12% usage, +8% cost)
📊 This Week: 8,923 tokens • $15.67 📉 (-3% usage, -1% cost)  
📅 This Month: 24,567 tokens • $45.23 ━ (0% usage, +2% cost)

▶ By Provider
  🤖 Anthropic: 45% usage • 52% cost ($1.22)
  🔥 OpenAI: 35% usage • 38% cost ($0.89)
  🔍 Google AI: 20% usage • 10% cost ($0.23)
```

## 🚀 Next Session Prep

After Chunk 2 completion:
- Update `CHUNK_IMPLEMENTATION_PROGRESS.md` with results
- Test thoroughly and document any issues
- Prepare for Chunk 3 (OpenAI API Integration) or Chunk 4 (Sprites)

## 📞 Quick Reference

- **Current codebase**: Enhanced menu with analytics (Chunk 1 complete)
- **Architecture**: SwiftUI + AppKit, local data storage, 90-day retention
- **Performance**: <50MB memory, <2% CPU, <100ms menu response
- **Testing**: Manual verification via menu bar interaction

**Ready to build cost tracking into Ham! 🎯💰**