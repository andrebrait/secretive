import Foundation
import CryptoKit
import OSLog
import SecretKit
import AppKit
import SSHProtocolKit

public actor ProxiedAgent: Sendable {

    /// The active SocketPort. Must be retained to be kept valid.
    private let port: SocketPort

    /// The FileHandle for the main socket.
    private let fileHandle: FileHandle

    public init() {
        let path = "/var/run/com.apple.launchd.0ucqoa5x1y/Listeners"

        port = SocketPort(path: path)
        fileHandle = FileHandle(fileDescriptor: port.socket, closeOnDealloc: true)

    }

    public func test() {
        let requestID = SSHAgent.Request.requestIdentities
        let request = requestID.data.lengthAndData
        try! fileHandle.write(contentsOf: request)
    }

}

extension SSHAgent.Request {

    var data: Data {
        var raw = self.protocolID
        return unsafe Data(bytes: &raw, count: MemoryLayout<UInt8>.size)
    }

}

private extension SocketPort {

    convenience init(path: String) {
        var addr = sockaddr_un()

        let length = unsafe withUnsafeMutablePointer(to: &addr.sun_path.0) { pointer in
            unsafe path.withCString { cstring in
                let len = unsafe strlen(cstring)
                unsafe strncpy(pointer, cstring, len)
                return len
            }
        }
        // This doesn't seem to be _strictly_ neccessary with SocketPort.
        // but just for good form.
        addr.sun_family = sa_family_t(AF_UNIX)
        // This mirrors the SUN_LEN macro format.
        addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size - MemoryLayout.size(ofValue: addr.sun_path) + length)

        let data = unsafe Data(bytes: &addr, count: MemoryLayout<sockaddr_un>.size)
        self.init(remoteWithProtocolFamily: AF_UNIX, socketType: SOCK_STREAM, protocol: 0, address: data)
    }

}
