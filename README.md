# 🐹 Ham - LLM Token Usage Menu Bar Monitor

A delightful macOS menu bar application featuring an animated hamster that runs at different speeds based on your LLM API token usage across Anthropic Claude, OpenAI, and Google AI.

Inspired by [RunCat](https://kyome.io/runcat/index.html), Ham brings the same playful system monitoring concept to LLM API usage tracking.

## ✨ Features

- **🎯 Multi-API Support**: Monitor token usage from Anthropic Claude, OpenAI, and Google AI APIs
- **🐹 Animated Hamster**: Speed varies based on your API token consumption rate
- **🔐 Secure Storage**: API keys stored securely in macOS Keychain
- **📊 Usage Analytics**: Daily/weekly/monthly usage summaries and cost tracking
- **⚡ Lightweight**: Minimal battery impact with efficient monitoring
- **🎨 Native macOS**: Built with Swift and SwiftUI for optimal performance

## 🚀 Installation

### Prerequisites
- macOS 13.0 or later
- Xcode Command Line Tools or Swift toolchain

### Build from Source

```bash
# Clone the repository
git clone https://github.com/helloericsf/ham.git
cd ham

# Build the project
swift build

# Run Ham
swift run Ham
```

## 🎮 Usage

1. **Launch Ham**: The hamster appears in your menu bar
2. **Add API Keys**: Click the hamster → Settings to add your API keys
3. **Monitor Usage**: Watch the hamster run faster as you use more tokens
4. **View Details**: Click the menu bar item to see detailed usage statistics

### Setting Up API Keys

Ham needs your API keys to monitor token usage:

#### Anthropic Claude
1. Go to [Anthropic Console](https://console.anthropic.com)
2. Create an API key
3. Add it to Ham settings

#### OpenAI
1. Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Create a new secret key
3. Add it to Ham settings

#### Google AI
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Add it to Ham settings

## 🛠️ Development

### Project Structure

```
Ham/
├── Sources/Ham/
│   ├── main.swift              # App entry point
│   ├── MenuBarManager.swift    # Menu bar integration
│   ├── HamsterAnimator.swift   # Animation system
│   ├── UsageMonitor.swift      # Token usage tracking
│   ├── APIMonitor.swift        # API service monitors
│   ├── KeychainManager.swift   # Secure key storage
│   └── SettingsWindow.swift    # Settings UI
├── Package.swift               # Swift Package Manager
└── README.md
```

### Architecture

Ham follows a clean, modular architecture:

- **MenuBarManager**: Coordinates menu bar presence and user interactions
- **HamsterAnimator**: Handles sprite animation with variable speed
- **UsageMonitor**: Aggregates token usage from multiple API providers
- **API Monitors**: Individual monitors for each LLM service
- **KeychainManager**: Secure storage for API credentials

### Adding New API Providers

1. Create a new monitor class implementing `APIMonitor`
2. Add the provider to `APIProvider` enum
3. Register it in `UsageMonitor.setupAPIMonitors()`

```swift
final class NewAPIMonitor: APIMonitor, @unchecked Sendable {
    func getCurrentUsage() async throws -> Int {
        // Implement API usage fetching
    }
    
    func hasValidAPIKey() -> Bool {
        // Check for valid API key
    }
}
```

## 🎨 Customization

### Animation Speed Mapping

The hamster's running speed is calculated based on tokens per minute:

```swift
let speed = min(max(tokensPerMinute / 1000.0, 0.1), 3.0)
```

Adjust the divisor (1000.0) to make the hamster more or less sensitive to usage changes.

### Monitoring Frequency

Usage is checked every 30 seconds by default. Modify in `UsageMonitor.startMonitoring()`:

```swift
Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true)
```

## 🔒 Privacy & Security

- **Local Only**: All data stored locally on your Mac
- **Secure Storage**: API keys encrypted in macOS Keychain
- **No Telemetry**: Zero data collection or external reporting
- **Open Source**: Full transparency in code and data handling

## 🐛 Troubleshooting

### Ham doesn't appear in menu bar
- Check Console.app for error messages
- Ensure macOS 13.0 or later
- Try restarting Ham

### API usage not updating
- Verify API keys in Settings
- Check network connectivity
- Some APIs may have rate limits or delayed reporting

### High CPU usage
- Reduce monitoring frequency
- Check for API endpoint issues
- Monitor system resources with Activity Monitor

## 📈 Roadmap

- [ ] Real hamster sprite animations (replacing emoji)
- [ ] Actual API usage endpoint implementations
- [ ] Cost tracking and budget alerts
- [ ] Historical usage charts
- [ ] Custom animation themes
- [ ] Menu bar usage statistics
- [ ] Export usage data

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [RunCat](https://kyome.io/runcat/index.html) by Kyome
- Built with Swift and love for the developer community
- Thanks to the LLM providers for their APIs

## 🛠️ Development

### Enhancement Progress
Ham is actively being enhanced with new features. Check the development documentation:

- **[Chunk Implementation Progress](CHUNK_IMPLEMENTATION_PROGRESS.md)** - Current development status and roadmap
- **[Session Quick Start](SESSION_QUICK_START.md)** - Quick start guide for new development sessions
- **[Enhancement Roadmap](ENHANCEMENT_ROADMAP.md)** - Complete feature roadmap and implementation plans

### Current Status
- ✅ **Chunk 1 Complete**: Enhanced Menu Statistics with rich analytics
- 🚀 **Chunk 2 Ready**: Cost Calculations and budget tracking
- 📊 **Active Features**: Real-time usage trends, provider breakdowns, activity metrics

### Architecture
- **Enhanced Analytics**: 90-day usage history with trend analysis
- **Rich Menu System**: Professional menu bar interface with submenus
- **Extensible Framework**: Ready for cost tracking and advanced features

## 📬 Contact

- GitHub Issues: [Report bugs or request features](https://github.com/helloericsf/ham/issues)
- GitHub Discussions: [Community support and ideas](https://github.com/helloericsf/ham/discussions)

---

**Made with 🐹 for developers who love delightful tools**