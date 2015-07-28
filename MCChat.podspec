#
# Be sure to run `pod lib lint MCChat.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MCChat"
  s.version          = "0.0.2"
  s.summary          = "A library facilitating chat over multipeer connectivity."
  s.description      = <<-DESC
                       MCChat is a library that facilitates chat using the multipeer connectivity framework.You can chat, select avatars, input personal information, see where people are without the need of any server setup!
                       DESC
  s.homepage         = "https://github.com/moray95/MCChat"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Moray Baruh" => "moraybaruh@me.com" }
  s.source           = { :git => "https://github.com/moray95/MCChat.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'MCChat' => ['Pod/Assets/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'CoreLocation', 'MultipeerConnectivity'
  s.dependency 'JSQMessagesViewController'
end
