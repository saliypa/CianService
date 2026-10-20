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
  TObjectsHelper = class
    class procedure FreeObjects<T: class>(var AItems: TArray<T>);
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
    destructor Destroy; override;
  end;

type
  TMessage = class
    content: TContent;
    createdAt: string;
    direction: string;
    messageId: string;
    userId: Int64;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TChat = class
    agentUserId: Int64;
    chatId: Int64;
    readAt: string;
    userId: Int64;
    createdAt: string;
    messages: TArray<TMessage>;
    offerId: Int64;
    updatedAt: string;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
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
    destructor Destroy; override;
  end;

type
  TUser = class
    avatar: TAvatar;
    firstName: string;
    lastName: string;
    name: string;
    userId: Int64;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TChatsReadabilityWebhook = class
    chats: TArray<TChat>;
    users: TArray<TUser>;
    webhookType: string;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
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
    id: Int64;
    mainPhoto: TMainPhoto;
    price: string;
    publishedUserId: Int64;
    title: string;
    url: string;
    userId: Int64;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TOffersMessagesWebhook = class
    chats: TArray<TChat>;
    offers: TArray<TOfferDetails>;
    users: TArray<TUser>;
    webhookType: string;
    userDict:TDictionary<Int64,TUser>;
    offerDict:TDictionary<Int64,TOfferDetails>;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
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
    destructor Destroy; override;
  end;

type
  TSystemMessage = class
    content: TSystemContent;
    createdAt: string;
    direction: string;
    messageId: string;
    userId: Int64;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TSystemMessagesWebhook = class
    chats: TArray<TChat>;
    users: TArray<TUser>;
    webhookType: string;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TResult = class
    chatsReadabilityWebhook: TChatsReadabilityWebhook;
    offersMessagesWebhook: TOffersMessagesWebhook;
    systemMessagesWebhook: TSystemMessagesWebhook;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;

type
  TCianResponseJson = class
    OperationId: string;
    Result: TResult;
    constructor Create(AJson: TJSONObject);
    destructor Destroy; override;
  end;
{$ENDREGION 'CianResponseJson'}

function ParseCianResponseJson(const JsonStr:string):TCianResponseJson;
function FindUserByUserId(AOffersMessagesWebhook:TOffersMessagesWebhook; AUserId:Int64):TUser;
function FindOfferByOfferId(AOffersMessagesWebhook:TOffersMessagesWebhook; AOfferId:Int64):TOfferDetails;


function FoundValueSubscriptions(const JsonStr:string; AValue:string):boolean;

implementation

{$REGION 'Destroy'}
class procedure TObjectsHelper.FreeObjects<T>(var AItems: TArray<T>);
var
  i: Integer;
begin
 for i:=0 to High(AItems) do
  AItems[i].Free;
 AItems:=nil;
end;

destructor TContent.Destroy;
begin
 TObjectsHelper.FreeObjects<TFile>(files);
 TObjectsHelper.FreeObjects<TOffer>(offers);
 inherited;
end;

destructor TMessage.Destroy;
begin
 content.Free;
 inherited;
end;

destructor TChat.Destroy;
begin
 TObjectsHelper.FreeObjects<TMessage>(messages);
 inherited;
end;

destructor TAvatar.Destroy;
begin
 images.Free;
 inherited;
end;

destructor TUser.Destroy;
begin
 avatar.Free;
 inherited;
end;

destructor TChatsReadabilityWebhook.Destroy;
begin
 TObjectsHelper.FreeObjects<TChat>(chats);
 TObjectsHelper.FreeObjects<TUser>(users);
 inherited;
end;

destructor TOfferDetails.Destroy;
begin
 mainPhoto.Free;
 inherited;
end;

destructor TOffersMessagesWebhook.Destroy;
begin
 //Словари не владеют объектами, объекты освобождаются через массивы
 userDict.Free;
 offerDict.Free;
 TObjectsHelper.FreeObjects<TChat>(chats);
 TObjectsHelper.FreeObjects<TOfferDetails>(offers);
 TObjectsHelper.FreeObjects<TUser>(users);
 inherited;
end;

destructor TSystemContent.Destroy;
begin
 TObjectsHelper.FreeObjects<TActionButton>(actionButtons);
 TObjectsHelper.FreeObjects<TFile>(files);
 inherited;
end;

destructor TSystemMessage.Destroy;
begin
 content.Free;
 inherited;
end;

destructor TSystemMessagesWebhook.Destroy;
begin
 TObjectsHelper.FreeObjects<TChat>(chats);
 TObjectsHelper.FreeObjects<TUser>(users);
 inherited;
end;

destructor TResult.Destroy;
begin
 chatsReadabilityWebhook.Free;
 offersMessagesWebhook.Free;
 systemMessagesWebhook.Free;
 inherited;
end;

destructor TCianResponseJson.Destroy;
begin
 Result.Free;
 inherited;
end;
{$ENDREGION 'Destroy'}

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
  then userId:=AJson.GetValue<Int64>('userId');
end;

{ TChat }

constructor TChat.Create(AJson: TJSONObject);
var
  i: Integer;
  JsonArray: TJSONArray;
begin
 if AJson.Contains('agentUserId')
  then agentUserId:=AJson.GetValue<Int64>('agentUserId');
 if AJson.Contains('chatId')
  then chatId:=AJson.GetValue<Int64>('chatId');
 if AJson.Contains('readAt')
  then readAt:=(AJson.GetValue<string>('readAt'));
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Int64>('userId');
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
  then offerId:=AJson.GetValue<Int64>('offerId');
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
  then userId:=AJson.GetValue<Int64>('userId');
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
 if AJson.Contains('miniUrl')
  then miniUrl:=AJson.GetValue<string>('miniUrl');
 if AJson.Contains('url')
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
  then id:=AJson.GetValue<Int64>('id');
 if AJson.Contains('mainPhoto')
  then mainPhoto:=TMainPhoto.Create(AJson.GetValue<TJSONObject>('mainPhoto'));
 if AJson.Contains('price')
  then price:=AJson.GetValue<string>('price');
 if AJson.Contains('publishedUserId')
  then publishedUserId := AJson.GetValue<Int64>('publishedUserId');
 if AJson.Contains('title')
  then title:=AJson.GetValue<string>('title');
 if AJson.Contains('url')
  then url:=AJson.GetValue<string>('url');
 if AJson.Contains('userId')
  then userId:=AJson.GetValue<Int64>('userId');
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
    offerDict:=TDictionary<Int64,TOfferDetails>.Create;
    for i:=0 to JsonArray.Count-1 do
     begin
      Offer:=TOfferDetails.Create(JsonArray.Items[i] as TJSONObject);
      if not offerDict.ContainsKey(Offer.Id)
       then
        begin
         offers[i]:=Offer;
         offerDict.Add(Offer.Id, Offer);
        end
       else Offer.Free; //Дубликат
     end;
   end;

 if AJson.Contains('users')
  then
   begin
    JsonArray := AJson.GetValue<TJSONArray>('users');
    SetLength(users, JsonArray.Count);
    userDict:=TDictionary<Int64,TUser>.Create;
    for i:=0 to JsonArray.Count-1 do
     begin
      User:=TUser.Create(JsonArray.Items[i] as TJSONObject);
      if not userDict.ContainsKey(User.userId)
       then
        begin
         users[i]:=User;
         userDict.Add(User.userId, User);
        end
       else User.Free; //Дубликат
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
  then userId:=AJson.GetValue<Int64>('userId');
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
 if AJson=nil
  then Exit;
 if AJson.Contains('chatsReadabilityWebhook')
  then ChatsReadabilityWebhook:=TChatsReadabilityWebhook.Create(AJson.GetValue<TJSONObject>('chatsReadabilityWebhook'));
 if AJson.Contains('offersMessagesWebhook')
  then OffersMessagesWebhook:=TOffersMessagesWebhook.Create(AJson.GetValue<TJSONObject>('offersMessagesWebhook'));
 if AJson.Contains('systemMessagesWebhook')
  then SystemMessagesWebhook:=TSystemMessagesWebhook.Create(AJson.GetValue<TJSONObject>('systemMessagesWebhook'));
end;

{ TJsonData }

constructor TCianResponseJson.Create(AJson: TJSONObject);
begin
 if AJson.Contains('operationId')
  then OperationId:=AJson.GetValue<string>('operationId');
 if AJson.Contains('result')
  then Result:=TResult.Create(AJson.GetValue<TJSONObject>('result'))
  else
   begin
    //Вебхук пришёл без обёртки result - сам объект и есть offersMessagesWebhook
    Result:=TResult.Create(nil);
    Result.offersMessagesWebhook:=TOffersMessagesWebhook.Create(AJson);
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
 JsonValue: TJSONValue;
 JsonObj: TJSONObject;
begin
 JsonValue:=TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(JsonStr),0);
 if not (JsonValue is TJSONObject)
  then
   begin
    JsonValue.Free;
    raise Exception.Create('Invalid JSON in webhook request');
   end;
 JsonObj:=TJSONObject(JsonValue);
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
 if JSONObject=nil
  then Exit;
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

function FindUserByUserId(AOffersMessagesWebhook:TOffersMessagesWebhook; AUserId:Int64):TUser;
begin
 Result:=nil;
 if (not Assigned(AOffersMessagesWebhook.userDict)) or
    (not AOffersMessagesWebhook.userDict.TryGetValue(AUserId,Result))
  then Result:=nil;
end;

function FindOfferByOfferId(AOffersMessagesWebhook:TOffersMessagesWebhook; AOfferId:Int64):TOfferDetails;
begin
 Result:=nil;
 if (not Assigned(AOffersMessagesWebhook.offerDict)) or
    (not AOffersMessagesWebhook.offerDict.TryGetValue(AOfferId,Result))
  then Result:=nil;
end;

end.
