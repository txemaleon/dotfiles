import Carbon
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: select-input-source <input-source-id>\n", stderr)
    exit(64)
}

let targetID = CommandLine.arguments[1]
let sources = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]

for source in sources {
    guard let rawID = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
        continue
    }

    let sourceID = Unmanaged<CFString>.fromOpaque(rawID).takeUnretainedValue() as String
    guard sourceID == targetID else {
        continue
    }

    let status = TISSelectInputSource(source)
    exit(status == noErr ? 0 : 1)
}

fputs("input source not found: \(targetID)\n", stderr)
exit(2)
