# 🚗 MileTracker

**Professional iOS Mileage Tracking App with Automatic Trip Detection**

A sophisticated iOS application built with Swift and SwiftUI that automatically detects and tracks your driving trips using Core Location and Core Motion, similar to commercial apps like MileIQ.

## ✨ Features

### 🎯 **Automatic Trip Detection**
- **Smart Start**: Automatically begins tracking when speed > 5 mph for > 15 seconds
- **Intelligent Stop**: Automatically ends trips after 2 minutes of no movement
- **Core Motion Integration**: Uses device motion sensors for accurate automotive activity detection
- **Background Processing**: Continues tracking even when the app is in the background

### 📱 **Professional UI/UX**
- **SwiftUI Interface**: Modern, responsive design following Apple's Human Interface Guidelines
- **Real-time Updates**: Live distance tracking and trip status updates
- **Intuitive Controls**: Simple start/stop buttons with clear visual feedback
- **Status Indicators**: Clear display of tracking state, permissions, and system health

### 🧪 **Comprehensive Testing System**
- **Test Case Management**: Professional-grade testing framework for systematic validation
- **Automated Logging**: Complete debug logs with timestamps and GPS accuracy data
- **Export Functionality**: Generate detailed reports for analysis and debugging
- **Mock Mode**: Simulated trips for testing without physical movement (DEBUG builds only)

### 🔧 **Advanced Technical Features**
- **Core Location Integration**: High-accuracy GPS tracking with configurable settings
- **Core Motion Detection**: Automotive activity recognition using device sensors
- **Background Location Updates**: Continuous tracking during app backgrounding
- **Error Handling**: Comprehensive error management and user feedback
- **Performance Optimization**: Efficient location processing and memory management

## 🚀 Getting Started

### Prerequisites
- **iOS 15.0+** (targets modern iOS features)
- **Xcode 14.0+** (for development and building)
- **iPhone with GPS** (for location tracking)
- **Location Permissions** (Always or When In Use)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/knportal/MileTracker.git
   cd MileTracker
   ```

2. **Open in Xcode**
   ```bash
   open MileTracker.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### First Run Setup

1. **Launch the app** on your device
2. **Grant Location Permissions** when prompted
3. **Choose "Always"** for background tracking capability
4. **Start your first trip** by getting in your car and driving

## 📱 How to Use

### 🚗 **Automatic Trip Detection (Recommended)**
1. **Get in your car** - no need to touch the app
2. **Start driving** - app automatically detects automotive activity
3. **Trip begins** after 15 seconds of driving above 5 mph
4. **Continue driving** - distance updates in real-time
5. **Park and exit** - trip automatically ends after 2 minutes of no movement

### 🎮 **Manual Trip Control**
- **Start Trip**: Manually begin tracking
- **Stop Trip**: Manually end current trip
- **Reset Trip**: Clear current trip data

### 🧪 **Test Case Management**
- **Start Test Case**: Begin recording a specific test scenario
- **Add Notes**: Document test conditions and observations
- **End Test Case**: Save complete test data
- **Export Reports**: Generate detailed test case reports

## 🏗️ Architecture

### **Core Components**
- **`LocationManager`**: Handles GPS tracking, motion detection, and trip logic
- **`ContentView`**: Main SwiftUI interface and user controls
- **`TestCase`**: Structured data model for test case management
- **Core Location Integration**: GPS accuracy and background processing
- **Core Motion Integration**: Automotive activity detection

### **Key Design Patterns**
- **MVVM Architecture**: Clean separation of concerns
- **Combine Framework**: Reactive programming for UI updates
- **Protocol-Oriented Design**: Flexible and testable code structure
- **Property Wrappers**: SwiftUI state management best practices

## 🔧 Development

### **Project Structure**
```
MileTracker/
├── MileTracker/
│   ├── LocationManager.swift      # Core location and motion logic
│   ├── ContentView.swift          # Main UI interface
│   ├── MileTrackerApp.swift       # App entry point
│   └── Assets.xcassets/          # App icons and colors
├── MileTrackerTests/              # Unit tests
├── MileTrackerUITests/            # UI tests
└── .cursor/rules/                 # Development rules and guidelines
```

### **Key Technologies**
- **Swift 5.9+**: Modern Swift language features
- **SwiftUI**: Declarative UI framework
- **Core Location**: GPS and location services
- **Core Motion**: Device motion and activity detection
- **Combine**: Asynchronous event handling

### **Build Configuration**
- **Deployment Target**: iOS 15.0+
- **Swift Version**: 5.9
- **Architectures**: arm64 (iPhone), x86_64 (Simulator)

## 🧪 Testing

### **Test Case Framework**
The app includes a comprehensive testing system for systematic validation:

1. **Create Test Cases**: Name and document specific test scenarios
2. **Record Data**: Automatically capture GPS, motion, and trip data
3. **Export Reports**: Generate detailed test case reports
4. **Analyze Results**: Review performance and identify issues

### **Mock Mode (DEBUG Only)**
- **Simulated Trips**: Test without physical movement
- **Predefined Routes**: Built-in test scenarios
- **Manual Controls**: Add mock locations and simulate motion

### **Debug Features**
- **Real-time Logging**: Comprehensive system activity logs
- **Status Monitoring**: System health and performance metrics
- **Export Functionality**: Share debug reports for analysis

## 📊 Performance

### **Location Accuracy**
- **GPS Accuracy**: 2-16 meters (typical)
- **Update Frequency**: Configurable distance and time filters
- **Background Efficiency**: Optimized for battery life

### **Trip Detection**
- **Start Detection**: 15 seconds after speed threshold
- **Stop Detection**: 2 minutes after last movement
- **False Positive Reduction**: Motion sensor validation

## 🔒 Privacy & Security

### **Data Handling**
- **Local Storage**: All data stored locally on device
- **No Cloud Sync**: Privacy-focused design
- **Optional Export**: User controls data sharing

### **Permissions**
- **Location Access**: Required for trip tracking
- **Motion Detection**: Required for automotive activity recognition
- **Background Processing**: Required for continuous tracking

## 🚨 Troubleshooting

### **Common Issues**

#### **Location Not Working**
- Check location permissions in Settings
- Ensure location services are enabled
- Verify GPS signal strength

#### **Trips Not Starting Automatically**
- Check motion detection permissions
- Ensure device is not in low power mode
- Verify automotive activity is detected

#### **Background Tracking Issues**
- Grant "Always" location permission
- Check background app refresh settings
- Ensure app is not force-closed

### **Debug Tools**
- **Status Display**: Real-time system status
- **Debug Logs**: Detailed activity logs
- **Health Check**: System diagnostics
- **Export Reports**: Comprehensive debugging data

## 🤝 Contributing

### **Development Guidelines**
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Implement proper error handling
- Add comprehensive logging
- Test on real devices

### **Code Quality**
- **SwiftLint**: Follow Swift style guidelines
- **Documentation**: Comment complex logic
- **Testing**: Include unit and UI tests
- **Performance**: Optimize for battery life

## 📄 License

This project is developed for educational and personal use. Please respect Apple's developer guidelines and terms of service.

## 🙏 Acknowledgments

- **Apple**: Core Location and Core Motion frameworks
- **SwiftUI**: Modern iOS development framework
- **iOS Community**: Best practices and development patterns

## 📞 Support

For questions, issues, or contributions:
- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check this README and inline code comments
- **Testing**: Use the built-in test case management system

---

**Built with ❤️ using Swift and SwiftUI**

*MileTracker - Professional mileage tracking for iOS*

