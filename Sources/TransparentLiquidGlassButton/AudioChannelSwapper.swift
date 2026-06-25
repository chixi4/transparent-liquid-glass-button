import CoreAudio

class AudioChannelSwapper {
    
    static func swap() -> Bool {
        // 1. Get default output device
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress, 0, nil, &size, &deviceID
        )
        guard status == noErr else {
            print("❌ AudioChannelSwapper: can't get default output device (\(status))")
            return false
        }
        
        // 2. Read current stereo channels
        var channelsAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var channels: [UInt32] = [0, 0]
        var dataSize = UInt32(MemoryLayout<UInt32>.size * 2)
        
        let readStatus = AudioObjectGetPropertyData(
            deviceID, &channelsAddr, 0, nil, &dataSize, &channels
        )
        guard readStatus == noErr else {
            print("❌ AudioChannelSwapper: can't read stereo channels (\(readStatus))")
            return false
        }
        
        // 3. Swap
        let swapped = [channels[1], channels[0]]
        var swappedSize = UInt32(MemoryLayout<UInt32>.size * 2)
        
        let writeStatus = AudioObjectSetPropertyData(
            deviceID, &channelsAddr, 0, nil, swappedSize, swapped
        )
        
        if writeStatus == noErr {
            print("🔊 AudioChannelSwapper: [\(channels[0]), \(channels[1])] → [\(swapped[0]), \(swapped[1])]")
            return true
        } else {
            print("❌ AudioChannelSwapper: can't set stereo channels (\(writeStatus))")
            return false
        }
    }
}
