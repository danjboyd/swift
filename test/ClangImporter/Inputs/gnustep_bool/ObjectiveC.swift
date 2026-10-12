// A minimal stand-in for the ObjectiveC overlay's Boolean bridging.

public struct ObjCBool {
  private var value: Bool

  public init(_ value: Bool) {
    self.value = value
  }

  public var boolValue: Bool {
    return value
  }
}

public func _convertBoolToObjCBool(_ x: Bool) -> ObjCBool {
  return ObjCBool(x)
}

public func _convertObjCBoolToBool(_ x: ObjCBool) -> Bool {
  return x.boolValue
}
