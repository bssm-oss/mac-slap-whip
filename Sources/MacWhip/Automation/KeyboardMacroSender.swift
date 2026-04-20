import ApplicationServices
import AppKit
import Carbon.HIToolbox
import Foundation

@MainActor
protocol KeyboardMacroSending {
    func sendControlC() async throws
    func sendText(_ text: String) async throws
    func sendReturn() async throws
}

enum KeyboardMacroError: LocalizedError {
    case failedToCreateEvent

    var errorDescription: String? {
        switch self {
        case .failedToCreateEvent: "키보드 이벤트를 생성하지 못했습니다."
        }
    }
}

@MainActor
struct KeyboardMacroSender: KeyboardMacroSending {
    func sendControlC() async throws {
        try postModifiedKey(.init(kVK_ANSI_C), modifiers: [.maskControl])
    }

    func sendText(_ text: String) async throws {
        guard !text.isEmpty else { return }
        try pasteText(text)
    }

    func sendReturn() async throws {
        try postKey(.init(kVK_Return), keyDown: true)
        try postKey(.init(kVK_Return), keyDown: false)
    }

    private func postKey(_ keyCode: CGKeyCode, keyDown: Bool) throws {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else {
            throw KeyboardMacroError.failedToCreateEvent
        }

        event.post(tap: .cghidEventTap)
    }

    private func postModifiedKey(_ keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        guard let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        else {
            throw KeyboardMacroError.failedToCreateEvent
        }

        downEvent.flags = modifiers
        upEvent.flags = modifiers
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }

    private func pasteText(_ text: String) throws {
        let pasteboard = NSPasteboard.general
        let previousItems = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { partialResult, type in
                if let data = item.data(forType: type) {
                    partialResult[type] = data
                }
            }
        } ?? []

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        defer {
            pasteboard.clearContents()
            for itemData in previousItems {
                let item = NSPasteboardItem()
                for (type, data) in itemData {
                    item.setData(data, forType: type)
                }
                pasteboard.writeObjects([item])
            }
        }

        try postModifiedKey(.init(kVK_ANSI_V), modifiers: [.maskCommand])
    }
}
