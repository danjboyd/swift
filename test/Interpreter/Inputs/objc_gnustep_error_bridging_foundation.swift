// A stand-in for the GNUstep Foundation overlay.  Under the GNUstep runtime
// a cast makes a Swift error into an NSError by calling Foundation's
// _convertErrorToNSError, and an NSError into a Swift error type by calling
// _convertNSErrorToError and _bridgeNSErrorToError.

@_exported import GNUstepNSError
@_exported import GNUstepNSString

public func _convertErrorToNSError(_ error: Error) -> NSError {
  if let embedded = error._getEmbeddedNSError() {
    return unsafeDowncast(embedded, to: NSError.self)
  }
  return _SwiftNativeNSError(error)
}

/// The Swift error ERROR stands for, else ERROR itself.
public func _convertNSErrorToError(_ error: NSError?) -> Error {
  if let native = error as? _SwiftNativeNSError {
    return native.swiftError
  }
  return error!
}

/// The NSError that stands for a Swift error.
final class _SwiftNativeNSError: NSError {
  let swiftError: Error

  init(_ error: Error) {
    swiftError = error
    super.init(domain: error._domain._bridgeToObjectiveCImpl(),
               code: error._code, userInfo: nil)
  }
}

extension NSError: Error {
  public var _domain: String {
    return String(cString: (domain() as! NSString).utf8String())
  }

  public var _code: Int {
    return code()
  }

  public func _getEmbeddedNSError() -> AnyObject? {
    return self
  }
}

/// An error type a cast can make from an arbitrary NSError.
public protocol _ObjectiveCBridgeableError: Error {
  init?(_bridgedNSError: __shared NSError)
}

public func _bridgeNSErrorToError<T: _ObjectiveCBridgeableError>(
    _ error: NSError, out: UnsafeMutablePointer<T>) -> Bool {
  guard let bridged = T(_bridgedNSError: error) else {
    return false
  }
  out.initialize(to: bridged)
  return true
}

/// An error that stores an NSError, which the compiler puts into an Error
/// as the NSError itself.
public protocol _BridgedStoredNSError: _ObjectiveCBridgeableError {
  static var errorDomain: String { get }
  var _nsError: NSError { get }
  init(_nsError error: NSError)
}

extension _BridgedStoredNSError {
  public init?(_bridgedNSError error: NSError) {
    guard error._domain == Self.errorDomain else {
      return nil
    }
    self.init(_nsError: error)
  }

  public func _getEmbeddedNSError() -> AnyObject? {
    return _nsError
  }
}

/// The user info of an error by default: here, the name of its type.
public func _getErrorDefaultUserInfo<T: Error>(_ error: T) -> AnyObject? {
  return _typeName(T.self)._bridgeToObjectiveCImpl()
}
