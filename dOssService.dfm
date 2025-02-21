object dmOSSService: TdmOSSService
  OnCreate = ServiceCreate
  DisplayName = 'SetAtRuntime'
  WaitHint = 30000
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 179
  Width = 309
end
