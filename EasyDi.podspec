#
# Be sure to run `pod lib lint EasyDi.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EasyDi'
  s.version          = '1.1.0'
  s.summary          = 'Effective DI library for rapid development in 200 lines of code'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Swift 3 and 4, iOS 8+
  EasyDi contains a dependency container for Swift. The syntax of this library was specially designed for rapid development and effective use. It fits in 200 lines, thus can do everything you need for grown-up DI library:
  - Objects creating with dependencies and injection of dependencies into existing ones
  - Separation into assemblies
  - Types of dependency resolution: objects graph, singleton, prototype
  - Objects substitution and dependency contexts for tests
                       DESC

  s.homepage         = 'https://github.com/AndreyZarembo/EasyDi.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Andrey Zarembo' => 'andrey.zarembo@gmail.com' }
  s.source           = { :git => 'https://github.com/AndreyZarembo/EasyDi.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/AndreyZarembo'

  s.ios.deployment_target = '8.0'

  s.source_files = 'EasyDi/**/*.swift'
end
