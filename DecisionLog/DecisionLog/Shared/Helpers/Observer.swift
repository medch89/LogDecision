import Foundation

public typealias Observer<T> = (T) -> Void
public typealias ActionHandler<Action> = (Action) -> Void
