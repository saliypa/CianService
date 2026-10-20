unit Classes.CianApiCore;

interface

uses
 System.SysUtils, System.JSON, System.Generics.Collections, System.Classes, REST.Client, REST.Types;


const
 cMainDescription      = 'public-api.cian.ru';
 cMainURL              = 'https://public-api.cian.ru/';
 cSubscribeWebhooks    = 'v2/subscribe-webhooks';
 cUnSubscribeWebhooks  = 'v2/unsubscribe-webhooks';
 cSendTestWebhooks     = 'v1/send-test-webhook';
 cSendMessage          = 'v1/send-message';
 cSendReadChat         = 'v1/read-chat';
 cGetChat              = 'v1/get-chat';
 cGetChats             = 'v1/get-chats';
 cGetMessages          = 'v1/get-messages';
 cGetMessageFile       = 'v1/get-message-file';
 cGetWebhooksSub       = 'v1/get-webhooks-subscriptions';


 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v2/unsubscribe-webhooks --header 'Content-Type: application/json' --data-raw '{"url": "https://example.com", "webhookType": "offersMessages"}'
 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v2/subscribe-webhooks --header 'Content-Type: application/json' --data-raw '{"url": "https://example.com", "webhookTypes": ["offersMessagesIncoming"]}'
 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/send-test-webhook --header 'Content-Type: application/json' --data-raw '{"webhookType": "offersMessages"}'
 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/send-message --header 'Content-Type: application/json' --data-raw '{"chatId": 1, "content": {"text": "Это тестовое сообщение"}}'
 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/read-chat --header 'Content-Type: application/json' --data-raw '{"chatId": 1}'
 //curl -X GET -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/get-chat?chatId=1
 //curl -X GET -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/get-chats?page=1&pageSize=100&orderBy=chatId
 //curl -X GET -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/get-messages?page=1&pageSize=100&chatId=1
 //curl -X GET -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/get-message-file?fileId=d5c09995-5677-4303-923e-401182574cc5
 //curl -X GET -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/get-webhooks-subscriptions --header 'Content-Type: application/json'
type
 TWebhookTypes = (wtChatsReadability, wtOffersMessagesApiOutgoing, wtOffersMessagesIncoming, wtOffersMessagesLkOutgoing, wtSystemMessages, wtOffersMessages);

type
 TOrderByTypes = (obChatId, obCreatedAt, obUpdatedAt);

type
 TOrderDirTypes = (odAsc, odDesc);

type
  TCianApiCore = class
  private
    { Private declarations }
    FRESTClient:TRESTClient;
    FRESTRequest:TRESTRequest;

    FToken       : string;
    FMainURL     : string;
    FWebhooksURL : string;
    FLastStatusCode : integer;

    function WebhookTypeToString(AWebhookType:TWebhookTypes):string;
    function OrderByTypeToString(AOrderByType:TOrderByTypes):string;
    function OrderDirTypeToString(AOrderDir:TOrderDirTypes):string;
    procedure PrepareRequest(AMethod:TRESTRequestMethod; const AResource:string; const AAccept:string=CONTENTTYPE_APPLICATION_JSON);
    function  ExecuteRequest:string;
  public
    { Public declarations }
    constructor Create(const AToken:string; const AWebhooksURL:string=''; const AMainURL:string='');
    destructor Destroy; override;

    function  GetParseErrors(AResponse:TCustomRESTResponse):string;
    function  SubscribeWebhooks(const AWebhookTypes: array of TWebhookTypes):string;
    function  UnSubscribeWebhooks(const AWebhookType: TWebhookTypes):string;
    function  SendTestWebhooks(const AWebhookType: TWebhookTypes):string;
    function  SendMessage(const AChatId:string; AText:string):string;
    function  SendReadChat(const AChatId:string):string;
    function  GetWebhooksSub:string;
    function  GetChat(const AChatId:string):string;
    function  GetChats(const APage:string; const APageSize:string; const AOrderBy:TOrderByTypes=obUpdatedAt; const AOrderDir:TOrderDirTypes=odDesc):string;
    function  GetMessages(const AChatId:string; const APage:string; const APageSize:string='100'):string;
    function  GetMessageFile(const AFileId:string):TMemoryStream;

    //HTTP-код последнего запроса (0 - запрос не выполнен: сеть, исключение)
    property  LastStatusCode:integer read FLastStatusCode;
  end;

implementation

uses
  Classes.Common, Classes.Logs;

{ TCianApiCore }

constructor TCianApiCore.Create(const AToken:string; const AWebhooksURL:string=''; const AMainURL:string='');
begin
 FRESTClient:=TRESTClient.Create(nil);
 FRESTRequest:=TRESTRequest.Create(nil);
 FRESTRequest.Client:=FRESTClient;
 FRESTClient.AcceptEncoding:='utf-8';
 FRESTRequest.AcceptEncoding:='utf-8';

 FToken:=AToken;
 FMainURL:=iif(AMainURL=EmptyStr,cMainURL,AMainURL);
 FWebhooksURL:=AWebhooksURL;

 FRESTClient.BaseURL:=FMainURL;
end;

destructor TCianApiCore.Destroy;
begin
 FRESTRequest.Free;
 FRESTClient.Free;
 inherited;
end;

function TCianApiCore.WebhookTypeToString(AWebhookType: TWebhookTypes):string;
begin
 case AWebhookType of
  wtChatsReadability          : Result:= 'chatsReadability';
  wtOffersMessagesApiOutgoing : Result:= 'offersMessagesApiOutgoing';
  wtOffersMessagesIncoming    : Result:= 'offersMessagesIncoming';
  wtOffersMessagesLkOutgoing  : Result:= 'offersMessagesLkOutgoing';
  wtSystemMessages            : Result:= 'systemMessages';
  wtOffersMessages            : Result:= 'offersMessages';
  else                          Result:= EmptyStr;
 end;
end;

function TCianApiCore.OrderByTypeToString(AOrderByType:TOrderByTypes):string;
begin
 case AOrderByType of
  obChatId                    : Result:= 'chatId';
  obCreatedAt                 : Result:= 'createdAt';
  obUpdatedAt                 : Result:= 'updatedAt';
  else                          Result:= 'updatedAt';
 end;
end;

function TCianApiCore.OrderDirTypeToString(AOrderDir:TOrderDirTypes):string;
begin
 case AOrderDir of
  odAsc                       : Result:= 'asc';
  odDesc                      : Result:= 'desc';
  else                          Result:= 'desc';
 end;
end;

//Сброс параметров предыдущего запроса и подготовка нового
procedure TCianApiCore.PrepareRequest(AMethod:TRESTRequestMethod; const AResource:string; const AAccept:string=CONTENTTYPE_APPLICATION_JSON);
begin
 FLastStatusCode:=0;
 FRESTRequest.Params.Clear;
 FRESTRequest.Body.ClearBody;
 FRESTRequest.Method:=AMethod;
 FRESTRequest.Accept:=AAccept;
 FRESTRequest.Resource:=AResource;
 FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
end;

//Выполнение запроса: тело ответа при 200, иначе текст ошибки (содержит 'Error')
function TCianApiCore.ExecuteRequest:string;
begin
 FRESTRequest.Execute;
 FLastStatusCode:=FRESTRequest.Response.StatusCode;
 if FRESTRequest.Response.StatusCode=200
  then Result:=FRESTRequest.Response.Content
  else Result:=GetParseErrors(FRESTRequest.Response);
end;

function TCianApiCore.GetParseErrors(AResponse:TCustomRESTResponse):string;
var
 AJSONValue   : TJSONValue;
 AOperationId : string;
 AMessage     : string;
begin
 Result:=Format('Error: %d - %s',[AResponse.StatusCode,AResponse.StatusText]);
 //Тело ошибки может быть не JSON (прокси, 502 и т.п.)
 AJSONValue:=TJSONObject.ParseJSONValue(AResponse.Content);
 try
  if AJSONValue is TJSONObject
   then
    begin
     AOperationId:=AJSONValue.GetValue<string>('operationId',EmptyStr);
     AMessage:=AJSONValue.GetValue<string>('result.message',EmptyStr);
     if AMessage<>EmptyStr
      then Result:=Format('Error: %d - %s - %s',[AResponse.StatusCode,AOperationId,AMessage]);
    end;
 finally
  AJSONValue.Free;
 end;
end;

function TCianApiCore.SubscribeWebhooks(const AWebhookTypes: array of TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
 AWebhookTypesArray  : TJSONArray;
 i                   : integer;
begin
 Result:=EmptyStr;
 ARequestBody:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('url',FWebhooksURL);
   AWebhookTypesArray:=TJSONArray.Create;
   ARequestBody.AddPair('webhookTypes',AWebhookTypesArray);
   for i:=0 to High(AWebhookTypes) do
    AWebhookTypesArray.Add(WebhookTypeToString(AWebhookTypes[i]));

   PrepareRequest(TRESTRequestMethod.rmPOST,cSubscribeWebhooks);
   FRESTRequest.AddBody(ARequestBody.ToJSON,ctAPPLICATION_JSON);
   Result:=ExecuteRequest;
  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SubscribeWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ARequestBody.Free;
 end;
end;

function TCianApiCore.UnSubscribeWebhooks(const AWebhookType: TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
begin
 Result:=EmptyStr;
 ARequestBody:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('url',FWebhooksURL);
   ARequestBody.AddPair('webhookType',WebhookTypeToString(AWebhookType));

   PrepareRequest(TRESTRequestMethod.rmPOST,cUnSubscribeWebhooks);
   FRESTRequest.AddBody(ARequestBody.ToJSON,ctAPPLICATION_JSON);
   Result:=ExecuteRequest;
  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.UnSubscribeWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendTestWebhooks(const AWebhookType: TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
begin
 Result:=EmptyStr;
 ARequestBody:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('webhookType',WebhookTypeToString(AWebhookType));

   PrepareRequest(TRESTRequestMethod.rmPOST,cSendTestWebhooks);
   FRESTRequest.AddBody(ARequestBody.ToJSON,ctAPPLICATION_JSON);
   Result:=ExecuteRequest;
  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendTestWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendMessage(const AChatId:string; AText:string):string;
var
 ARequestBody        : TJSONObject;
 AContent            : TJSONObject;
begin
 Result:=EmptyStr;
 ARequestBody:=TJSONObject.Create;
 try
  try
   //По схеме API chatId - int64, передаём числом
   ARequestBody.AddPair('chatId',TJSONNumber.Create(StrToInt64(AChatId)));
   AContent:=TJSONObject.Create;
   ARequestBody.AddPair('content',AContent);
   AContent.AddPair('text',AText);

   PrepareRequest(TRESTRequestMethod.rmPOST,cSendMessage);
   FRESTRequest.AddBody(ARequestBody.ToJSON,ctAPPLICATION_JSON);
   Result:=ExecuteRequest;
  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendMessage: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendReadChat(const AChatId:string):string;
var
 ARequestBody        : TJSONObject;
begin
 Result:=EmptyStr;
 ARequestBody:=TJSONObject.Create;
 try
  try
   //По схеме API chatId передаётся в JSON-теле числом (query-параметров у метода нет)
   ARequestBody.AddPair('chatId',TJSONNumber.Create(StrToInt64(AChatId)));

   PrepareRequest(TRESTRequestMethod.rmPOST,cSendReadChat);
   FRESTRequest.AddBody(ARequestBody.ToJSON,ctAPPLICATION_JSON);
   Result:=ExecuteRequest;
  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendReadChat: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  ARequestBody.Free;
 end;
end;

function TCianApiCore.GetChat(const AChatId:string):string;
begin
 Result:=EmptyStr;
 try
  PrepareRequest(TRESTRequestMethod.rmGET,cGetChat);
  FRESTRequest.Params.AddItem('chatId',AChatId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  Result:=ExecuteRequest;
 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetChat: ['+E.ClassName+': '+e.Message+']'); end;
end;

function TCianApiCore.GetChats(const APage:string; const APageSize:string; const AOrderBy:TOrderByTypes=obUpdatedAt; const AOrderDir:TOrderDirTypes=odDesc):string;
begin
 Result:=EmptyStr;
 try
  PrepareRequest(TRESTRequestMethod.rmGET,cGetChats);
  FRESTRequest.Params.AddItem('page',APage,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('pageSize',APageSize,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('orderBy',OrderByTypeToString(AOrderBy),TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('orderDir',OrderDirTypeToString(AOrderDir),TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  Result:=ExecuteRequest;
 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetChats: ['+E.ClassName+': '+e.Message+']'); end;
end;

function TCianApiCore.GetWebhooksSub:string;
begin
 Result:=EmptyStr;
 try
  PrepareRequest(TRESTRequestMethod.rmGET,cGetWebhooksSub);
  Result:=ExecuteRequest;
 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetWebhooksSub: ['+E.ClassName+': '+e.Message+']'); end;
end;

function TCianApiCore.GetMessages(const AChatId:string; const APage:string; const APageSize:string='100'):string;
begin
 Result:=EmptyStr;
 try
  PrepareRequest(TRESTRequestMethod.rmGET,cGetMessages);
  FRESTRequest.Params.AddItem('page',APage,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('pageSize',APageSize,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('chatId',AChatId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  Result:=ExecuteRequest;
 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetMessages: ['+E.ClassName+': '+e.Message+']'); end;
end;

function TCianApiCore.GetMessageFile(const AFileId:string):TMemoryStream;
var
 AResponse            : TCustomRESTResponse;
 AMemoryStream        : TMemoryStream;
begin
 Result:=nil;
 try
  PrepareRequest(TRESTRequestMethod.rmGET,cGetMessageFile,CONTENTTYPE_APPLICATION_OCTET_STREAM);
  FRESTRequest.Params.AddItem('fileId',AFileId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
  FRESTRequest.Execute;
  AResponse:=FRESTRequest.Response;
  FLastStatusCode:=AResponse.StatusCode;

  if AResponse.StatusCode<>200
   then raise Exception.Create(GetParseErrors(AResponse));

  AMemoryStream:=TMemoryStream.Create;
  try
   //ContentLength не заполняется при chunked-ответе, берём фактический размер
   if Length(AResponse.RawBytes)>0
    then AMemoryStream.WriteData(AResponse.RawBytes, Length(AResponse.RawBytes));
   AMemoryStream.Position:=0;
  except
   AMemoryStream.Free;
   raise;
  end;
  Result:=AMemoryStream;
 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetMessageFile: ['+E.ClassName+': '+e.Message+']'); end;
end;

end.
