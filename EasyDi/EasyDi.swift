//
//  EasyDi.swift
//
//  Created by Andrey Zarembo.
//
import Foundation

public typealias InjectableObject = Any

public final class DIContext {
    
    fileprivate lazy var syncQueue:DispatchQueue = Dispatch.DispatchQueue(label: "", qos: .userInteractive)
    static var defaultInstance = DIContext()
    fileprivate var assemblies:[String:Assembly] = [:]

    var objectGraphStack:[String: InjectableObject] = [:]
    var objectGraphStackDepth:Int = 0
    var zeroDepthInjectionClosures:[()->Void] = []

    public init() {}

    public func assembly<AssemblyType: Assembly>() -> AssemblyType {
        let instance = self.instance(for: AssemblyType.self)
        return castAssemblyInstance(instance, asType: AssemblyType.self)
    }

    public func instance(for assemblyType: Assembly.Type) -> Assembly {

        let assemblyClassName:String = String(reflecting: assemblyType)
        if let instance = self.assemblies[assemblyClassName] {
            return instance
        }
        
        var instance:Assembly? = nil
        syncQueue.sync {
            instance = assemblyType.newInstance()
            instance?.context = self
            self.assemblies[assemblyClassName] = instance
        }
        return instance!
    }
}

internal protocol AssemblyInternal {
    static func newInstance() -> Self
}

public enum Scope {
    case prototype
    case objectGraph
    case lazySingleton
}

public typealias UntypedPatchInitObjectClosure = () -> InjectableObject
public typealias InitObjectPatchClosure<ObjectType: InjectableObject> = () -> ObjectType

public typealias UntypedPatchInjectObjectClosure = () -> InjectableObject
public typealias InjectObjectPatchClosure<ObjectType: InjectableObject> = () -> ObjectType

open class Assembly: AssemblyInternal {

    public internal(set) var context: DIContext!

    public static func instance(from context: DIContext = DIContext.defaultInstance)->Self {
        let instance = context.instance(for: self)
        return castAssemblyInstance(instance, asType: self)
    }

    internal static func newInstance() -> Self {
        return self.init()
    }

    public required init() {}

    var singletons:[String: InjectableObject] = [:]
    var definitions:[String: DefinitionInternal] = [:]
    internal var substitutions:[String: UntypedPatchClosure] = [:]

    public func addSubstitution<ObjectType: InjectableObject>(for definitionKey: String, with substitutionClosure: @escaping SubstitutionClosure<ObjectType>) {
        self.substitutions[definitionKey] = substitutionClosure
    }

    public func removeSubstitution(for definitionKey: String) {
        self.substitutions[definitionKey] = nil
    }

    public func definePlaceholder<ObjectType: InjectableObject>(key: String = #function) -> ObjectType {
        return self.define(key: key)
    }
    
    public func define<ObjectType: InjectableObject>(key: String = #function, definitionKey: String = #function, scope: Scope = .objectGraph, init initClosure: @autoclosure @escaping () -> ObjectType, inject injectClosure: @escaping (_ object: ObjectType) -> Void = { _ in } ) {
        let _:ObjectType = self.define(key: key, definitionKey: definitionKey, scope: scope, init: initClosure, inject: injectClosure)
    }

    public func define<ObjectType: InjectableObject, ResultType: InjectableObject>(key: String = #function, definitionKey: String = #function, scope: Scope = .objectGraph, init initClosure: @autoclosure @escaping () -> ObjectType, inject injectClosure: @escaping (_ object: ObjectType) -> Void = { _ in } ) -> ResultType {

        return self.define(key: key, definitionKey: definitionKey, scope: scope) { (definition:Definition<ResultType>) in
            definition.initClosure = {
                let objectFromInit = initClosure()
                guard let resultObject = objectFromInit as? ResultType else {
                    fatalError("Object of type \(objectFromInit) can't be converted to \(ResultType.self)")
                }
                return resultObject
            }
            definition.injectClosure = { object in
                injectClosure(object as! ObjectType)
            }
        }
    }

    fileprivate func define<ObjectType: InjectableObject>(key simpleKey: String = #function, definitionKey: String = #function, scope: Scope = .objectGraph, initClosure: DefinitionClosure<ObjectType>? = nil) -> ObjectType {
        
        let key: String = String(reflecting: self).replacingOccurrences(of: ".", with: "")+simpleKey
        var result:ObjectType

        guard let context = self.context else {
            fatalError("Assembly has no context to work in")
        }

        if let patchClosure = self.substitutions[definitionKey], let object = patchClosure() as? ObjectType {
            return object
        } else if scope == .lazySingleton, let singleton = self.singletons[key] as? ObjectType {
            result = singleton
        } else if let objectFromStack = context.objectGraphStack[key] as? ObjectType, scope != .prototype {
            result = objectFromStack
        } else if let definition = self.definitions[definitionKey], let object = definition.initObject() as? ObjectType {

            result = object
            context.objectGraphStack[key] = result
            self.context.zeroDepthInjectionClosures.append {
                definition.injectObject(object: object)
            }
        } else {

            let definition = Definition<ObjectType>()
            initClosure?(definition)
            self.definitions[definitionKey] = definition

            guard let object = definition.initObject() as? ObjectType else {
                fatalError("Invalid object type")
            }
            context.objectGraphStack[key] = object
            context.objectGraphStackDepth += 1
            definition.injectObject(object: object)
            context.objectGraphStackDepth -= 1

            result = object
        }

        if context.objectGraphStackDepth == 0 {
            while let closure = self.context.zeroDepthInjectionClosures.popLast() {
                context.objectGraphStack[key] = result
                context.objectGraphStackDepth += 1
                closure()
                context.objectGraphStackDepth -= 1
            }
            context.objectGraphStack.removeAll()
            definitions.removeAll()
        }

        if self.singletons[key] == nil, scope == .lazySingleton {
            self.singletons[key] = result
        }

        return result
    }
}

internal protocol DefinitionInternal {

    func initObject() -> InjectableObject?
    func injectObject(object: InjectableObject) -> Void
}

public final class Definition<ObjectType: InjectableObject>: DefinitionInternal {

    public var initClosure: ObjectInitClosure<ObjectType>?
    public var injectClosure: ObjectInjectClosure<ObjectType>?

    func initObject() -> InjectableObject? {
        return self.initClosure?()
    }
    func injectObject(object: InjectableObject) -> Void {
        guard let typedObject = object as? ObjectType else {
            return
        }
        self.injectClosure?(typedObject)
    }
}

public typealias ObjectInitClosure<ObjectType: InjectableObject> = () -> ObjectType
public typealias ObjectInjectClosure<ObjectType: InjectableObject> = (_ object: ObjectType) -> Void
public typealias DefinitionClosure<ObjectType: InjectableObject> = (_ definition: Definition<ObjectType>) -> Void
public typealias SubstitutionClosure<ObjectType: InjectableObject> = () -> ObjectType
internal typealias UntypedPatchClosure = () -> InjectableObject

func castAssemblyInstance<T>(_ instance: Any, asType type: T.Type) -> T {
    return instance as! T
}
