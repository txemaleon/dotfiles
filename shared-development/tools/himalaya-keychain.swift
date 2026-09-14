import Foundation
import Security

func fail(_ status: OSStatus) -> Never {
    // Only the OS status is logged; credential contents never appear in errors.
    FileHandle.standardError.write(Data("Keychain error: \(status)\n".utf8))
    exit(1)
}
guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: himalaya-keychain get|set account\n".utf8))
    exit(2)
}
let action = CommandLine.arguments[1]
let account = CommandLine.arguments[2]
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "himalaya-icloud",
    kSecAttrAccount as String: account,
    kSecAttrSynchronizable as String: false
]
switch action {
case "get":
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(lookup as CFDictionary, &result)
    guard status == errSecSuccess else { fail(status) }
    guard let data = result as? Data, !data.isEmpty else { fail(errSecDecode) }
    FileHandle.standardOutput.write(data)
case "set":
    let data = FileHandle.standardInput.readDataToEndOfFile()
    guard !data.isEmpty, data.count <= 4096 else { fail(errSecParam) }
    var item = query
    item[kSecValueData as String] = data
    var status = SecItemAdd(item as CFDictionary, nil)
    if status == errSecDuplicateItem {
        status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
    }
    guard status == errSecSuccess else { fail(status) }
default:
    exit(2)
}
