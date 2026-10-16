// A stand-in for the GNUstep Foundation overlay.  Under the GNUstep runtime
// a cast makes a Swift error into an NSError by calling Foundation's
// _convertErrorToNSError.

@_exported import GNUstepNSError
@_exported import GNUstepNSString

public func _convertErrorToNSError(_ error: Error) -> NSError {
  if let embedded = error._getEmbeddedNSError() {
    return unsafeDowncast(embedded, to: NSError.self)
  }
  return NSError(domain: error._domain._bridgeToObjectiveCImpl(),
                 code: error._code, userInfo: nil)!
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
