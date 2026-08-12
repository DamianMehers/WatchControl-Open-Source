import Foundation
import os

class KeyStore {
    
    let group = "TBS.com.atadore.WatchRemote"
    
    static let shared = KeyStore();
    
    private init() {}
    
    func store(macInfo: MacInfo) {
        let data = try! JSONEncoder().encode(macInfo)
        let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword as String,
                                       kSecAttrAccount as String: macInfo.name,
                                       kSecValueData as String: data,
                                       kSecAttrSynchronizable as String : kCFBooleanTrue!,
                                       kSecAttrAccessGroup as String : group
        ]
        SecItemDelete(addquery as CFDictionary)
        let status : OSStatus = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else {
            os_log("store: whoops: \(status)")
            return
        }
    }
    
    func clear(name: String) async {
        await withCheckedContinuation { continuation in
            let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword as String,
                                           kSecAttrAccount as String: name,
                                           kSecAttrSynchronizable as String : kCFBooleanTrue!,
                                           kSecAttrAccessGroup as String : group
            ]
            SecItemDelete(addquery as CFDictionary)
            continuation.resume()
        }
    }
    
    func retrieve() async -> [MacInfo] {
        await withCheckedContinuation { continuation in
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecReturnAttributes as String: true,
                                        kSecReturnData as String: true,
                                        kSecMatchLimit as String : kSecMatchLimitAll,
                                        kSecAttrSynchronizable as String : kCFBooleanTrue!,
                                        kSecAttrAccessGroup as String : group
            ]
            
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            var returnValue = [MacInfo]()
            guard status == errSecSuccess, let items = result as? [[String: Any]] else {
                continuation.resume(returning: returnValue)
                Log.d("Keychain SecItemCopyMatching status: \(status), result nil: \(result == nil)")
                return
            }
            
            let decoder = JSONDecoder()
            
            for item in items {
                guard let passwordData = item[kSecValueData as String] as? Data,
                      let macInfo = try? decoder.decode(MacInfo.self, from: passwordData) else {
                    continue
                }
                returnValue.append(macInfo)
            }
            
            continuation.resume(returning: returnValue)
        }
    }
    
}
