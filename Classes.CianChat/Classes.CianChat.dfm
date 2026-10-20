object CianChat: TCianChat
  OldCreateOrder = False
  DisplayName = 'CianChatService'
  AfterInstall = ServiceAfterInstall
  OnContinue = ServiceContinue
  OnExecute = ServiceExecute
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
  object MainConnection: TADOConnection
    CommandTimeout = 600
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 32
    Top = 40
  end
  object IdHTTPServer: TIdHTTPServer
    Bindings = <>
    DefaultPort = 8114
    OnCommandGet = IdHTTPServerCommandGet
    Left = 128
    Top = 40
  end
end
