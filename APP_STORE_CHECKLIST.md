# App Store Submission Checklist

## Pre-Submission

### Code Quality
- [ ] Version number updated in Info.plist
- [ ] Build number incremented
- [ ] All TODO/FIXME comments resolved
- [ ] No DEBUG-only code in release builds
- [ ] SwiftLint passes with zero errors
- [ ] All unit tests passing
- [ ] No compiler warnings

### Testing
- [ ] UI tested on Apple TV 4K simulator
- [ ] VoiceOver accessibility verified
- [ ] Focus navigation works correctly
- [ ] All media types play correctly
- [ ] Error states display properly
- [ ] Offline behavior tested

### App Store Connect
- [ ] App description updated
- [ ] "What's New" text prepared
- [ ] Screenshots updated (1920x1080 for tvOS)
- [ ] App preview video (optional)
- [ ] Keywords updated
- [ ] Support URL active
- [ ] Privacy Policy URL active

### Technical Requirements
- [ ] API credentials configured
- [ ] No HTTP traffic (HTTPS only)
- [ ] App Transport Security properly configured
- [ ] Crash-free startup verified
- [ ] Memory usage acceptable (<200MB typical for tvOS apps; validate with Instruments)

### Legal
- [ ] Copyright notices current
- [ ] Third-party licenses attributed
- [ ] Internet Archive API usage compliant

## Post-Submission
- [ ] TestFlight build tested
- [ ] App Review notes prepared
- [ ] Demo account credentials ready (if needed)
- [ ] Contact information current
