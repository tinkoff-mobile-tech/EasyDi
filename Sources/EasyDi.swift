//
//  EasyDi.swift
//
//  Created by Andrey Zarembo.
//
import Foundation

public typealias InjectableObject = Any

/// This class is used to join assembly instanced into separated shared group. 
///
/// All assemblies with one context shares object graph stack.
///
/// Also easy assembly instance has it's own singleton storage, so singletons is created one per context.
///
/// Each test should have it's own context to persist independance of tests.
/// Substitutions also applyed to assembly instance in context and not shared between contexts.
///
/// Assemblies should obtain insances of each other via it's contexts to mantain graph consistency.
///
///  ```
///  lazy var anotherAssembly: AnotherAssemblyClass = self.context.assembly()
///  ```
///
public final class DIContext {
    
    fileprivate lazy var syncQueue:DispatchQueue = Dispatch.DispatchQueue(label: "EasyDi Context Sync Queue", qos: .userInteractive)
    
    public static var defaultInstance = DIContext()
    fileprivate var assemblies:[String:Assembly] = [:]

    var objectGraphStorage: [String: InjectableObject] = [:]
    
    var objectGraphStackDepth:Int = 0
    var zeroDepthInjectionClosures:[()->Void] = []

    public init() {}

    /// This method creates assembly instance based on it's result.
    ///
    /// - returns: Assembly instance
    ///
    ///  ```
    ///  lazy var anotherAssembly: AnotherAssemblyClass = self.context.assembly()
    ///  ```
    public func assembly<AssemblyType: Assembly>() -> AssemblyType {
        
        let instance = self.instance(for: AssemblyType.self)
        return castAssemblyInstance(instance, asType: AssemblyType.self)
    }

    /// This method creates assembly instance by type
    ///
    /// - parameter assemblyType: Class of the assembly
    ///
    /// - returns: Assembly instance
    ///
    /// ```
    /// var assembly = context.instance(for AssemblyClass.self)
    /// ```
    public func instance(for assemblyType: Assembly.Type) -> Assembly {
        
        var instance: Assembly? = nil
        syncQueue.sync {
            let assemblyClassName:String = String(reflecting: assemblyType)
            if let existingInstance = self.assemblies[assemblyClassName] {
                instance = existingInstance
            }
            else {
                let newInstance = assemblyType.newInstance()
                newInstance.context = self
                self.assemblies[assemblyClassName] = newInstance
                instance = newInstance
            }
        }
        return instance!
    }
}

/// Helper protocol to get Assembly instanced based on it's class
internal protocol AssemblyInternal {
    
    /// This method returns instance of assembly class
    ///
    /// - returns: Assembly instance
    static func newInstance() -> Self
}

/// [Types of dependency resolution]: https://github.com/AndreyZarembo/EasyDi#dependency-resolution-types-example-of-average-complexity
///
/// This tells assembly how it should return requested dependencies. Create one for object graph, return singleton or create new instance each time.
///
/// Read more here:  [Types of dependency resolution]
///
public enum Scope {
    
    /// [Prototype]: https://github.com/AndreyZarembo/EasyDi#prototype
    ///
    /// Dependency instance is created each time.
    ///
    /// [Prototype] description contains short example with memory graph illustration
    case prototype
    
    /// [ObjectGraph]: https://github.com/AndreyZarembo/EasyDi#objectgraph
    ///
    /// Dependency instance is created one per object graph.
    ///
    /// [ObjectGraph]  description contains short example with memory graph illustration
    case objectGraph
    
    /// [Singleton]: https://github.com/AndreyZarembo/EasyDi#singleton
    ///
    /// Dependency is created one per assembly. And created only at resosultion, so why it's lazy
    ///
    /// [Singleton]  description contains short example with memory graph illustration
    case lazySingleton
}


/// This is assembly class. Is't used to describe dependencies and resolve it.
///
/// Syntax:
/// ```
/// lazy var anotherAssembly:AnotherAssembly = self.context.assembly()
///
/// var object: IObjectProtocol {
///   return define(init: Object()) {
///     $0.serivce = self.service
///     $0.anotherService = self.anotherAssembly.anotherService
///   }
/// }
///
/// var service: IServiceProtocol {
///   return define(init: Service())
/// }
///
/// ```
open class Assembly: AssemblyInternal {

    public internal(set) var context: DIContext!

    /// This method creates assembly for specified context or default context if no paramters provided
    /// 
    /// - parameter context: DIContext object which assembly should belong to
    ///
    /// - returns: Assembly instance
    public static func instance(from context: DIContext = DIContext.defaultInstance)->Self {
        
        let instance = context.instance(for: self)
        return castAssemblyInstance(instance, asType: self)
    }

    /// Helper internal method to create assembly
    internal static func newInstance() -> Self {
        
        return self.init()
    }

    /// Initialiser
    public required init() {}

    /// All lazy singletons are stored here.
    ///
    /// Dictionary key is **key** parameter from **define** method
    var singletons:[String: InjectableObject] = [:]
    /// Temporary definitions cache
    ///
    /// Dictionary key is **key** parameter from **define** method
    var definitions:[String: DefinitionInternal] = [:]
    
    /// Array of applyed substitutions
    ///
    /// Dictionary key is **key** parameter from **define** method
    internal var substitutions:[String: UntypedPatchClosure] = [:]

    /// This method forces assembly to return result of closure instead of assemblies dependency.
    ///
    /// It's usefull to stub objects and make A / B testing
    ///
    /// - parameter definitionKey: should exactly match method or property name of substituting dependency
    /// - parameter substitutionClosure: closure, which returns result object for substitution
    ///
    public func addSubstitution<ObjectType: InjectableObject>(
        for definitionKey: String,
        with substitutionClosure: @escaping SubstitutionClosure<ObjectType>) {
        
        self.substitutions[definitionKey] = substitutionClosure
    }

    /// This method removes substitution from assembly
    ///
    /// - parameter definitionKey: should exactly match method or property name of substituting dependency
    ///
    public func removeSubstitution(for definitionKey: String) {
        
        self.substitutions[definitionKey] = nil
    }

    /// The method defines return-only placeholder for object.
    ///
    /// Use this method to inject something, created or injected with runtime parameters.
    ///
    /// **This method will crash if there's no such object in current graph**
    ///
    /// Usually this method defines key, and injecting function should have same key
    ///
    /// e.g.
    /// ```
    /// func inject(into: SomeViewController) {
    ///   defineInjection(key: "view", into: SomeViewController) {
    ///     $0.presenter = ...
    ///   }
    /// }
    ///
    /// var view: SomeViewController {
    ///   return self.definePlaceholder()
    /// }
    ///
    /// ```
    ///
    /// - parameter key: name of the method or property. Default value should be used in most cases
    ///
    /// - returns: Injected object from object graph
    ///
    public func definePlaceholder<ObjectType: InjectableObject>(key: String = #function) -> ObjectType {
        
        let closure: DefinitionClosure<ObjectType>? = nil
        return self.define(key: key, definitionClosure: closure)
    }
    
    /// This method defines injection into existing object without return
    ///
    /// It can be used to inject dependencies into existing objects.
    ///
    /// Also this method can define 'key' to make injected object available for *definePlaceholder* method
    /// e.g.
    /// ```
    /// func inject(into: SomeViewController) {
    ///   defineInjection(key: "view", into: SomeViewController) {
    ///     $0.presenter = ...
    ///   }
    /// }
    ///
    /// var view: SomeViewController {
    ///   return self.definePlaceholder()
    /// }
    ///
    /// ```
    ///
    /// - parameter key: name of the method or property. Default value should be used in most cases
    ///
    /// - parameter definitionKey: name of the method or property. Default value should be used
    ///
    /// - parameter scope: type of dependencies resolution. See: **Scope** and [Types of dependency resolution]
    ///
    /// - parameter initClosure: autoclosure, which is called to obtain initial object to be injected into. **Place injectable object here**
    ///
    /// - parameter injectClosure: optional closure, called to resolve dependencies for object. **Place dependencies definition here**
    /// Default value is empty closure.
    ///
    /// [Types of dependency resolution]: https://github.com/AndreyZarembo/EasyDi#dependency-resolution-types-example-of-average-complexity
    ///
    public func defineInjection<ObjectType>(
        key: String = #function,
        definitionKey: String = #function,
        scope: Scope = .objectGraph,
        into initClosure: @autoclosure @escaping () -> ObjectType,
        inject injectClosure: @escaping ObjectInjectClosure<ObjectType> = { _ in } ) {
        
        let _: ObjectType = self.define(
            key: key,
            definitionKey: definitionKey,
            scope: scope,
            init: initClosure,
            inject: injectClosure
        )
    }
    
    /// This method defines object, which will be initialized and injected by assembly.
    ///
    /// Syntax:
    /// ```
    /// lazy var anotherAssembly:AnotherAssembly = self.context.assembly()
    ///
    /// var object: IObjectProtocol {
    ///   return define(init: Object()) {
    ///     $0.serivce = self.service
    ///     $0.anotherService = self.anotherAssembly.anotherService
    ///   }
    /// }
    ///
    /// var service: IServiceProtocol {
    ///   return define(init: Service())
    /// }
    ///
    /// ```
    ///
    /// - parameter key: name of the method or property. Default value should be used in most cases
    ///
    /// - parameter definitionKey: name of the method or property. Default value should be used
    ///
    /// - parameter scope: type of dependencies resolution. See: **Scope** and [Types of dependency resolution]
    ///
    /// - parameter initClosure: autoclosure, which is called to obtain initial object to be injected into. **Place injectable object here**
    ///
    /// - parameter injectClosure: optional closure, called to resolve dependencies for object. **Place dependencies definition here**
    /// Default value is empty closure.
    ///
    /// - returns: Initialized and injected object
    ///
    /// [Types of dependency resolution]: https://github.com/AndreyZarembo/EasyDi#dependency-resolution-types-example-of-average-complexity
    ///
    public func define<ObjectType, ResultType: InjectableObject>(
        key: String = #function,
        definitionKey: String = #function,
        scope: Scope = .objectGraph,
        init initClosure: @autoclosure @escaping () -> ObjectType,
        inject injectClosure: @escaping ObjectInjectClosure<ObjectType> = { _ in } ) -> ResultType {

        return self.define(key: key, definitionKey: definitionKey, scope: scope) { (definition:Definition<ObjectType>) in
            definition.initClosure = initClosure
            definition.injectClosure = injectClosure
        }
    }

    /// Internal method where main injection logic is performed.
    ///
    /// - parameter key: name of the method or property. Default value should be used in most cases
    ///
    /// - parameter definitionKey: name of the method or property. Default value should be used
    ///
    /// - parameter scope: type of dependencies resolution. See: **Scope** and [Types of dependency resolution]
    ///
    /// - parameter definitionClosure: Closure with creation and configuration of **Definition<ObjectType>**. Default is nil for placeholder.
    ///
    /// - returns: Initialized and injected object
    ///
    /// [Types of dependency resolution]: https://github.com/AndreyZarembo/EasyDi#dependency-resolution-types-example-of-average-complexity
    ///
    fileprivate func define<ObjectType: InjectableObject, ResultType: InjectableObject>(
        key simpleKey: String = #function,
        definitionKey: String = #function,
        scope: Scope = .objectGraph,
        definitionClosure: DefinitionClosure<ObjectType>? = nil) -> ResultType {
        
        // Objects are stored in context by key made of Assembly class name and name of var or method
        let key: String = String(reflecting: self).replacingOccurrences(of: ".", with: "")+simpleKey
        var result:ObjectType

        guard let context = self.context else {
            fatalError("Assembly has no context to work in")
        }

        // First of all it checks if there's substitution for this var or method
        if let substitutionClosure = self.substitutions[definitionKey] {
            
            let substitutionObject = substitutionClosure()
            guard let object = substitutionObject as? ResultType else {
                fatalError("Expected type: \(ResultType.self), received: \(type(of: substitutionObject))")
            }
            return object

            
        // Next check for existing singletons
        } else if scope == .lazySingleton, let singleton = self.singletons[key] {
            
            result = singleton as! ObjectType
            
        // And trying to return object from graph
        } else if let objectFromStack = context.objectGraphStorage[key] as? ObjectType, scope == .objectGraph {
            
            result = objectFromStack

        } else if let definition = self.definitions[definitionKey], var object = definition.initObject() {
            
            result = object as! ObjectType
            context.objectGraphStorage[key] = result
            self.context.zeroDepthInjectionClosures.append {
                definition.injectObject(object: &object)
            }
        // Creating and initializing object
        } else {

            // Create Definition object to store injections and dependencies information
            let definition = Definition<ObjectType>()
            definitionClosure?(definition)
            self.definitions[definitionKey] = definition
            
            guard var object = definition.initObject() else {
                fatalError("Failed to initialize object")
            }
            
            // Object is created. It's stores in the object graph with it's key
            context.objectGraphStorage[key] = object
            // Going deeper to 'stack'.
            // Injections of this object will resolve dependencies recurently using objects from graph
            context.objectGraphStackDepth += 1
            definition.injectObject(object: &object)
            context.objectGraphStackDepth -= 1

            result = object as! ObjectType
        }
        
        // When recursion is finished, remove all objects from objectGraph
        if context.objectGraphStackDepth == 0 {
            while let closure = self.context.zeroDepthInjectionClosures.popLast() {
                context.objectGraphStorage[key] = result
                context.objectGraphStackDepth += 1
                closure()
                context.objectGraphStackDepth -= 1
            }
            context.objectGraphStorage.removeAll()
            definitions.removeAll()
        }

        // And save singletons
        if self.singletons[key] == nil, scope == .lazySingleton {
            
            self.singletons[key] = result
        }
        
        guard let finalResult = result as? ResultType else {
            fatalError("Failed to build result object. Expected \(ResultType.self) received: \(result)")
        }
        
        return finalResult
    }
}

/// This is type-erasing protocol used to store definition generics and access them
internal protocol DefinitionInternal {

    func initObject() -> InjectableObject?
    func injectObject(object: inout InjectableObject) -> Void
}

/// Definition object is used to store initialization and injection closures
public final class Definition<ObjectType: InjectableObject>: DefinitionInternal {

    public var initClosure: ObjectInitClosure<ObjectType>?
    public var injectClosure: ObjectInjectClosure<ObjectType>?

    func initObject() -> InjectableObject? {
        
        return self.initClosure?()
    }
    
    func injectObject(object: inout InjectableObject) -> Void {
        
        guard var injectableObject = object as? ObjectType else {
            
            return
        }
        
        self.injectClosure?(&injectableObject)
        object = injectableObject
    }
}

public typealias ObjectInitClosure<ObjectType: InjectableObject> = () -> ObjectType
public typealias ObjectInjectClosure<ObjectType: InjectableObject> = (_ object: inout ObjectType) -> Void
public typealias DefinitionClosure<ObjectType: InjectableObject> = (_ definition: Definition<ObjectType>) -> Void
public typealias SubstitutionClosure<ObjectType: InjectableObject> = () -> ObjectType
internal typealias UntypedPatchClosure = () -> InjectableObject

/// Helper function to cast Assembly type correctly
func castAssemblyInstance<T>(_ instance: Any, asType type: T.Type) -> T {
    
    return instance as! T
}
