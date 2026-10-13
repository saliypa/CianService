unit Classes.CianResponseCore;

interface

uses
  System.JSON, System.SysUtils, System.Classes, System.DateUtils, System.Generics.Collections,
  Classes.Common, System.ioUtils;

{$REGION 'CianResponseJson'}
type
 TJSONObjectHelper = class helper for TJSONObject
  function Contains(const Key: string):boolean;
 end;

type
  TFile = class
    fileId: string;
    mimeType: string;
    name: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TOffer = class
    formattedAddress: string;
    formattedInfo: string;
    formattedPrice: string;
    photoUrls: TArray<string>;
    realtyOfferId: string;
    url: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TContent = class
    files: TArray<TFile>;
    offers: TArray<TOffer>;
    text: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TMessage = class
    content: TContent;
    createdAt: string;
    direction: string;
    messageId: string;
    userId: Integer;
    constructor Create(AJson: TJSONObject);
  end;

type
  TChat = class
    agentUserId: Integer;
    chatId: Integer;
    readAt: string;
    userId: Integer;
    createdAt: string;
    messages: TArray<TMessage>;
    offerId: Integer;
    updatedAt: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TImages = class
    big: string;
    small: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TAvatar = class
    images: TImages;
    constructor Create(AJson: TJSONObject);
  end;

type
  TUser = class
    avatar: TAvatar;
    firstName: string;
    lastName: string;
    name: string;
    userId: Integer;
    constructor Create(AJson: TJSONObject);
  end;

type
  TChatsReadabilityWebhook = class
    chats: TArray<TChat>;
    users: TArray<TUser>;
    webhookType: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TMainPhoto = class
    miniUrl: string;
    url: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TOfferDetails = class
    address: string;
    externalId: string;
    id: Integer;
    mainPhoto: TMainPhoto;
    price: string;
    publishedUserId: Integer;
    title: string;
    url: string;
    userId: Integer;
    constructor Create(AJson: TJSONObject);
  end;

type
  TOffersMessagesWebhook = class
    chats: TArray<TChat>;
    offers: TArray<TOfferDetails>;
    users: TArray<TUser>;
    webhookType: string;
    userDict:TDictionary<integer,TUser>;
    offerDict:TDictionary<integer,TOfferDetails>;
    constructor Create(AJson: TJSONObject);
  end;

type
  TActionButton = class
    link: string;
    text: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TSystemContent = class
    actionButtons: TArray<TActionButton>;
    files: TArray<TFile>;
    htmlText: string;
    text: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TSystemMessage = class
    content: TSystemContent;
    createdAt: string;
    direction: string;
    messageId: string;
    userId: Integer;
    constructor Create(AJson: TJSONObject);
  end;

type
  TSystemMessagesWebhook = class
    chats: TArray<TChat>;
    users: TArray<TUser>;
    webhookType: string;
    constructor Create(AJson: TJSONObject);
  end;

type
  TResult = class
    chatsReadabilityWebhook: TChatsReadabilityWebhook;
    offersMessagesWebhook: TOffersMessagesWebhook;
    systemMessagesWebhook: TSystemMessagesWebhook;
    constructor Create(AJson: TJSONObject);
  end;

type
  TCianResponseJson = class
    OperationId: string;
    Result: TResult;
    constructor Create(AJson: TJSONObject);
  end;
{$ENDREGION 'CianResponseJson'}

function ParseCianResponseJson(const JsonStr:string):TCianResponseJson;
function FindUserByUserId(AOffersMessagesWebhook:TOffersMessagesWebhook; AUserId:integer):TUser;
function FindOfferByOfferId(AOffersMessagesWebhook:TOffersMessagesWebhook; AOfferId:integer):TOfferDetails;


function FoundValueSubscriptions(const JsonStr:string; AValue:string):boolean;

implementation

{$REGION 'CianResponseJson'}
{ TFile }

constructor TFile.Create(AJson: TJSONObject);
begin
 if AJson.Contains('fileId')
  then fileId:=AJson.GetValue<string>('fileId');
 if AJson.Contains('mimeType')
  then mimeType:=AJson.GetValue<string>('mimeType');
 if AJson.Contains('name')
  then name:=AJson.GetValue<string>('name');
end;

{ TOffer }

constructor TOffer.Create(AJson: TJSONObject);
begin
 if AJson.Contains('formattedAddress')
  then formattedAddress:=AJson.GetValue<string>('formattedAddress');
 if AJson.Contains('formattedInfo')
  then formattedInfo:=AJson.GetValue<string>('formattedInfo');
 if AJson.Contains('formattedPrice')
  then formattedPrice:=AJson.GetValue<string>('formattedPrice');
 if AJson.Contains('photoUrls')
  then photoUrls:=AJson.GetValue<TJSONArray>('photoUrls').AsType<TArray<string>>;
 if AJson.Contains('realtyOfferId')
  then realtyOfferId:=AJson.GetValue<string>('realtyOfferId');
 if AJson.Contains('url')
  then url:=AJson.GetValue<string>('url');
end;

{ TContent }

constructor TContent.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('files')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('files');
    SetLength(files, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
     files[i]:=TFile.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('offers')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('offers');
    SetLength(offers, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
      offers[i]:=TOffer.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('text')
  then text:=AJson.GetValue<string>('text');
end;

{ TMessage }

constructor TMessage.Create(AJson: TJSONObject);
begin
 if AJson.Contains('content')
  then content:=TContent.Create(AJson.GetValue<TJSONObject>('content'));
 if AJson.Contains('createdAt')
  then createdAt:=AJson.GetValue<string>('createdAt');
 if AJson.Contains('direction')
  then direction:=AJson.GetValue<string>('direction');
 if AJson.Contains('messageId')
  then messageId:=AJson.GetValue<string>('messageId');
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Integer>('userId');
end;

{ TChat }

constructor TChat.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('agentUserId')
  then agentUserId:=AJson.GetValue<Integer>('agentUserId');
 if AJson.Contains('chatId')
  then chatId:=AJson.GetValue<Integer>('chatId');
 if AJson.Contains('readAt')
  then readAt:=(AJson.GetValue<string>('readAt'));
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Integer>('userId');
 if AJson.Contains('createdAt')
  then createdAt:=AJson.GetValue<string>('createdAt');

 if AJson.Contains('messages')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('messages');
    SetLength(messages, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
     messages[i]:=TMessage.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('offerId')
  then offerId:=AJson.GetValue<Integer>('offerId');
 if AJson.Contains('updatedAt')
  then updatedAt:=AJson.GetValue<string>('updatedAt');
end;

{ TImages }

constructor TImages.Create(AJson: TJSONObject);
begin
 if AJson.Contains('big')
  then big:=AJson.GetValue<string>('big');
 if AJson.Contains('small')
  then small:=AJson.GetValue<string>('small');
end;

{ TAvatar }

constructor TAvatar.Create(AJson: TJSONObject);
begin
 if AJson.Contains('images')
  then images:=TImages.Create(AJson.GetValue<TJSONObject>('images'));
end;

{ TUser }

constructor TUser.Create(AJson: TJSONObject);
begin
 if AJson.Contains('avatar')
  then avatar:=TAvatar.Create(AJson.GetValue<TJSONObject>('avatar'));
 if AJson.Contains('firstName')
  then firstName:=AJson.GetValue<string>('firstName');
 if AJson.Contains('lastName')
  then lastName:=AJson.GetValue<string>('lastName');
 if AJson.Contains('name')
  then name:=AJson.GetValue<string>('name');
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Integer>('userId');
end;

{ TChatsReadabilityWebhook }

constructor TChatsReadabilityWebhook.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('chats')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('chats');
    SetLength(chats, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
     chats[i]:=TChat.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('users')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('users');
    SetLength(users, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
     users[i]:=TUser.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('webhookType')
  then webhookType := AJson.GetValue<string>('webhookType');
end;

{ TMainPhoto }

constructor TMainPhoto.Create(AJson: TJSONObject);
begin
 if AJson.Contains('users')
  then miniUrl:=AJson.GetValue<string>('miniUrl');
 if AJson.Contains('users')
  then url:=AJson.GetValue<string>('url');
end;

{ TOfferDetails }

constructor TOfferDetails.Create(AJson: TJSONObject);
begin
 if AJson.Contains('address')
  then address:=AJson.GetValue<string>('address');
 if AJson.Contains('externalId')
  then externalId:=AJson.GetValue<string>('externalId');
 if AJson.Contains('id')
  then id:=AJson.GetValue<Integer>('id');
 if AJson.Contains('mainPhoto')
  then mainPhoto:=TMainPhoto.Create(AJson.GetValue<TJSONObject>('mainPhoto'));
 if AJson.Contains('price')
  then price:=AJson.GetValue<string>('price');
 if AJson.Contains('publishedUserId')
  then publishedUserId := AJson.GetValue<Integer>('publishedUserId');
 if AJson.Contains('title')
  then title:=AJson.GetValue<string>('title');
 if AJson.Contains('url')
  then url:=AJson.GetValue<string>('url');
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Integer>('userId');
end;

{ TOffersMessagesWebhook }

constructor TOffersMessagesWebhook.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
  User:TUser;
  Offer:TOfferDetails;
begin
 if AJson.Contains('chats')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('chats');
    SetLength(chats, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
     chats[i]:=TChat.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('offers')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('offers');
    SetLength(offers, JsonArray.Count);
    offerDict:=TDictionary<integer,TOfferDetails>.Create;
    for i:=0 to JsonArray.Count-1 do
     begin
      Offer:=TOfferDetails.Create(JsonArray.Items[i] as TJSONObject);
      if not offerDict.ContainsKey(Offer.Id)
       then
        begin
         offers[i]:=Offer;
         offerDict.Add(Offer.Id, Offer);
        end;
     end;
   end;

 if AJson.Contains('users')
  then
   begin
    JsonArray := AJson.GetValue<TJSONArray>('users');
    SetLength(users, JsonArray.Count);
    userDict:=TDictionary<integer,TUser>.Create;
    for i:=0 to JsonArray.Count-1 do
     begin
      User:=TUser.Create(JsonArray.Items[i] as TJSONObject);
      if not userDict.ContainsKey(User.userId)
       then
        begin
         users[i]:=User;
         userDict.Add(User.userId, User);
        end;
     end;
  end;

 if AJson.Contains('webhookType')
  then webhookType:=AJson.GetValue<string>('webhookType');
end;

{ TActionButton }

constructor TActionButton.Create(AJson: TJSONObject);
begin
 if AJson.Contains('link')
  then link:=AJson.GetValue<string>('link');
 if AJson.Contains('text')
  then text:=AJson.GetValue<string>('text');
end;

{ TSystemContent }

constructor TSystemContent.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('actionButtons')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('actionButtons');
    SetLength(actionButtons, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
      actionButtons[i]:=TActionButton.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('files')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('files');
    SetLength(files, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
      files[i]:=TFile.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('htmlText')
  then htmlText:=AJson.GetValue<string>('htmlText');
 if AJson.Contains('text')
  then text:=AJson.GetValue<string>('text');
end;

{ TSystemMessage }

constructor TSystemMessage.Create(AJson: TJSONObject);
begin
 if AJson.Contains('content')
  then content:=TSystemContent.Create(AJson.GetValue<TJSONObject>('content'));
 if AJson.Contains('createdAt')
  then createdAt:=AJson.GetValue<string>('createdAt');
 if AJson.Contains('direction')
  then direction:=AJson.GetValue<string>('direction');
 if AJson.Contains('messageId')
  then messageId:=AJson.GetValue<string>('messageId');
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Integer>('userId');
end;

{ TSystemMessagesWebhook }

constructor TSystemMessagesWebhook.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('chats')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('chats');
    SetLength(chats, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
      chats[i]:=TChat.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('users')
  then
   begin
    JsonArray:=AJson.GetValue<TJSONArray>('users');
    SetLength(users, JsonArray.Count);
    for i:=0 to JsonArray.Count-1 do
      users[i]:=TUser.Create(JsonArray.Items[i] as TJSONObject);
   end;

 if AJson.Contains('webhookType')
  then webhookType:=AJson.GetValue<string>('webhookType');
end;

{ TResult }

constructor TResult.Create(AJson: TJSONObject);
begin
 if AJson.Contains('chatsReadabilityWebhook')
  then ChatsReadabilityWebhook:=TChatsReadabilityWebhook.Create(AJson.GetValue<TJSONObject>('chatsReadabilityWebhook'));
 if AJson.Contains('offersMessagesWebhook')
  then OffersMessagesWebhook:=TOffersMessagesWebhook.Create(AJson.GetValue<TJSONObject>('offersMessagesWebhook'));
 if AJson.Contains('systemMessagesWebhook')
  then SystemMessagesWebhook:=TSystemMessagesWebhook.Create(AJson.GetValue<TJSONObject>('systemMessagesWebhook'));
end;

{ TJsonData }

constructor TCianResponseJson.Create(AJson: TJSONObject);
var
 JsonObj: TJSONObject;
 ResultObj: TJSONObject;
begin
 if AJson.Contains('operationId')
  then OperationId:=AJson.GetValue<string>('operationId');
 if AJson.Contains('result')
  then Result:=TResult.Create(AJson.GetValue<TJSONObject>('result'))
  else
   begin
    ResultObj:=TJSONObject.Create;
    JsonObj:=TJSONObject.Create;
    JsonObj.AddPair(TJSONPair.Create('offersMessagesWebhook',AJson));
    ResultObj.AddPair(TJSONPair.Create('result',JsonObj));
    Result:=TResult.Create(ResultObj.GetValue<TJSONObject>('result'))
   end;
end;

{ TJSONObjectHelper }

function TJSONObjectHelper.Contains(const Key: string): boolean;
var
 JSONPair:TJSONPair;
begin
 Result:=False;
 for JSONPair in Self do
  begin
   if JSONPair.JsonString.Value=Key
    then
     begin
      Result:=True;
      break;
     end;
  end;
end;
{$ENDREGION 'CianResponseJson'}

{$REGION 'CianResponseJson'}
function ParseCianResponseJson(const JsonStr:string):TCianResponseJson;
var
 JsonObj: TJSONObject;
begin
 JsonObj:=TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(JsonStr),0) as TJSONObject;
 try
  Result:=TCianResponseJson.Create(JsonObj);
 finally
  JsonObj.Free;
 end;
end;
{$ENDREGION 'CianResponseJson'}

{$REGION 'FoundValueSubscriptions'}
function FoundValueSubscriptions(const JsonStr:string; AValue:string):boolean;
var
 JSONObject         : TJSONObject;
 ResultObject       : TJSONObject;
 SubscriptionObj    : TJSONObject;
 SubscriptionArray  : TJSONArray;
 i:Integer;
begin
 Result:=False;
 JSONObject:=TJSONObject.ParseJSONValue(JsonStr) as TJSONObject;
 try
   if JSONObject.Contains('result')
    then
     begin
      ResultObject:=JSONObject.GetValue<TJSONObject>('result');
      if ResultObject.Contains('subscriptions')
       then
        begin
         SubscriptionArray:=ResultObject.GetValue<TJSONArray>('subscriptions');
         for i:=0 to SubscriptionArray.Count-1 do
          begin
           SubscriptionObj:=SubscriptionArray.Items[i] as TJSONObject;
           if SubscriptionObj.GetValue<string>('url','')=AValue
            then
             begin
              Result:=True;
              Break;
             end;
          end;
        end;
     end;
 finally
  JSONObject.Free;
 end;
end;
{$ENDREGION 'FoundValueSubscriptions'}

function FindUserByUserId(AOffersMessagesWebhook:TOffersMessagesWebhook; AUserId:integer):TUser;
begin
 if AOffersMessagesWebhook.userDict.TryGetValue(AUserId,Result)
  then Exit;
end;

function FindOfferByOfferId(AOffersMessagesWebhook:TOffersMessagesWebhook; AOfferId:integer):TOfferDetails;
begin
 if AOffersMessagesWebhook.offerDict.TryGetValue(AOfferId,Result)
  then Exit;
end;

end.
