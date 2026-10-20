unit Classes.CianChat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.SvcMgr,
  System.Win.Registry, Data.DB, Data.Win.ADODB, IdContext,
  IdCustomHTTPServer, IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer;

type
  TCianChat = class(TService)
    MainConnection: TADOConnection;
    IdHTTPServer: TIdHTTPServer;
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    function GetServiceController: TServiceController; override;
  end;

var
  CianChat: TCianChat;


implementation

uses
 Classes.Inc, Classes.Logs, Classes.Common, Classes.CianHandler;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
 CianChat.Controller(CtrlCode);
end;

constructor TCianChat.Create(AOwner: TComponent);
begin
 inherited;
 //Имя службы берётся из имени exe (CianChatService / CianChatAssignmentService).
 //SCM передаёт имя службы в ServiceMain, и VCL ищет TService с таким Name -
 //при несовпадении служба не запускается (ошибка 1053)
 Name:=GetServiceName;
 DisplayName:=Name;
end;

procedure TCianChat.ServiceExecute(Sender: TService);
begin
 while not Terminated do
  begin
   ServiceThread.ProcessRequests(false);
   TThread.Sleep(1000);
  end;
end;

function TCianChat.GetServiceController: TServiceController;
begin
 Result:=ServiceController;
end;

{$REGION 'ServiceAfterInstall'}
procedure TCianChat.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
 Reg:=TRegistry.Create(KEY_READ or KEY_WRITE);
 try
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey('SYSTEM\CurrentControlSet\Services\' + Name, false)
   then
    begin
     Reg.WriteString('Description', cDescription);
     Reg.CloseKey;
    end;
 finally
  Reg.Free;
 end;
end;
{$ENDREGION 'ServiceAfterInstall'}

procedure TCianChat.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
 WriteLog_C(Format('#Attempting to continue service %s', [Name]));
 //Пауза = не принимаем запросы (Циан повторяет доставку, но через 72 ч недоставки отключает URL; запросы ИК получат отказ соединения)
 try
  IdHTTPServer.Active:=True;
  Continued:=True;
 except on e:Exception do
   begin
    Continued:=False;
    WriteLog_C('*** Has error in TCianChat.ServiceContinue: ['+E.ClassName+': '+e.Message+']');
   end;
 end;
 WriteLog_C('#Service continued');
end;

procedure TCianChat.ServicePause(Sender: TService; var Paused: Boolean);
begin
 WriteLog_C(Format('#Attempting to pause service %s', [Name]));
 try
  IdHTTPServer.Active:=False;
 except on e:Exception do WriteLog_C('*** Has error in TCianChat.ServicePause: ['+E.ClassName+': '+e.Message+']'); end;
 Paused:=True;
 WriteLog_C('#Service paused');
end;

procedure TCianChat.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
 WriteLog_C(Format('#Attempting to stop service %s', [Name]));
 try
  IdHTTPServer.Active:=False;
 except on e:Exception do WriteLog_C('*** Has error in TCianChat.ServiceStop: ['+E.ClassName+': '+e.Message+']'); end;
 Stopped:=True;
 WriteLog_C('#Service stopped');
end;

procedure TCianChat.ServiceStart(Sender: TService; var Started: Boolean);
begin
 Started:=False;
 try
  if not LoadSettings
   then Exit;

  WriteLog_C(Format('#Attempting to start service %s', [Name]));
  MainConnection.ConnectionString:=sConnectionString;

  IdHTTPServer.DefaultPort:=sServerPort.ToInteger;
  IdHTTPServer.Active:=True;

  //Подписка
  TThread.CreateAnonymousThread(
   procedure
    begin
     if not SetListener
      then WriteLog_C('!!! Webhooks subscription check failed, see log above');
    end).Start;

  Started:=True;
  WriteLog_C('#Service started');
 except on e:Exception do
   begin
    WriteLog_C('*** Has error in TCianChat.ServiceStart: ['+E.ClassName+': '+e.Message+']');
    try IdHTTPServer.Active:=False; except end;
   end;
 end;
end;

{$REGION 'IdHTTPServerCommandGet'}
procedure TCianChat.IdHTTPServerCommandGet(AContext:TIdContext; ARequestInfo:TIdHTTPRequestInfo; AResponseInfo:TIdHTTPResponseInfo);
begin
 HandleHTTPRequest(ARequestInfo,AResponseInfo);
end;
{$ENDREGION 'IdHTTPServerCommandGet'}

end.
