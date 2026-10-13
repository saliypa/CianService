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
 //curl -X POST -H 'Authorization: Bearer <ACCESS TOKEN>' https://public-api.cian.ru/v1/read-chat?chatId=1
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

    function WebhookTypeToString(AWebhookType:TWebhookTypes):string;
    function OrderByTypeToString(AOrderByType:TOrderByTypes):string;
    function OrderDirTypeToString(AOrderDir:TOrderDirTypes):string;
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
  end;

implementation

uses
  Classes.Common, Vcl.Dialogs, Classes.Logs;

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
 FRESTClient.Free;
 FRESTRequest.Free;
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

function TCianApiCore.GetParseErrors(AResponse:TCustomRESTResponse):string;
var
 AJSONResponse       : TJSONObject;
 sErrorMessage       : string;
 //AError              : TJSONObject;
 //i                   : integer;
begin
 Result:=EmptyStr;
 if (AResponse.StatusCode = 400) or
    (AResponse.StatusCode = 401) or
    (AResponse.StatusCode = 429) or
    (AResponse.StatusCode = 500)
  then
   begin
     AJSONResponse:=TJSONObject.ParseJSONValue(AResponse.Content) as TJSONObject;
     try
      sErrorMessage:=Format('Error: %s - %s', [AJSONResponse.GetValue<string>('operationId'), AJSONResponse.GetValue<string>('result.message')]);
      //Достаточно информации ошибке
      {if AJSONResponse.GetValue<TJSONArray>('result.errors')<>nil
       then
        begin
         sErrorMessage:=sErrorMessage+sLineBreak+'Errors:';
         for i:=0 to AJSONResponse.GetValue<TJSONArray>('result.errors').Count-1 do
          begin
           AError:=AJSONResponse.GetValue<TJSONArray>('result.errors').Items[i] as TJSONObject;
           sErrorMessage:=sErrorMessage+sLineBreak+Format('Code: %s, Key: %s, Message: %s', [AError.GetValue<string>('code'),AError.GetValue<string>('key'),AError.GetValue<string>('message')]);
          end;
        end;}
     finally
      AJSONResponse.Free;
     end;

     Result:=sErrorMessage;
   end
  else
   Result:=Format('Error: %d - %s',[AResponse.StatusCode,AResponse.StatusText]);
end;

function TCianApiCore.SubscribeWebhooks(const AWebhookTypes: array of TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
 AWebhookTypesArray  : TJSONArray;
 AResponseBody       : string;
 i                   : integer;
 AResponse           : TCustomRESTResponse;
begin
 ARequestBody:=TJSONObject.Create;
 AWebhookTypesArray:=TJSONArray.Create;
 try
  try
   ARequestBody.AddPair('url',FWebhooksURL);

   for i:=0 to High(AWebhookTypes) do
    AWebhookTypesArray.Add(WebhookTypeToString(AWebhookTypes[i]));
   ARequestBody.AddPair('webhookTypes',AWebhookTypesArray);

   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmPOST;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('',ARequestBody.ToJSON,TRESTRequestParameterKind.pkREQUESTBODY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('ContentType',CONTENTTYPE_APPLICATION_JSON, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

   FRESTRequest.Resource:=cSubscribeWebhooks;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SubscribeWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
  ARequestBody.Free;
 end;
end;

function TCianApiCore.UnSubscribeWebhooks(const AWebhookType: TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
 AResponseBody       : string;
 AResponse           : TCustomRESTResponse;
begin
 ARequestBody:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('url',FWebhooksURL);
   ARequestBody.AddPair('webhookType',WebhookTypeToString(AWebhookType));

   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmPOST;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('',ARequestBody.ToJSON,TRESTRequestParameterKind.pkREQUESTBODY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('ContentType',CONTENTTYPE_APPLICATION_JSON, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

   FRESTRequest.Resource:=cUnSubscribeWebhooks;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.UnSubscribeWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendTestWebhooks(const AWebhookType: TWebhookTypes):string;
var
 ARequestBody        : TJSONObject;
 AResponseBody       : string;
 AResponse           : TCustomRESTResponse;
begin
 ARequestBody:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('webhookType',WebhookTypeToString(AWebhookType));
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmPOST;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('',ARequestBody.ToJSON,TRESTRequestParameterKind.pkREQUESTBODY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('ContentType',CONTENTTYPE_APPLICATION_JSON, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

   FRESTRequest.Resource:=cSendTestWebhooks;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendTestWebhooks: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendMessage(const AChatId:string; AText:string):string;
var
 ARequestBody        : TJSONObject;
 AContent            : TJSONObject;
 AResponseBody       : string;
 AResponse           : TCustomRESTResponse;
begin
 ARequestBody:=TJSONObject.Create;
 AContent:=TJSONObject.Create;
 try
  try
   ARequestBody.AddPair('chatId',AChatId);
   AContent.AddPair('text',AText);
   ARequestBody.AddPair('content',AContent);

   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmPOST;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('',ARequestBody.ToJSON,TRESTRequestParameterKind.pkREQUESTBODY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('ContentType',CONTENTTYPE_APPLICATION_JSON, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

   FRESTRequest.Resource:=cSendMessage;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendMessage: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
  ARequestBody.Free;
 end;
end;

function TCianApiCore.SendReadChat(const AChatId:string):string;
var
 AResponse           : TCustomRESTResponse;
 AResponseBody       : string;
begin
 try
  try
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmPOST;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('chatId',AChatId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);

   FRESTRequest.Resource:=cSendReadChat;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.SendReadChat: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
 end;
end;

function TCianApiCore.GetChat(const AChatId:string):string;
var
 AResponse            : TCustomRESTResponse;
 AResponseBody        : string;
begin
 try
  try
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmGet;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('chatId',AChatId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);

   FRESTRequest.Resource:=cGetChat;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetChat: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
 end;
end;

function TCianApiCore.GetChats(const APage:string; const APageSize:string; const AOrderBy:TOrderByTypes=obUpdatedAt; const AOrderDir:TOrderDirTypes=odDesc):string;
var
 AResponse            : TCustomRESTResponse;
 AResponseBody        : string;
begin
 try
  try
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmGet;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('page',APage,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('pageSize',APageSize,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('orderBy',OrderByTypeToString(AOrderBy),TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('orderDir',OrderDirTypeToString(AOrderDir),TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);

   FRESTRequest.Resource:=cGetChats;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetChats: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
 end;
end;

function TCianApiCore.GetWebhooksSub:string;
var
 AResponse            : TCustomRESTResponse;
 AResponseBody        : string;
begin
 try
  try
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmGet;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('ContentType',CONTENTTYPE_APPLICATION_JSON, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

   FRESTRequest.Resource:=cGetWebhooksSub;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetWebhooksSub: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
 end;
end;

function TCianApiCore.GetMessages(const AChatId:string; const APage:string; const APageSize:string='100'):string;
var
 AResponse            : TCustomRESTResponse;
 AResponseBody        : string;
begin
 try
  try
   FRESTRequest.Body.ClearBody;

   FRESTRequest.Method:=TRESTRequestMethod.rmGet;
   FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_JSON;
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('page',APage,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('pageSize',APageSize,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);
   FRESTRequest.Params.AddItem('chatId',AChatId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);

   FRESTRequest.Resource:=cGetMessages;
   FRESTRequest.Execute;
   AResponse:=FRESTRequest.Response;

   if AResponse.StatusCode=200
    then
     begin
      AResponseBody:=FRESTRequest.Response.Content;
      exit;
     end;

   AResponseBody:=GetParseErrors(AResponse);

  except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetMessages: ['+E.ClassName+': '+e.Message+']'); end;
 finally
  Result:=AResponseBody;
 end;
end;

function TCianApiCore.GetMessageFile(const AFileId:string):TMemoryStream;
var
 AResponse            : TCustomRESTResponse;
 AMemoryStream        : TMemoryStream;
begin
 Result:=nil;
 try
  FRESTRequest.Body.ClearBody;

  FRESTRequest.Method:=TRESTRequestMethod.rmGet;
  FRESTRequest.Accept:=CONTENTTYPE_APPLICATION_OCTET_STREAM;
  FRESTRequest.Params.Clear;
  FRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
  FRESTRequest.Params.AddItem('fileId',AFileId,TRESTRequestParameterKind.pkQUERY, [poDoNotEncode]);

  FRESTRequest.Resource:=cGetMessageFile;
  FRESTRequest.Execute;
  AResponse:=FRESTRequest.Response;

  if AResponse.StatusCode=200
   then
    begin
     AMemoryStream:=TMemoryStream.Create;
     try
      AMemoryStream.WriteData(AResponse.RawBytes, AResponse.ContentLength);
      AMemoryStream.Position:=0;
     except
      AMemoryStream.Free;
      raise Exception.Create('TMemoryStream.Create');
     end;

     Result:=AMemoryStream;
     exit;
    end;

  raise Exception.Create(GetParseErrors(AResponse));

 except on e:Exception do WriteLog_C('*** Has error in TCianApiCore.GetMessageFile: ['+E.ClassName+': '+e.Message+']'); end;
end;

end.

