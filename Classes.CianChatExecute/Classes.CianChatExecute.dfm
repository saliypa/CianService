object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 342
  ClientWidth = 392
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 144
    Top = 8
    Width = 77
    Height = 13
    Caption = #1042#1085#1077#1096#1080#1081' id '#1063#1072#1090#1072
  end
  object GetWebhooksSub: TBitBtn
    Left = 8
    Top = 288
    Width = 119
    Height = 25
    Caption = 'GetWebhooksSub'
    TabOrder = 0
    OnClick = GetWebhooksSubClick
  end
  object GetMessageFileb: TBitBtn
    Left = 8
    Top = 257
    Width = 119
    Height = 25
    Caption = 'GetMessageFileb'
    TabOrder = 1
    OnClick = GetMessageFilebClick
  end
  object GetMessages: TBitBtn
    Left = 8
    Top = 226
    Width = 119
    Height = 25
    Caption = 'GetMessages'
    TabOrder = 2
    OnClick = GetMessagesClick
  end
  object SendReadChat: TBitBtn
    Left = 8
    Top = 195
    Width = 119
    Height = 25
    Caption = 'SendReadChat'
    TabOrder = 3
    OnClick = SendReadChatClick
  end
  object GetChats: TBitBtn
    Left = 8
    Top = 164
    Width = 119
    Height = 25
    Caption = 'GetChats'
    TabOrder = 4
    OnClick = GetChatsClick
  end
  object GetChat: TBitBtn
    Left = 8
    Top = 133
    Width = 119
    Height = 25
    Caption = 'GetChat'
    TabOrder = 5
    OnClick = GetChatClick
  end
  object TestWebhook: TBitBtn
    Left = 8
    Top = 102
    Width = 119
    Height = 25
    Caption = 'TestWebhook'
    TabOrder = 6
    OnClick = TestWebhookClick
  end
  object Send: TBitBtn
    Left = 8
    Top = 71
    Width = 119
    Height = 25
    Caption = 'Send'
    TabOrder = 7
    OnClick = SendClick
  end
  object UnSubscribe: TBitBtn
    Left = 8
    Top = 40
    Width = 119
    Height = 25
    Caption = 'UnSubscribe'
    TabOrder = 8
    OnClick = UnSubscribeClick
  end
  object Subscribe: TBitBtn
    Left = 8
    Top = 8
    Width = 119
    Height = 25
    Caption = 'Subscribe'
    TabOrder = 9
    OnClick = SubscribeClick
  end
  object EditChatId: TEdit
    Left = 144
    Top = 27
    Width = 201
    Height = 21
    TabOrder = 10
    Text = '42424242'
  end
  object TestWebhookSend: TBitBtn
    Left = 144
    Top = 102
    Width = 201
    Height = 25
    Caption = #1086#1090#1087#1088#1072#1074#1080#1090#1100' '#1090#1077#1089#1090#1086#1074#1086#1077' '#1089#1086#1086#1073#1097#1077#1085#1080#1077
    TabOrder = 11
    OnClick = TestWebhookSendClick
  end
  object MainConnection: TADOConnection
    CommandTimeout = 600
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 152
    Top = 48
  end
  object IdHTTPServer: TIdHTTPServer
    Bindings = <>
    DefaultPort = 8114
    OnCommandGet = IdHTTPServerCommandGet
    Left = 216
    Top = 48
  end
end
