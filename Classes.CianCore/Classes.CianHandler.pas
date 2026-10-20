unit Classes.CianHandler;

//Общая логика сервиса и демонстрационного исполняемого файла:
//настройки, подписка на вебхуки, обработка входящих HTTP-запросов

interface

uses
 System.SysUtils, System.Classes, IdCustomHTTPServer;

// Загрузка настроек из ini рядом с исполняемым файлом
function  LoadSettings:boolean;
// Проверка/оформление подписки на вебхуки Циан
function  SetListener:boolean;
// Обработка входящего HTTP-запроса (From=SETL - отправка в Циан, URI c cian - вебхук от Циан)
procedure HandleHTTPRequest(ARequestInfo:TIdHTTPRequestInfo; AResponseInfo:TIdHTTPResponseInfo);

implementation

uses
 System.IniFiles, System.SyncObjs, System.Generics.Collections, Data.Win.ADODB, WinApi.ActiveX,
 Classes.Inc, Classes.Logs, Classes.Common, Classes.DBCore, Classes.CianApiCore, Classes.CianResponseCore;

const
 //Сколько хранить messageId обработанных сообщений и с какого размера чистить
 cProcessedMessagesTTL = 1; //сутки
 cProcessedMessagesMax = 10000;

var
 WebhookLock : TCriticalSection;
 //messageId обработанных сообщений - защита от повторной доставки вебхука.
 //Доступ только из ProcessWebhook, который выполняется под WebhookLock
 ProcessedMessages : TDictionary<string,TDateTime>;

function IsMessageProcessed(const AMessageId:string):boolean;
begin
 Result:=(AMessageId<>EmptyStr) and ProcessedMessages.ContainsKey(AMessageId);
end;

procedure SetMessageProcessed(const AMessageId:string);
var
 AKeys : TArray<string>;
 i     : integer;
begin
 if AMessageId=EmptyStr
  then Exit;

 //Чистим записи старше суток, чтобы словарь не рос бесконечно
 if ProcessedMessages.Count>=cProcessedMessagesMax
  then
   begin
    AKeys:=ProcessedMessages.Keys.ToArray;
    for i:=0 to High(AKeys) do
     if Now-ProcessedMessages[AKeys[i]]>cProcessedMessagesTTL
      then ProcessedMessages.Remove(AKeys[i]);
   end;

 ProcessedMessages.AddOrSetValue(AMessageId,Now);
end;

//Секрет вебхука - отдельный сегмент пути: https://tone.setl.ru/chatcian2/<секрет>/
//Не задан - проверка отключена (при старте в лог пишется предупреждение)
function CheckWebhookSecret(const AURI:string):boolean;
var
 ASegments : TArray<string>;
 i         : integer;
begin
 Result:=sWebhookSecret=EmptyStr;
 if Result
  then Exit;

 ASegments:=AURI.Split(['/','?']);
 for i:=0 to High(ASegments) do
  if SameToken(ASegments[i],sWebhookSecret)
   then Exit(True);
end;

//Секрет вебхука в лог не пишем: он входит в WebhooksURL и в ответы Циан о подписках
function MaskSecret(const AValue:string):string;
begin
 if sWebhookSecret=EmptyStr
  then Result:=AValue
  else Result:=StringReplace(AValue,sWebhookSecret,'***',[rfReplaceAll]);
end;

//Тело вебхука, который не удалось обработать, сохраняется в FailedWebhooks рядом с exe.
//Страховка на случай, если Циан не повторит доставку: такие файлы разбираются вручную
procedure SaveFailedWebhook(const ABody:string);
var
 AFileName : string;
 AStream   : TStringStream;
begin
 try
  ForceDirectories(sFailedWebhooksPath);
  AFileName:=IncludeTrailingPathDelimiter(sFailedWebhooksPath)+FormatDateTime('yyyy-mm-dd_hh-nn-ss-zzz',Now)+'.json';
  AStream:=TStringStream.Create(ABody,TEncoding.UTF8);
  try
   AStream.SaveToFile(AFileName);
  finally
   AStream.Free;
  end;
  WriteLog_C('!!! CIAN. Receiving. Webhook body saved: ['+AFileName+']');
 except on e:Exception do WriteLog_C('*** Has error in SaveFailedWebhook: ['+E.ClassName+': '+e.Message+']'); end;
end;

{$REGION 'LoadSettings'}
function LoadSettings:boolean;
var
 AIniFile  : TMemIniFile;
 AString   : string;
 AMainPath : string;
 AMainEXE  : string;
begin
 //Настройки и лог всегда рядом с исполняемым файлом (и для сервиса, и для демо)
 AMainPath:=ExtractFilePath(ParamStr(0));
 AMainEXE:=ExtractFileName(ParamStr(0));
 sServiceName:=GetServiceName;

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
  //Токен Циан: у каждой службы свой, в её ini. Не задан - служба не работает с Циан
  //(чужой ключ по умолчанию привёл бы к двойной обработке сообщений другого аккаунта)
  sToken:=Trim(AIniFile.ReadString('Parameters', 'Token',EmptyStr));
  //Защитный токен SETL хранится только в ini
  sSetlToken:=Trim(AIniFile.ReadString('Parameters', 'SetlToken',EmptyStr));
  //Секретный сегмент пути вебхука, должен входить в WebhooksURL
  sWebhookSecret:=Trim(AIniFile.ReadString('Parameters', 'WebhookSecret',EmptyStr));
  sFailedWebhooksPath:=AMainPath+cFailedWebhooksPath;
  sDebugMode:=AIniFile.ReadInteger('Parameters', 'DebugMode', 0).ToBoolean;

  sServerName:=AIniFile.ReadString('Parameters', 'ServerName',cServerWork);
  sDBName:=AIniFile.ReadString('Parameters', 'DBName',cDBNameWork);

  sMainDescription:=AIniFile.ReadString('Parameters', 'MainDescription',cMainDescription);

  WriteLog_C(#13#10#13#10);
  //Имя службы = имя exe; допустимы только буквы, цифры и _ (требование TService.Name)
  if not SameText(sServiceName,ChangeFileExt(AMainEXE,EmptyStr))
   then WriteLog_C('!!! Exe name ['+AMainEXE+'] is not a valid service name (letters, digits, _). Service name ['+sServiceName+'] is used');
  if not FileExists(AIniFile.FileName)
   then WriteLog_C('!!! Ini file not found: ['+AIniFile.FileName+']. Default settings are used');
  if sSetlToken=EmptyStr
   then WriteLog_C('!!! SetlToken is not set in ini. Requests From=SETL will be rejected');
  if sWebhookSecret=EmptyStr
   then WriteLog_C('!!! WebhookSecret is not set in ini. Incoming webhooks are accepted without check')
   else
    if not CheckWebhookSecret(sWebhooksURL)
     then WriteLog_C('!!! WebhooksURL does not contain WebhookSecret as a path segment. Cian webhooks will be rejected')
     else
      if Length(sWebhookSecret)<32
       then WriteLog_C('!!! WebhookSecret is too short, use at least 32 characters');
  if sToken=EmptyStr
   then WriteLog_C('!!! Token is not set in ini. Cian is disabled: no webhook subscription, requests From=SETL and webhooks get 503');

  sConnectionString:=Format('Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=True;Data Source=%s;Initial Catalog=%s;Application Name=%s',
                  [UpperCase(sServerName), sDBName, sServiceName]);

  WriteLog_C(Format('#Connecting to DB: %s',[sConnectionString]));

  Result:=True;
 finally
  FreeAndNil(AIniFile);
 end;
end;
{$ENDREGION 'LoadSettings'}

{$REGION 'SetListener'}
function IsErrorResponse(const AResponse:string):boolean;
begin
 Result:=(AResponse=EmptyStr) or (Pos('error',LowerCase(AResponse))>0);
end;

//До 5 попыток, пока ответ пустой или с ошибкой
function CallWithRetry(const AName:string; AFunc:TFunc<string>):string;
var
 AIteration:integer;
begin
 Result:=EmptyStr;
 AIteration:=0;
 while IsErrorResponse(Result) and (AIteration<5) do
  begin
   Inc(AIteration);
   WriteLog_C('--> CIAN. '+AName+'. Iteration #' + AIteration.ToString);
   Result:=AFunc();
   WriteLog_C('<-- CIAN. '+AName+'. Response=['+MaskSecret(Result)+']');
  end;
end;

function SetListener:boolean;
var
 ACianApiCore  : TCianApiCore;
 AResponse     : string;
 AFound        : boolean;
 AWebhookTypes : TArray<TWebhookTypes>;
begin
 Result:=False;
 AFound:=False;
 //Без ключа Циан подписку не проверяем и не оформляем (предупреждение уже в логе старта)
 if sToken=EmptyStr
  then
   begin
    WriteLog_C('!!! CIAN. SetListener skipped: Token is not set');
    Exit(True);
   end;

 WriteLog_C('--> CIAN. SetListener. '+MaskSecret(sWebhooksURL));
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
      AResponse:=CallWithRetry('GetWebhooksSub',
                  function:string
                   begin
                    Result:=ACianApiCore.GetWebhooksSub;
                   end);
      if IsErrorResponse(AResponse)
       then Exit;

      AFound:=FoundValueSubscriptions(AResponse,sWebhooksURL);
     end;

   if sSetUnSubscribe
    then
     begin
      WriteLog_C('--> CIAN. UnSubscribeWebhooks.');
      AResponse:=ACianApiCore.UnSubscribeWebhooks(wtOffersMessages);
      //AResponse:=ACianApiCore.UnSubscribeWebhooks(wtSystemMessages);
      //AResponse:=ACianApiCore.UnSubscribeWebhooks(wtChatsReadability);
      WriteLog_C('<-- CIAN. UnSubscribeWebhooks. Response=['+MaskSecret(AResponse)+']');
      Result:=not IsErrorResponse(AResponse);
      Exit;
     end;

   if (sSetSubscribe) and
       (not AFound)
    then
     begin
      AResponse:=CallWithRetry('SubscribeWebhooks',
                  function:string
                   begin
                    Result:=ACianApiCore.SubscribeWebhooks(AWebhookTypes);
                   end);
      if IsErrorResponse(AResponse)
       then Exit;

      AResponse:=CallWithRetry('GetWebhooksSub',
                  function:string
                   begin
                    Result:=ACianApiCore.GetWebhooksSub;
                   end);
      if IsErrorResponse(AResponse)
       then Exit;
     end;

   Result:=True;
  except on e:Exception do WriteLog_C('*** Has error in SetListener: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ACianApiCore.Free;
 end;
end;
{$ENDREGION 'SetListener'}

{$REGION 'GetMessageFile'}
function GetMessageFile(ACianApiCore:TCianApiCore; AChatId:string; AFile:TFile):string;
var
 AFilePath:string;
 AFileStream:TFileStream;
 AMemoryStream:TMemoryStream;
begin
 Result:=EmptyStr;
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

  //Имя файла приходит извне - убираем путь и недопустимые символы
  AFilePath:=AFilePath+SafeFileName(AFile.fileId+AFile.name);

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
 except on e:Exception do WriteLog_C('*** Has error in GetMessageFile: ['+E.ClassName+': '+e.Message+']'); end;
end;
{$ENDREGION 'GetMessageFile'}

{$REGION 'ProcessWebhook'}
function GetUserName(AUser:TUser):string;
begin
 Result:=EmptyStr;
 if Assigned(AUser)
  then Result:=AUser.firstName+' '+AUser.lastName+' '+AUser.name;
end;

//Обработка вебхука Циан. Результат - HTTP-код ответа Циан:
// 200 - обработан (или обрабатывать нечего);
// 400 - некорректный JSON, повтор не поможет;
// 500 - не все сообщения сохранены: Циан повторит доставку, уже обработанные отсеются по messageId
function ProcessWebhook(const ABody:string):integer;
var
 ACianApiCore      : TCianApiCore;
 AResponse         : string;
 AConnection       : TADOConnection;
 AChatIdIntOff     : string;
 AChatIdInt        : string;
 i                 : integer;
 j                 : integer;
 k                 : integer;
 ACianResponseJson : TCianResponseJson;
 AWebhook          : TOffersMessagesWebhook;
 AChat             : TChat;
 AMessage          : TMessage;
 AChatId           : string;
 AUserName         : string;
 AOfferUrl         : string;
 AOffer            : TOfferDetails;
 ASessionId        : string;
 AResultAdvOper    : TResultAdv;
 AResultAdvNew     : TResultAdv;
 AOperatorId       : string;
 AOperatorAllow    : boolean;
 ADecription       : string;
 AText             : string;
 AFiles            : TArray<TFile>;
 AFileName         : string;
begin
 Result:=200;
 AResponse:=EmptyStr;
 ACianApiCore:=nil;
 AConnection:=nil;
 ACianResponseJson:=nil;
 CoInitialize(nil);
 try
  try
   try
    ACianResponseJson:=ParseCianResponseJson(ABody);
   except on e:Exception do
     begin
      WriteLog_C('*** CIAN. Receiving. Invalid request: ['+E.ClassName+': '+e.Message+']');
      Result:=400;
      Exit;
     end;
   end;

   if (not Assigned(ACianResponseJson.Result)) or
      (not Assigned(ACianResponseJson.Result.offersMessagesWebhook))
    then
     begin
      AResponse:='No offersMessagesWebhook in request, skipped';
      Exit;
     end;
   AWebhook:=ACianResponseJson.Result.offersMessagesWebhook;

   ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
   AConnection:=TADOConnection.Create(nil);
   AConnection.ConnectionString:=sConnectionString;
   AConnection.LoginPrompt:=False;
   AConnection.Connected:=True;

   for i:=0 to High(AWebhook.chats) do
    begin
     AChat:=AWebhook.chats[i];
     AChatId:=AChat.chatId.ToString;
     //Ошибка в одном чате не останавливает остальные. Следующие сообщения этого чата
     //не обрабатываются, чтобы при повторной доставке сохранился их порядок
     try
      ASessionId:=CianDBCore.SetUserSession(AChatId,cMainURL,sMainDescription,AConnection);
      if ASessionId=EmptyStr
       then raise Exception.Create('Client session is not created');

      AOffer:=FindOfferByOfferId(AWebhook,AChat.offerId);
      if Assigned(AOffer)
       then AOfferUrl:=AOffer.url
       else AOfferUrl:=EmptyStr;

      for j:=0 to High(AChat.messages) do
       begin
        AMessage:=AChat.messages[j];

        //Только входящие от клиента: при подписке на *Outgoing Циан присылает и наши же сообщения
        if (AMessage.direction<>EmptyStr) and
           (not SameText(AMessage.direction,'in'))
         then
          begin
           WriteLog_C('<-- CIAN. Receiving. Skipped outgoing message. ChatId='+AChatId+' MessageId='+AMessage.messageId);
           Continue;
          end;

        //Повторная доставка того же сообщения
        if IsMessageProcessed(AMessage.messageId)
         then
          begin
           WriteLog_C('<-- CIAN. Receiving. Skipped duplicate message. ChatId='+AChatId+' MessageId='+AMessage.messageId);
           Continue;
          end;

        if Assigned(AMessage.content)
         then
          begin
           AText:=AMessage.content.text;
           AFiles:=AMessage.content.files;
          end
         else
          begin
           AText:=EmptyStr;
           AFiles:=nil;
          end;

        //ResultType<0 без исключения - клиент неизвестен или забанен (ошибка БД - исключение)
        AResultAdvOper:=CianDBCore.GetFreeOperator(AChatId,sMainDescription,AConnection);
        if AResultAdvOper.ResultType>0
         then
          begin
           ADecription:=AResultAdvOper.ResultValue[0];
           AOperatorAllow:=StrToBoolDef(AResultAdvOper.ResultValue[1],False);
           AOperatorId:=AResultAdvOper.ResultValue[2];
          end
         else
          begin
           ADecription:=EmptyStr;
           AOperatorAllow:=False;
           AOperatorId:=EmptyStr;
          end;

        AUserName:=GetUserName(FindUserByUserId(AWebhook,AMessage.userId));

        //Ошибка отправки автоответа не повод для повторной доставки: сообщение клиента уже сохранено
        if not AOperatorAllow
         then
          begin  //сообщения от бота
           AChatIdIntOff:=CianDBCore.SetOfflineMess(cMainURL,AUserName,ASessionId,AConnection);

           if CianDBCore.UpdOfflineMess(AChatIdIntOff,ADecription,AConnection) and
              (ADecription<>EmptyStr)
            then
             begin
              AResponse:=AResponse+ACianApiCore.SendMessage(AChatId,ADecription);
              AResponse:=AResponse+'#'+(j+1).ToString+'; ';
              if ACianApiCore.LastStatusCode<>200
               then WriteLog_C('*** CIAN. Receiving. Bot message is not sent. ChatId='+AChatId);
             end;
          end
         else
          begin
           AResultAdvNew:=CianDBCore.SetNewChat(ASessionId,AOperatorId,
                                      AOfferUrl,
                                      sMainDescription,
                                      AUserName,
                                      AText + iif(Length(AFiles)>0,Format(' Прикрепленный файл %d шт.',[Length(AFiles)]),EmptyStr),
                                      AConnection);
           if AResultAdvNew.ResultType<0
            then raise Exception.Create('Chat is not created. OperatorId='+AOperatorId);

           //Создан новый чат. Автоответ может быть пустым (VF_SetlTone_GetAutoAnswer_Cian вернёт NULL, если оператора нет в Attr6).
           //При повторной доставке чат уже не новый, поэтому автоответ не уйдёт дважды
           if (AResultAdvNew.ResultType=0) and
              (ADecription<>EmptyStr)
            then
             begin
              AResponse:=AResponse+ACianApiCore.SendMessage(AChatId,ADecription);
              AResponse:=AResponse+'#'+(j+1).ToString+'; ';
              if ACianApiCore.LastStatusCode<>200
               then WriteLog_C('*** CIAN. Receiving. Auto answer is not sent. ChatId='+AChatId);
             end;

           //Вложения сохраняем и для нового, и для продолженного чата.
           //При повторной доставке VF_SetlTone_newChat_Cian не задублирует текст, а файлы скачаются заново
           AChatIdInt:=AResultAdvNew.ResultValue[0];
           for k:=0 to High(AFiles) do
            begin
             AFileName:=GetMessageFile(ACianApiCore,AChatIdInt,AFiles[k]);
             if AFileName=EmptyStr
              then raise Exception.Create('File is not saved. FileId='+AFiles[k].fileId);
             CianDBCore.SetFileToDB(AChatIdInt,AFileName,AConnection);
            end;
          end;

        SetMessageProcessed(AMessage.messageId);
       end;
     except on e:Exception do
       begin
        WriteLog_C('*** CIAN. Receiving. Chat is not processed, waiting for redelivery. ChatId='+AChatId+' ['+E.ClassName+': '+e.Message+']');
        Result:=500;
       end;
     end;
    end;
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in ProcessWebhook: ['+E.ClassName+': '+e.Message+']');
     Result:=500;
    end;
  end;
 finally
  ACianResponseJson.Free;
  ACianApiCore.Free;
  if Assigned(AConnection)
   then
    begin
     try AConnection.Connected:=False; except end;
     AConnection.Free;
    end;
  CoUnInitialize;
  WriteLog_C('<-- CIAN. Receiving. Response=['+Trim(AResponse)+']');
  WriteLog_C('<-- CIAN. Receiving. End. HTTP '+Result.ToString);
 end;
end;
{$ENDREGION 'ProcessWebhook'}

{$REGION 'ProcessSend'}
//Отправка сообщения из ИК в Циан. Результат - HTTP-код ответа ИК:
// 200 - Циан принял сообщение; 502 - Циан вернул ошибку или недоступен (текст в AError)
function ProcessSend(const AChatId, AMessage:string; out AError:string):integer;
var
 ACianApiCore  : TCianApiCore;
 AResponse     : string;
begin
 Result:=502;
 AError:=EmptyStr;
 AResponse:=EmptyStr;
 try
  ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
  try
   AResponse:=ACianApiCore.SendMessage(AChatId,AMessage);
   if ACianApiCore.LastStatusCode=200
    then Result:=200
    else
     if AResponse<>EmptyStr
      then AError:=AResponse
      else AError:='Cian API is not available';
  finally
   ACianApiCore.Free;
  end;
 except on e:Exception do
   begin
    WriteLog_C('*** Has error in ProcessSend: ['+E.ClassName+': '+e.Message+']');
    AError:=e.Message;
   end;
 end;
 WriteLog_C('<-- CIAN. Send. Response=['+AResponse+']');
 WriteLog_C('<-- CIAN. Send. End.');
end;
{$ENDREGION 'ProcessSend'}

{$REGION 'HandleHTTPRequest'}
//Проверка защитного токена SETL: заголовок X-Setl-Token или параметр SetlToken
function CheckSetlToken(ARequestInfo:TIdHTTPRequestInfo):boolean;
var
 AToken:string;
begin
 AToken:=ARequestInfo.RawHeaders.Values[cSetlTokenHeader];
 if AToken=EmptyStr
  then AToken:=ARequestInfo.Params.Values[cSetlTokenParam];
 Result:=SameToken(Trim(AToken),sSetlToken);
end;

procedure HandleHTTPRequest(ARequestInfo:TIdHTTPRequestInfo; AResponseInfo:TIdHTTPResponseInfo);
var
 AResponseNo    : integer;
 AResponseText  : string;
 AParamsLog     : TStringList;
 AChatId        : string;
 AMessage       : string;
 AError         : string;
 ABody          : string;
 AStringStream  : TStringStream;
 i              : integer;
begin
 AResponseNo:=200;
 AResponseText:='OK';
 ABody:=EmptyStr;
 try
  try
   {$REGION 'cSendParam'}
   //Именно параметр From=SETL, а не подстрока где-либо в параметрах (например, в тексте сообщения)
   if (ARequestInfo.CommandType=hcPOST) and
      SameText(ARequestInfo.Params.Values[cSendParam],cSendValue)
    then
     begin
      if not CheckSetlToken(ARequestInfo)
       then
        begin
         WriteLog_C('*** CIAN. Send. Rejected: invalid SetlToken. RemoteIP='+ARequestInfo.RemoteIP);
         AResponseNo:=403;
         AResponseText:='Forbidden';
         Exit;
        end;

      //Токен в лог не пишем
      AParamsLog:=TStringList.Create;
      try
       AParamsLog.Assign(ARequestInfo.Params);
       i:=AParamsLog.IndexOfName(cSetlTokenParam);
       if i>=0
        then AParamsLog.Delete(i);
       WriteLog_C('--> CIAN. Send. Start');
       WriteLog_C('--> CIAN. Send. Params=['+Trim(StringReplace(AParamsLog.Text,#13#10,'; ',[rfReplaceAll]))+']');
      finally
       AParamsLog.Free;
      end;

      AChatId:=ARequestInfo.Params.Values['ChatId'];
      AMessage:=StringReplace(ARequestInfo.Params.Values['Message'], '\n', Chr(10), [rfReplaceAll]);
      //chatId в API Циан - int64
      if StrToInt64Def(AChatId,0)<=0
       then
        begin
         WriteLog_C('*** CIAN. Send. Rejected: invalid ChatId ['+AChatId+']');
         AResponseNo:=400;
         AResponseText:='Bad Request';
         Exit;
        end;

      if sToken=EmptyStr
       then
        begin
         WriteLog_C('*** CIAN. Send. Rejected: Token is not set');
         AResponseNo:=503;
         AResponseText:='Service Unavailable: Cian Token is not set';
         Exit;
        end;

      //Отправляем до ответа: ИК получает фактический результат отправки в Циан
      AResponseNo:=ProcessSend(AChatId,AMessage,AError);
      if AResponseNo<>200
       then AResponseText:='Bad Gateway: '+AError;

      Exit;
     end;
   {$ENDREGION 'cSendParam'}

   {$REGION 'cRespCmd'}
   if (ARequestInfo.CommandType=hcPOST) and
      (Pos(cRespCmd,LowerCase(ARequestInfo.URI))>0)
    then
     begin
      //Вебхуки принимаются только на адрес с секретным сегментом, на который подписан Циан
      if not CheckWebhookSecret(ARequestInfo.URI)
       then
        begin
         WriteLog_C('*** CIAN. Receiving. Rejected: invalid webhook secret. RemoteIP='+ARequestInfo.RemoteIP);
         AResponseNo:=404;
         AResponseText:='Not Found';
         Exit;
        end;

      //Без ключа не скачать вложения и не отправить автоответ: 503, Циан повторит доставку
      if sToken=EmptyStr
       then
        begin
         WriteLog_C('*** CIAN. Receiving. Rejected: Token is not set');
         AResponseNo:=503;
         AResponseText:='Service Unavailable';
         Exit;
        end;

      WriteLog_C('--> CIAN. Receiving. Start');

      if not Assigned(ARequestInfo.PostStream)
       then
        begin
         AResponseNo:=400;
         AResponseText:='Bad Request';
         Exit;
        end;

      AStringStream:=TStringStream.Create('',TEncoding.UTF8);
      try
       AStringStream.LoadFromStream(ARequestInfo.PostStream);
       ABody:=AStringStream.DataString;
      finally
       AStringStream.Free;
      end;

      //Обрабатываем до ответа: если сообщение не сохранено, Циан получит 500 и повторит доставку.
      //Вебхуки обрабатываются по одному: так согласованы автоответ и учёт обработанных messageId
      WebhookLock.Enter;
      try
       AResponseNo:=ProcessWebhook(ABody);
      finally
       WebhookLock.Leave;
      end;

      case AResponseNo of
       400 : AResponseText:='Bad Request';
       500 : AResponseText:='Internal Server Error';
      end;
     end;
   {$ENDREGION 'cRespCmd'}
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in HandleHTTPRequest: ['+E.ClassName+': '+e.Message+']');
     AResponseNo:=500;
     AResponseText:='Internal Server Error';
    end;
  end;
 finally
  //Вебхук не обработан - сохраняем тело на случай, если Циан не повторит доставку
  if (AResponseNo=500) and
     (ABody<>EmptyStr)
   then SaveFailedWebhook(ABody);

  AResponseInfo.ContentType:='text/plain';
  AResponseInfo.CharSet:='utf-8';
  AResponseInfo.ContentText:=AResponseText;
  AResponseInfo.ResponseNo:=AResponseNo;
 end;
end;
{$ENDREGION 'HandleHTTPRequest'}

initialization
 WebhookLock:=TCriticalSection.Create;
 ProcessedMessages:=TDictionary<string,TDateTime>.Create;

finalization
 ProcessedMessages.Free;
 WebhookLock.Free;

end.
