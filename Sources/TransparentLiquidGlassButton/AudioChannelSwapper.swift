import CoreAudio
import Foundation

struct AudioChannelSwapResult: Equatable, Sendable {
    let before: [UInt32]
    let after: [UInt32]
}

enum AudioChannelSwapError: Error, Equatable, LocalizedError, Sendable {
    case cannotGetDefaultOutputDevice(OSStatus)
    case defaultOutputDeviceUnavailable
    case stereoPropertyUnavailable(AudioDeviceID)
    case cannotCheckStereoProperty(AudioDeviceID, OSStatus)
    case stereoPropertyNotSettable(AudioDeviceID)
    case cannotGetStereoPropertySize(AudioDeviceID, OSStatus)
    case unexpectedStereoPropertySize(expected: UInt32, actual: UInt32)
    case cannotReadStereoChannels(AudioDeviceID, OSStatus)
    case invalidChannelCount(Int)
    case cannotWriteStereoChannels(AudioDeviceID, OSStatus)
    case verificationMismatch(expected: [UInt32], actual: [UInt32])

    var errorDescription: String? {
        switch self {
        case .cannotGetDefaultOutputDevice(let status):
            "无法取得默认输出设备：\(Self.statusText(status))"
        case .defaultOutputDeviceUnavailable:
            "系统当前没有可用的默认输出设备"
        case .stereoPropertyUnavailable(let deviceID):
            "输出设备 \(deviceID) 不提供立体声通道映射属性"
        case .cannotCheckStereoProperty(let deviceID, let status):
            "无法检查输出设备 \(deviceID) 的通道映射是否可写：\(Self.statusText(status))"
        case .stereoPropertyNotSettable(let deviceID):
            "输出设备 \(deviceID) 不允许修改立体声通道映射"
        case .cannotGetStereoPropertySize(let deviceID, let status):
            "无法读取输出设备 \(deviceID) 的通道映射长度：\(Self.statusText(status))"
        case .unexpectedStereoPropertySize(let expected, let actual):
            "立体声通道映射长度异常：预期 \(expected) 字节，实际 \(actual) 字节"
        case .cannotReadStereoChannels(let deviceID, let status):
            "无法读取输出设备 \(deviceID) 的立体声通道：\(Self.statusText(status))"
        case .invalidChannelCount(let count):
            "立体声通道数量必须是 2，实际为 \(count)"
        case .cannotWriteStereoChannels(let deviceID, let status):
            "无法写入输出设备 \(deviceID) 的立体声通道：\(Self.statusText(status))"
        case .verificationMismatch(let expected, let actual):
            "通道映射写入后校验失败：预期 \(expected)，实际 \(actual)"
        }
    }

    private static func statusText(_ status: OSStatus) -> String {
        let value = UInt32(bitPattern: status)
        let bytes = [
            UInt8((value >> 24) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8(value & 0xff),
        ]

        guard bytes.allSatisfy({ (0x20...0x7e).contains($0) }) else {
            return String(status)
        }

        return "\(status) ('\(String(decoding: bytes, as: UTF8.self))')"
    }
}

final class AudioChannelSwapper {
    private static let stereoChannelCount = 2
    private static let stereoDataSize = UInt32(
        MemoryLayout<UInt32>.size * stereoChannelCount
    )

    static func swap() -> Result<AudioChannelSwapResult, AudioChannelSwapError> {
        do {
            return .success(try performSwap())
        } catch {
            return .failure(error)
        }
    }

    static func swappedChannels(
        _ channels: [UInt32]
    ) throws(AudioChannelSwapError) -> [UInt32] {
        guard channels.count == stereoChannelCount else {
            throw .invalidChannelCount(channels.count)
        }

        return [channels[1], channels[0]]
    }

    private static func performSwap() throws(AudioChannelSwapError) -> AudioChannelSwapResult {
        let deviceID = try defaultOutputDevice()
        var channelsAddress = stereoPropertyAddress()

        guard AudioObjectHasProperty(deviceID, &channelsAddress) else {
            throw .stereoPropertyUnavailable(deviceID)
        }

        var isSettable: DarwinBoolean = false
        let settableStatus = AudioObjectIsPropertySettable(
            deviceID,
            &channelsAddress,
            &isSettable
        )
        guard settableStatus == noErr else {
            throw .cannotCheckStereoProperty(deviceID, settableStatus)
        }
        guard isSettable.boolValue else {
            throw .stereoPropertyNotSettable(deviceID)
        }

        let channels = try readStereoChannels(deviceID, address: &channelsAddress)
        let swapped = try swappedChannels(channels)
        let writeStatus = swapped.withUnsafeBytes { buffer in
            AudioObjectSetPropertyData(
                deviceID,
                &channelsAddress,
                0,
                nil,
                stereoDataSize,
                buffer.baseAddress!
            )
        }
        guard writeStatus == noErr else {
            throw .cannotWriteStereoChannels(deviceID, writeStatus)
        }

        let verified = try readStereoChannels(deviceID, address: &channelsAddress)
        guard verified == swapped else {
            throw .verificationMismatch(expected: swapped, actual: verified)
        }

        return AudioChannelSwapResult(before: channels, after: verified)
    }

    private static func defaultOutputDevice() throws(AudioChannelSwapError) -> AudioDeviceID {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        guard status == noErr else {
            throw .cannotGetDefaultOutputDevice(status)
        }
        guard deviceID != kAudioObjectUnknown else {
            throw .defaultOutputDeviceUnavailable
        }

        return deviceID
    }

    private static func readStereoChannels(
        _ deviceID: AudioDeviceID,
        address: inout AudioObjectPropertyAddress
    ) throws(AudioChannelSwapError) -> [UInt32] {
        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )
        guard sizeStatus == noErr else {
            throw .cannotGetStereoPropertySize(deviceID, sizeStatus)
        }
        guard dataSize == stereoDataSize else {
            throw .unexpectedStereoPropertySize(expected: stereoDataSize, actual: dataSize)
        }

        var channels = [UInt32](repeating: 0, count: stereoChannelCount)
        let readStatus = channels.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &dataSize,
                buffer.baseAddress!
            )
        }
        guard readStatus == noErr else {
            throw .cannotReadStereoChannels(deviceID, readStatus)
        }
        guard dataSize == stereoDataSize else {
            throw .unexpectedStereoPropertySize(expected: stereoDataSize, actual: dataSize)
        }

        return channels
    }

    private static func stereoPropertyAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}
