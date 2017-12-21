# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'CoinWatch' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CoinWatch
  pod 'RealmSwift'
  pod "PromiseKit", "~> 4.0"
  pod "HockeySDK", :subspecs => ['AllFeaturesLib']
  pod "SVPullToRefresh"
  pod "coinbase-official", :path => '~/Developer/Personal/coinbase-sdk'

  target 'CoinWatchTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
