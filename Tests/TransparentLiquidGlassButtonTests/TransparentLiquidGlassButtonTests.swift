import AppKit
import Testing
@testable import TransparentLiquidGlassButton

@Test func swapsLeftAndRightChannels() throws {
    let swapped = try AudioChannelSwapper.swappedChannels([1, 2])

    #expect(swapped == [2, 1])
}

@Test func swappingTwiceRestoresOriginalChannels() throws {
    let original: [UInt32] = [7, 9]
    let swapped = try AudioChannelSwapper.swappedChannels(original)
    let restored = try AudioChannelSwapper.swappedChannels(swapped)

    #expect(restored == original)
}

@Test func rejectsUnexpectedChannelCount() {
    do {
        _ = try AudioChannelSwapper.swappedChannels([1])
        Issue.record("单声道数据应该被拒绝")
    } catch {
        #expect(error == .invalidChannelCount(1))
    }
}

@Test func smallPointerMovementRemainsAClick() {
    let start = NSPoint(x: 100, y: 100)

    #expect(!DraggableGlassButton.shouldStartDragging(
        from: start,
        to: NSPoint(x: 101, y: 100)
    ))
    #expect(!DraggableGlassButton.shouldStartDragging(
        from: start,
        to: NSPoint(x: 104, y: 100)
    ))
}

@Test func movementBeyondThresholdStartsDragging() {
    let start = NSPoint(x: 100, y: 100)

    #expect(DraggableGlassButton.shouldStartDragging(
        from: start,
        to: NSPoint(x: 105, y: 100)
    ))
    #expect(DraggableGlassButton.shouldStartDragging(
        from: start,
        to: NSPoint(x: 103, y: 103)
    ))
}
