Pod::Spec.new do |s|
  s.name             = 'NBTimerTask'
  s.version          = '1.0.0'
  s.summary          = '一个使用source实现的易用的Timer'
  s.homepage         = 'https://github.com/liubin303/NBTimerTask'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liubin303' => '273631976@qq.com' }
  s.source           = { :git => 'https://github.com/liubin303/NBTimerTask.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.source_files     = 'NBTimerTask/*.{h,m}'
  s.requires_arc     = true

end