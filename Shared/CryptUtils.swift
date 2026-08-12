//
//  CryptUtils.swift
//  WatchControl
//
//  Created by Damian Mehers on 03.04.23.
//

import Foundation
import CommonCrypto

class CryptUtils {
    
    
    private static func paddedKeyData(for key: String, keyLength: Int) -> Data {
        let keyData = key.data(using: .utf8)!
        let paddedKeyData = NSMutableData(length: keyLength)!
        
        keyData.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) in
            if let baseAddress = keyBytes.baseAddress {
                paddedKeyData.replaceBytes(in: NSRange(location: 0, length: min(keyData.count, keyLength)), withBytes: baseAddress)
            }
        }
        
        return paddedKeyData as Data
    }
    
    
    static func encrypt(data: Data, key: String) -> Data? {
        let keyLength = kCCKeySizeAES128
        let keyData = paddedKeyData(for: key, keyLength: keyLength)

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)

        var numBytesEncrypted: Int = 0
        let cryptStatus = keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
            data.withUnsafeBytes { dataBytes -> CCCryptorStatus in
                buffer.withUnsafeMutableBytes { bufferBytes -> CCCryptorStatus in
                    return CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        keyLength,
                        nil, // Use ECB mode (no Initialization Vector)
                        dataBytes.baseAddress,
                        data.count,
                        bufferBytes.baseAddress,
                        bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }

        if cryptStatus == kCCSuccess {
            buffer.count = numBytesEncrypted
            return buffer
        } else {
            print("Error: Failed to encrypt data")
            return nil
        }
    }
    
    static func decrypt(data: Data, key: String) -> Data? {
        let keyLength = kCCKeySizeAES128
        let keyData = paddedKeyData(for: key, keyLength: keyLength)

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)

        var numBytesDecrypted: Int = 0
        let cryptStatus = keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
            data.withUnsafeBytes { dataBytes -> CCCryptorStatus in
                buffer.withUnsafeMutableBytes { bufferBytes -> CCCryptorStatus in
                    return CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        keyLength,
                        nil, // Use ECB mode (no Initialization Vector)
                        dataBytes.baseAddress,
                        data.count,
                        bufferBytes.baseAddress,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }

        if cryptStatus == kCCSuccess {
            buffer.count = numBytesDecrypted
            return buffer
        } else {
            print("Error: Failed to decrypt data")
            return nil
        }
    }
}
