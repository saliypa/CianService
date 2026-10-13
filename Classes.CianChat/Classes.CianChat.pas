unit Classes.CianChat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  System.Win.Registry, System.IniFiles, Vcl.ExtCtrls, Data.DB, Data.Win.ADODB, System.Variants, IdContext,
  IdCustomHTTPServer, IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer, System.Threading,
  Classes.CianResponseCore, WinApi.ActiveX;

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
    FConnectionString : string;
    function  SetSettings:boolean;
    function  GetMessageFile(AChatId:string; AFile:TFile):string;
    function  SetListener:boolean;
  public
    { Public declarations }
    function GetServiceController: TServiceController; override;
  end;

var
  CianChat: TCianChat;


implementation

uses
 Classes.Inc, Classes.Logs, Classes.DBCore, Classes.CianApiCore, Classes.Common;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
 CianChat.Controller(CtrlCode);
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
  if Reg.OpenKey('SYSTEM\CurrentControlSet\Services' + name, false)
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
 WriteLog_C(Format('#Attempting to continue service %s', [cServiceName]));
 Continued:=True;
 WriteLog_C('#Service continued');
end;

procedure TCianChat.ServicePause(Sender: TService; var Paused: Boolean);
begin
 WriteLog_C(Format('#Attempting to pause service %s', [cServiceName]));
 Paused:=True;
 WriteLog_C('#Service paused');
end;

procedure TCianChat.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
 WriteLog_C(Format('#Attempting to stop service %s', [cServiceName]));
 Stopped:=True;
 WriteLog_C('#Service stopped');
 Sleep(1000);
end;

procedure TCianChat.ServiceStart(Sender: TService; var Started: Boolean);
begin
 if not SetSettings
  then Halt;

 IdHTTPServer.DefaultPort:=sServerPort.ToInteger;
 IdHTTPServer.Active:=True;

 if not SetListener
  then
   begin
    IdHTTPServer.Active:=False;
    Halt;
   end;

 WriteLog_C(Format('#Attempting to start service %s', [cServiceName]));
 WriteLog_C('#Service started');
end;

{$REGION 'SetListener'}
function TCianChat.SetListener:boolean;
var
 ACianApiCore  : TCianApiCore;
 AResponse     : string;
 AFound        : boolean;
 AWebhookTypes : array of TWebhookTypes;
 AIteration    : integer;
begin
 Result:=False;
 AFound:=False;
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  try
   SetLength(AWebhookTypes,1);
   AWebhookTypes[0]:=wtOffersMessagesIncoming;
   //AWebhookTypes[1]:=wtOffersMessagesApiOutgoing;
   //AWebhookTypes[2]:=wtSystemMessages;

   if sCheckSubscribe
    then
     begin
      AIteration:=0;
      AResponse:=EmptyStr;
      while ((AResponse=EmptyStr) or (Pos('error',LowerCase(AResponse))>0)) and
            (AIteration<5) do
       begin
        Inc(AIteration);
        WriteLog_C('--> CIAN. GetWebhooksSub.');
        WriteLog_C('--> CIAN. GetWebhooksSub. Iteration #' + AIteration.ToString);
        AResponse:=ACianApiCore.GetWebhooksSub;
        WriteLog_C('<-- CIAN. GetWebhooksSub. Response=['+AResponse+']');
       end;

      if (Pos('error',LowerCase(AResponse))>0) or
         (AResponse=EmptyStr)
       then Exit;

      AFound:=FoundValueSubscriptions(AResponse,sWebhooksURL);
     end;

   if sSetUnSubscribe
    then
     begin
      AResponse:=ACianApiCore.UnSubscribeWebhooks(wtOffersMessages);
      //AResponse:=ACianApiCore.UnSubscribeWebhooks(wtSystemMessages);
      //AResponse:=ACianApiCore.UnSubscribeWebhooks(wtChatsReadability);
      Exit;
     end;

   if (sSetSubscribe) and
       (not AFound)
    then
     begin
      AIteration:=0;
      AResponse:=EmptyStr;
      while ((AResponse=EmptyStr) or (Pos('error',LowerCase(AResponse))>0)) and
            (AIteration<5) do
       begin
        Inc(AIteration);
        WriteLog_C('--> CIAN. SubscribeWebhooks.');
        WriteLog_C('--> CIAN. SubscribeWebhooks. Iteration #' + AIteration.ToString);
        AResponse:=ACianApiCore.SubscribeWebhooks(AWebhookTypes);
        WriteLog_C('<-- CIAN. SubscribeWebhooks. Response=['+AResponse+']');
       end;

      if (Pos('error',LowerCase(AResponse))>0) or
         (AResponse=EmptyStr)
       then Exit;

      AIteration:=0;
      AResponse:=EmptyStr;
      while ((AResponse=EmptyStr) or (Pos('error',LowerCase(AResponse))>0)) and
            (AIteration<5) do
       begin
        Inc(AIteration);
        WriteLog_C('--> CIAN. GetWebhooksSub.');
        WriteLog_C('--> CIAN. GetWebhooksSub. Iteration #' + AIteration.ToString);
        AResponse:=ACianApiCore.GetWebhooksSub;
        WriteLog_C('<-- CIAN. GetWebhooksSub. Response=['+AResponse+']');
       end;

      if (Pos('error',LowerCase(AResponse))>0) or
         (AResponse=EmptyStr)
       then Exit;
     end;

   Result:=True;
  except on e:Exception do WriteLog_C('*** Has error in TCianChat.SetListener: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ACianApiCore.Free;
 end;
end;
{$ENDREGION 'SetListener'}

{$REGION 'SetSettings'}
function TCianChat.SetSettings:boolean;
var
 AIniFile  : TMemIniFile;
 AString   : string;
 AMainPath : string;
 AMainEXE  : string;
begin
 //Для сервиса
 AMainPath:=cMainPath;
 //Для сервиса переуступок
 //AMainPath:=cMainAssigPath;
 //Для обычного исполняемого файла
 //AMainPath:=ExtractFilePath(ParamStr(0));

 //Для сервиса
 AMainEXE:=cMainExe;
 //для сервиса переуступок
 //AMainEXE:=cMainAssigExe;
 //Для обычного исполняемого файла
 //AMainEXE:=ExtractFileName(ParamStr(0));

 AIniFile:=TMemIniFile.Create(ChangeFileExt(AMainPath+AMainEXE, '.ini'),TEncoding.UTF8);
 try
  //Основные настройки
  sServerPort:=AIniFile.ReadString('Parameters', 'ServerPort', '8114');

  AString:=Trim(AIniFile.ReadString('Parameters', 'LogHistPath', 'LogHistory'));
  HistLogPath:=AMainPath+AString;
  MaxLogSize:=AIniFile.ReadInteger('Parameters', 'MaxLogSize', 1000000);
  LogFilePath:=ChangeFileExt(AMainPath+AMainEXE, cLogExt);

  sSetSubscribe:=AIniFile.ReadInteger('Parameters', 'SetSubscribe', 1).ToBoolean;
  sSetUnSubscribe:=AIniFile.ReadInteger('Parameters', 'SetUnSubscribe', 0).ToBoolean;
  sCheckSubscribe:=AIniFile.ReadInteger('Parameters', 'CheckSubscribe', 1).ToBoolean;
  if sSetUnSubscribe
   then sSetSubscribe:=False;

  sPathFile:=AIniFile.ReadString('Parameters', 'PathTempFiles',cPathFile);
  sWebhooksURL:=AIniFile.ReadString('Parameters', 'WebhooksURL',cWebhooksURL);
  sToken:=AIniFile.ReadString('Parameters', 'Token',cToken);
  sDebugMode:=AIniFile.ReadInteger('Parameters', 'DebugMode', 0).ToBoolean;

  sServerName:=AIniFile.ReadString('Parameters', 'ServerName',cServerWork);
  sDBName:=AIniFile.ReadString('Parameters', 'DBName',cDBNameWork);

  sMainDescription:=AIniFile.ReadString('Parameters', 'MainDescription',cMainDescription);

  WriteLog_C(#13#10#13#10);
  FConnectionString:=Format('Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=True;Data Source=%s;Initial Catalog=%s;Application Name=%s',
                  [UpperCase(sServerName), sDBName, cServiceName]);

  WriteLog_C(Format('#Connecting to DB: %s',[FConnectionString]));
  MainConnection.ConnectionString:=FConnectionString;

  Result:=True;
 finally
  FreeAndNil(AIniFile);
 end;
end;
{$ENDREGION 'SetSettings'}

{$REGION 'GetMessageFile'}
function TCianChat.GetMessageFile(AChatId:string; AFile:TFile):string;
var
 ACianApiCore:TCianApiCore;
 AFilePath:string;
 AFileStream:TFileStream;
 AMemoryStream:TMemoryStream;
begin
 Result:=EmptyStr;
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  try
   AFilePath:=sPathFile+AChatId+'\';
   ForceDirectories(AFilePath);
   if not DirectoryExists(AFilePath)
    then
     begin
      AFilePath:=GetUserTempPath+AChatId+'\';
      ForceDirectories(AFilePath);
     end;

   if not DirectoryExists(AFilePath)
    then Exit;

   AFilePath:=AFilePath+AFile.fileId+AFile.name;
   AMemoryStream:=ACianApiCore.GetMessageFile(AFile.fileId);
   try
    if AMemoryStream=nil
     then raise Exception.Create('Error downloading file');

    AFileStream:=TFileStream.Create(AFilePath,fmCreate);
    try
     AFileStream.CopyFrom(AMemoryStream,AMemoryStream.Size);
    finally
     AFileStream.Free;
    end;
   finally
    AMemoryStream.Free;
   end;

   Result:=AFilePath;
   WriteLog_C('<-- CIAN. Receiving. File downloaded successfully. ['+AFilePath+']');
  except on e:Exception do WriteLog_C('*** Has error in TCianChat.GetMessageFile: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ACianApiCore.Free;
 end;
end;
{$ENDREGION 'GetMessageFile'}

{$REGION 'IdHTTPServerCommandGet'}
procedure TCianChat.IdHTTPServerCommandGet(AContext:TIdContext; ARequestInfo:TIdHTTPRequestInfo; AResponseInfo:TIdHTTPResponseInfo);
var
 AResponseNo    : integer;
 AResponseText  : string;
 AParamsOut     : TStrings;
 AStringStream  : TStringStream;
begin
 AResponseNo:=200;
 AResponseText:='OK';
 try
  try
   {$REGION 'cSendCmd'}
   if (ARequestInfo.CommandType=hcPOST) and
      (Pos(LowerCase(cSendCmd),LowerCase(ARequestInfo.Params.Text))>0)
    then
     begin
      if ARequestInfo.Params.Text=EmptyStr
       then exit;

      WriteLog_C('--> CIAN. Send. Start');
      WriteLog_C('--> CIAN. Send. Params=['+Trim(StringReplace(ARequestInfo.Params.Text,#13#10,'; ',[rfReplaceAll]))+']');

      AParamsOut:=TStringList.Create;
      AParamsOut.Text:=ARequestInfo.Params.Text;

      TThread.CreateAnonymousThread(
       procedure
        var
         ACianApiCore  : TCianApiCore;
         AResponse     : string;
         AChatId       : string;
         AMessage      : string;
         i             : integer;
        begin
         AResponse:=EmptyStr;
         ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
         try
          for i:=0 to AParamsOut.Count-1 do
           begin
            if AParamsOut.Names[i]='ChatId'
             then AChatId:=AParamsOut.ValueFromIndex[i];

            if AParamsOut.Names[i]='Message'
             then AMessage:=StringReplace(AParamsOut.ValueFromIndex[i], '\n', Chr(10), [rfReplaceAll]);
           end;

           AResponse:=AResponse + ACianApiCore.SendMessage(AChatId,AMessage);
         finally
          if Assigned(ACianApiCore)
           then ACianApiCore.Free;
          if Assigned(AParamsOut)
           then AParamsOut.Free;
         end;

         TThread.Synchronize(nil,
         procedure
          begin
           WriteLog_C('<-- CIAN. Send. Response=['+AResponse+']');
           WriteLog_C('<-- CIAN. Send. End.');
          end);
        end).Start;


      Exit;
     end;
   {$ENDREGION 'cSendCmd'}

   {$REGION 'cRespCmd'}
   if (ARequestInfo.CommandType=hcPOST) and
      (Pos(cRespCmd,LowerCase(ARequestInfo.URI))>0)
    then
     begin
      WriteLog_C('--> CIAN. Receiving. Start');
      //WriteLog_C('--> CIAN. Receiving. Params=['+Trim(StringReplace(ARequestInfo.Params.Text,#13#10,'; ',[rfReplaceAll]))+']');

      if not Assigned(ARequestInfo.PostStream)
       then exit;
      AStringStream:=TStringStream.Create('',TEncoding.UTF8);
      AStringStream.LoadFromStream(ARequestInfo.PostStream);
      AStringStream.Position:=0;

      TThread.CreateAnonymousThread(
       procedure
        var
         ACianApiCore      : TCianApiCore;
         AResponse         : string;
         AConnection       : TADOConnection;
         AChatIdIntOff     : string;
         AChatIdIntOnline  : string;
         i                 : integer;
         j                 : integer;
         k                 : integer;
         ACianResponseJson : TCianResponseJson;
         AUser             : TUser;
         AOffer            : TOfferDetails;
         ASessionId        : string;
         AResultAdvOper    : TResultAdv;
         AResultAdvNew     : TResultAdv;
         AOperatorId       : string;
         AOperatorAllow    : boolean;
         ADecription       : string;
         ABotMessage       : string;
         AFileName         : string;
         AWithFiles        : integer;
        begin
         AResponse:=EmptyStr;
         ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
         CoInitialize(nil);
         AConnection:=TADOConnection.Create(nil);
         try
          AConnection.ConnectionString:=FConnectionString;
          AConnection.LoginPrompt:=False;
          AConnection.Connected:=True;

          ACianResponseJson:=ParseCianResponseJson(AStringStream.DataString);

          for i:=0 to High(ACianResponseJson.Result.OffersMessagesWebhook.Chats) do
           begin
            ABotMessage:=EmptyStr;
            ASessionId:=CianDBCore.SetUserSession(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].chatId.ToString,cMainURL,cMainDescription,AConnection);
            for j:=0 to High(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages) do
             begin
              AResultAdvOper:=CianDBCore.GetFreeOperator(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].chatId.ToString,cMainDescription,AConnection);
              if AResultAdvOper.ResultType>0
               then
                begin
                 ADecription:=AResultAdvOper.ResultValue[0];
                 AOperatorAllow:=AResultAdvOper.ResultValue[1].ToBoolean;
                 AOperatorId:=AResultAdvOper.ResultValue[2];
                end
               else
                begin
                 ADecription:=EmptyStr;
                 AOperatorAllow:=False;
                 AOperatorId:=EmptyStr;
                end;

              AUser:=FindUserByUserId(ACianResponseJson.Result.OffersMessagesWebhook,ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].UserId);
              AOffer:=FindOfferByOfferId(ACianResponseJson.Result.OffersMessagesWebhook,ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].OfferId);
              if not AOperatorAllow
               then
                begin  //сообщения от бота
                  ABotMessage:=ADecription;

                  AChatIdIntOff:=CianDBCore.SetOfflineMess(cMainURL,AUser.firstName+' '+AUser.lastName+' '+ AUser.name,ASessionId,AConnection);

                  if CianDBCore.UpdOfflineMess(AChatIdIntOff,ABotMessage,AConnection)
                   then
                    begin
                     AResponse:=ACianApiCore.SendMessage(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].chatId.ToString,ABotMessage);

                     AResponse:=AResponse+'#'+(j+1).ToString+'; ';
                    end;
                end;

              if AOperatorAllow
               then
                begin
                  AWithFiles:=High(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].content.files)+1;
                  AResultAdvNew:=CianDBCore.SetNewChat(ASessionId,AOperatorId,
                                             AOffer.url,//ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].content.offers[0].url,
                                             cMainDescription,
                                             AUser.firstName+' '+AUser.lastName+' '+ AUser.name,
                                             ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].content.text + iif(AWithFiles>0,Format('Прикрепленный файл %d шт.',[AWithFiles]),EmptyStr),
                                             AConnection);

                  if AResultAdvNew.ResultType=0 //Создан новый чат
                   then
                    begin
                      AResponse:=ACianApiCore.SendMessage(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].chatId.ToString,ADecription);
                      AResponse:=AResponse+'#'+(j+1).ToString+'; ';
                    end;

                  if AResultAdvNew.ResultType=1 //Продолжен имеющийся чат
                   then
                    begin
                     AChatIdIntOnline:=AResultAdvNew.ResultValue[0];
                     for k:=0 to High(ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].content.files) do
                      begin
                       AFileName:=GetMessageFile(AChatIdIntOnline,ACianResponseJson.Result.OffersMessagesWebhook.Chats[i].Messages[j].content.files[k]);
                       if AFileName<>EmptyStr
                        then CianDBCore.SetFileToDB(AChatIdIntOnline,AFileName,AConnection);
                      end;
                    end;
                end;
             end;
           end;
         finally
          if Assigned(ACianApiCore)
           then ACianApiCore.Free;
          if Assigned(AStringStream)
           then AStringStream.Free;
          if Assigned(ACianApiCore)
           then
            begin
             AConnection.Connected:=False;
             FreeAndNil(AConnection);
            end;
          CoUnInitialize;
         end;

         TThread.Synchronize(nil,
         procedure
          begin
           WriteLog_C('<-- CIAN. Receiving. Response=['+Trim(AResponse)+']');
           WriteLog_C('<-- CIAN. Receiving. End.');
          end);
        end).Start;
     end;
   {$ENDREGION 'GetMessageFile'}
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianChat.IdHTTPServerCommandGet: ['+E.ClassName+': '+e.Message+']');
     AResponseNo:=500;
     AResponseText:='Internal Server Error';
    end;
  end;
 finally
  AResponseInfo.ContentText:=AResponseText;
  AResponseInfo.ResponseNo:=AResponseNo;
 end;
end;
{$ENDREGION 'IdHTTPServerCommandGet'}

end.
