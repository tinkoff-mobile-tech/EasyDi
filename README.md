# EasyDi

[![CI Status](https://travis-ci.org/AndreyZarembo/EasyDi.svg?branch=master](https://travis-ci.org/AndreyZarembo/EasyDi)
[![Version](https://img.shields.io/cocoapods/v/EasyDi.svg?style=flat)](http://cocoapods.org/pods/EasyDi)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/EasyDi.svg?style=flat)](http://cocoapods.org/pods/EasyDi)
[![Platform](https://img.shields.io/cocoapods/p/EasyDi.svg?style=flat)](http://cocoapods.org/pods/EasyDi)
[![Swift Version](https://img.shields.io/badge/Swift-3.0--4.0-F16D39.svg?style=flat)](https://developer.apple.com/swift)

![](easy_di_logo.png)

Effective DI library for rapid development in 200 lines of code.

## Requirements

Swift 3 or 4, iOS 8+

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

EasyDi is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "EasyDi"
```

## Author

Andrey Zarembo

e-mail: [andrey.zarembo@gmail.com](mailto:andrey.zarembo@gmail.com)

twitter: [@andreyzarembo](https://twitter.com/AndreyZarembo)

telegram: [@andreyzarembo](https://telegram.me/andreyzarembo)

## License

EasyDi is available under the MIT license. See the LICENSE file for more info.

## About

Dependency inversion is very important if project contains more than 5 screens and will be supported for more than a year.
Here are three basic scenarios where DI makes life better:

- **Parallel development**. One developer will be able to deal with UI, while another one will work with data if they agree in advance on the interfaces. Then UI can be developed with test data, and the data layer can be called from the test UI.

- **Tests**. By substituting the network layer for objects with fixed responses, you can check all the options for UI behavior, including in case of errors.

- **Refactor**. The network layer can be replaced with a new, fast version with a cache and another API, if you leave the protocol with the UI unchanged.

The essence of DI can be described in one sentence: Dependencies for objects should be closed by the protocol and passed to the object when creating from the outside.

```swift
// Instead of
class OrderViewController {
  func didClickShopButton(_ sender: UIButton?) {
    APIClient.sharedInstance.purchase(...)
  }
}

// this approach should be used
protocol IPurchaseService {
  func perform(...)
}

class OrderViewController {
  var purchaseService: IPurchaseService?
  func didClickShopButton(_ sender: UIButton?) {
    self.purchaseService?.perform(...)
  }
}
```

More details with the principle of dependency inversion and the SOLID concept can be found [here](https://www.objc.io/issues/15-testing/dependency-injection/) and [here](https://en.wikipedia.org/wiki/SOLID_(object-oriented_design)).

EasyDi contains a dependency container for Swift. The syntax of this library was specially designed for rapid development and effective use. It fits in 200 lines, thus can do everything you need for grown-up DI library:

- Objects creating with dependencies and injection of dependencies into existing ones
- Separation into containers - Assemblies
- Types of dependency resolution: objects graph, singleton, prototype
- Objects substitution and dependency contexts for tests

There is no register / resolve methods in EasyDi. Instead of this, the dependencies are described like this:

```swift
var apiClient: IAPIClient {
  return define(init: APIClient()) {
    $0.baseURl = self.baseURL
  }
}
```

This makes it possible to resolve circular dependencies and implement already existing objects.

## How to work with EasyDi (A simple example)

A simple example of using a library: to remove the work with the network from the ViewController to the services and place their creation and dependencies in a separate container. This is a simple and effective way to begin dividing an application into layers. In this example we'll look at the service and controller from the example above.

```swift
protocol IPurchaseService {
  func perform(with objectId: String, then completion: (success: Bool)->Void)
}    

class PurchaseService {

  var baseURL: URL?
  var apiPath = "/purchase/"
  var apiClient: IAPIClient?

  func perform(with objectId: String, then completion: (_ success: Bool) -> Void) {

    guard let apiClient = self.apiClient, let url = self.baseURL else {
      fatalError("Trying to do something with uninitialized purchase service")
    }
    let purchaseURL = baseURL.appendingPathComponent(self.apiPath).appendingPathComponent(objectId)
    let urlRequest = URLRequest(url: purchaseURL)
    self.apiClient.post(urlRequest) { (_, error) in
      let success: Bool = (error == nil)
        completion( success )
    }
  }
}
```

Controller:

```swift
class OrderViewController {

  var purchaseService: IPurchaseService?
  var purchaseId: String?

  func didClickShopButton(_ sender: UIButton?) {

    guard let purchaseService = self.purchaseService, let purchaseId = self.purchaseId else {
      fatalError("Trying to do something with uninitialized order view controller")
    }

    self.purchaseService.perform(with: self.purchaseId) { (success) in
      self.presenter(showOrderResult: success)
    }
  }
}
```

Service dependencies:

```swift
class ServiceAssembly: Assembly {

  var purchaseService: IPurchaseService {
    return define(init: PurchaseService()) {
      $0.baseURL = self.apiV1BaseURL
      $0.apiClient = self.apiClient
    }
  }

  var apiClient: IAPIClient {
    return define(init: APIClient())
  }

  var apiV1BaseURL: URL {
    return define(init: URL("http://someapi.com/")!)
  }
}
```

And this is how we inject the service in the controller:

```swift
var orderViewAssembly: Assembly {

  var serviceAssembly: ServiceAssembly = self.context.assembly()

  func inject(into controller: OrderViewController, purchaseId: String) {
    let _:OrderViewController = define(init: controller) {
    $0.purchaseService = self.serviceAssembly.purchaseService
    $0.purchaseId = purchaseId
    }
  }
}
```

Now you can change the class of the service without going into the ViewController.   

## Dependency resolution types (Example of average complexity)

### ObjectGraph

By default, all dependencies are resolved through the graph of the objects. If the object already exists on the stack of the current object graph, then it is used again. This allows to insert the same object into several objects, and also allow the cyclic dependencies. For example, take the objects A, B and C with links A-> B-> C. (Do not pay attention to RetainCycle).

```swift
class A {
  var b: B?
}

class B {
  var c: C?
}

class C {
  var a: A?
}
```

This is how Assembly looks and here is a dependency graph for two requests A.

```swift
class ABCAssembly: Assembly {

  var a:A {
    return define(init: A()) {
      $0.b = self.B()
    }
  }

  var b:B {
    return define(init: B()) {
      $0.c = self.C()
    }
  }

  var c:C {
    return define(init: C()) {
      $0.a = self.A()
    }
  }
}

var a1 = ABCAssembly.instance().a
var a2 = ABCAssembly.instance().a
```

![](/scopes_object_graph.png)
Two independent graphs were obtained.

### Singleton

But it happens that you need to create one object, which will then be used everywhere, for example, the analytics system or the storage. It is not necessary to use the classic Singleton with SharedInstance, because it will not be possible to replace it. For these purposes, there is scope in EasyDi: singleton. This object is created once, once dependencies are introduced into it and more EasyDi does not change it, but only returns. For example, we make a singleton from B.

```swift
class ABCAssembly: Assembly {
  var a:A {
    return define(init: A()) {
      $0.b = self.B()
    }
  }

  var b:B {
    return define(scope: .lazySingleton, init: B()) {
      $0.c = self.C()
    }
  }

  var c:C {
    return define(init: C()) {
      $0.a = self.A()
    }
  }
}

var a1 = ABCAssembly.instance().a
var a2 = ABCAssembly.instance().a
```
![](/scopes_singleton.png)
This time, one object graph was obtained, because B became common.

### Prototype

Sometimes each request requires a new object.  On the example of ABC objects for the A-prototype, this would look like this:

```swift
class ABCAssembly: Assembly {
  var a:A {
    return define(scope: .prototype, init: A()) {
      $0.b = self.B()
    }
  }

  var b:B {
    return define(init: B()) {
      $0.c = self.C()
    }
  }

  var c:C {
    return define(init: C()) {
      $0.a = self.A()
    }
  }
}

var a1 = ABCAssembly.instance().a
var a2 = ABCAssembly.instance().a
```
![](/scopes_prototype.png)

There results that two graphs of objects give 4 copies of object A

It is important to understand that this is the entry point to the graph and it is not necessary to make prototypes from other dependencies. If you combine prototypes in a loop, then the stack will be overflow and the application will fall.

## Substitutions and contexts for tests (A complex example)

When testing, it is important to maintain test independence. In EasyDi, this is provided by Assemblies contexts. For example, integration tests, where singletons are used. They are used like this:

```swift
let context: DIContext = DIContext()
let assemblyInstance2 = TestAssembly.instance(from: context)
```

It is important to ensure that the contexts of the shared Assemblies coincide.

```swift
class FeedViewAssembly: Assembly {

  lazy var serviceAssembly:ServiceAssembly = self.context.assembly()

}
```

Another important part of testing is mocks and stubs, that is, objects with known behavior. With known input data, the tested object produces a known result. If object does not produce it, then the test is not passed. More information about testing can be found [here](https://www.objc.io/issues/15-testing/). And here's how you can replace the object:

```swift
protocol ITheObject {
  var intParameter: Int { get }
}

class MyAssembly: Assembly {

  var theObject: ITheObject {
    return define(init: TheObject()) {
      $0.intParameter = 10
    }
  }
}

let myAssembly = MyAssembly.instance()
myAssembly.addSubstitution(for: "theObject") { () -> ITheObject in
  let result = FakeTheObject()
  result.intParameter = 30
  return result
}
```

Now the theObject property will return a new object of another type with another intParameter.

The same mechanism can be used for a / b testing in the application. For example, like this:

```swift
let FeatureAssembly: Assembly {

  var feature: IFeature {
    return define(init: Feature) {
      ...
    }
  }
}

let FeatureABTestAssembly: Assembly {

  lazy var featureAssembly: FeatureAssembly = self.context.assembly()

  var feature: IFeature {
    return define(init: FeatureV2) {
      ...
    }
  }

  func activate(firstTest: Bool) {
    if (firstTest) {
      self.featureAssembly.addSubstitution(for: "feature") {
        return self.feature
      }
    } else {
      self.featureAssembly.removeSubstitution(for: "feature")
    }
  }
}
```

Here, a separate container is created for the test, which creates a second variant of the object and allows to enable / disable the substitution of this object.

## Dependency injection in the VIPER (Complex example)

It happens that it is necessary to inject dependencies into an existing object, and from him, too, someone depends. The simplest example is VIPER, when Presenter should be added to the ViewController, and it should get a link to the ViewController itself.

For this, EasyDi has 'keys' with which you can return the same object from different methods. It looks like this:

```swift
сlass ModuleAssembly: Assembly {

  func inject(into view: ModuleViewController) {
    return define(key: "view", init: view) {
      $0.presenter = self.presenter
    }
  }

  var view: IModuleViewController {
    return definePlaceholder()
  }

  var presenter: IModulePresenter {
    return define(init: ModulePresenter()) {
	  $0.view = self.view
      $0.interactor = self.interactor
    }
  }

  var interaction: IModuleInteractor {
    return define(init: ModuleInteractor()) {
	  $0.presenter = self.presenter
      ...
    }
  }
}
```

Here, to implement dependencies in the ViewController, the inject method is used, which is linked by the key with the viewController property. Now, this property returns the object passed to the inject method. And only when resolving the dependencies of the graph of objects that begins with the inject method.
