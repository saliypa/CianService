unit Classes.CianChatExecute;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Data.Win.ADODB,
  Vcl.StdCtrls, Vcl.Buttons, IdContext, IdCustomHTTPServer, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdHTTPServer;

type
  TForm1 = class(TForm)
    MainConnection: TADOConnection;
    GetWebhooksSub: TBitBtn;
    GetMessageFileb: TBitBtn;
    GetMessages: TBitBtn;
    SendReadChat: TBitBtn;
    GetChats: TBitBtn;
    GetChat: TBitBtn;
    TestWebhook: TBitBtn;
    Send: TBitBtn;
    UnSubscribe: TBitBtn;
    Subscribe: TBitBtn;
    EditChatId: TEdit;
    IdHTTPServer: TIdHTTPServer;
    TestWebhookSend: TBitBtn;
    Label1: TLabel;
    procedure SubscribeClick(Sender: TObject);
    procedure UnSubscribeClick(Sender: TObject);
    procedure SendClick(Sender: TObject);
    procedure TestWebhookClick(Sender: TObject);
    procedure GetChatClick(Sender: TObject);
    procedure GetChatsClick(Sender: TObject);
    procedure SendReadChatClick(Sender: TObject);
    procedure GetMessagesClick(Sender: TObject);
    procedure GetMessageFilebClick(Sender: TObject);
    procedure GetWebhooksSubClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
    procedure TestWebhookSendClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
 Classes.Inc, Classes.Logs, Classes.Common, Classes.CianApiCore, Classes.CianHandler;

{$R *.dfm}

{ TForm1 }

{$REGION 'Demo'}
procedure TForm1.GetChatClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
 AChatId:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AChatId:=EditChatId.Text;

  AResponse:=ACianApiCore.GetChat(AChatId);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.GetChatsClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
 APage:string;
 APageSize:string;
 AOrderBy:TOrderByTypes;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  APage:='1';
  APageSize:='100';
  AOrderBy:=obUpdatedAt;

  AResponse:=ACianApiCore.GetChats(APage,APageSize,AOrderBy);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.GetWebhooksSubClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AResponse:=ACianApiCore.GetWebhooksSub;
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.GetMessageFilebClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AFileId:string;
 AFilePath:string;
 AFileStream:TFileStream;
 AMemoryStream:TMemoryStream;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AFileId:='d5c09995-5677-4303-923e-401182574cc5';
  AFilePath:='file.bin';

  AMemoryStream:=ACianApiCore.GetMessageFile(AFileId);
  try
   if AMemoryStream=nil
    then
     begin
      ShowMessage('Error downloading file');
      Exit;
     end;

   AFileStream:=TFileStream.Create(AFilePath,fmCreate);
   try
    AFileStream.CopyFrom(AMemoryStream,AMemoryStream.Size);
   finally
    AFileStream.Free;
   end;
  finally
   AMemoryStream.Free;
  end;

  ShowMessage('File downloaded successfully');
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.GetMessagesClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
 AChatId:string;
 APage:string;
 APageSize:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AChatId:=EditChatId.Text;
  APage:='1';
  APageSize:='100';

  AResponse:=ACianApiCore.GetMessages(AChatId,APage,APageSize);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.SubscribeClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AWebhookTypes: array of TWebhookTypes;
 AResponse:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  SetLength(AWebhookTypes,1);
  AWebhookTypes[0]:=wtOffersMessagesIncoming;
  //AWebhookTypes[1]:=wtOffersMessagesApiOutgoing;
  //AWebhookTypes[2]:=wtSystemMessages;

  AResponse:=ACianApiCore.SubscribeWebhooks(AWebhookTypes);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.TestWebhookClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AWebhookTypes: TWebhookTypes;
 AResponse:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AWebhookTypes:=wtOffersMessages;

  AResponse:=ACianApiCore.SendTestWebhooks(AWebhookTypes);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.TestWebhookSendClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AWebhookTypes: TWebhookTypes;
 AResponse:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AWebhookTypes:=wtOffersMessages;

  AResponse:=ACianApiCore.SendTestWebhooks(AWebhookTypes);
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.UnSubscribeClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AWebhookTypes: TWebhookTypes;
 AResponse:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AWebhookTypes:=wtOffersMessages;

  AResponse:=ACianApiCore.UnSubscribeWebhooks(AWebhookTypes);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.SendClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
 AChatId:string;
 AText:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AChatId:=EditChatId.Text;
  AText:='TestMessage';

  AResponse:=ACianApiCore.SendMessage(AChatId,AText);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;

procedure TForm1.SendReadChatClick(Sender: TObject);
var
 ACianApiCore:TCianApiCore;
 AResponse:string;
 AChatId:string;
begin
 ACianApiCore:=TCianApiCore.Create(sToken,sWebhooksURL);
 try
  AChatId:=EditChatId.Text;

  AResponse:=ACianApiCore.SendReadChat(AChatId);
  ShowMessage(SplitText(AResponse));
 finally
  ACianApiCore.Free;
 end;
end;
{$ENDREGION 'Demo'}

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 WriteLog_C(Format('#Attempting to stop service %s', [sServiceName]));
 IdHTTPServer.Active:=False;
 WriteLog_C('#Service stopped');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 if not LoadSettings
  then Halt;

 Caption:=ExtractFileName(ParamStr(0));
 MainConnection.ConnectionString:=sConnectionString;

 IdHTTPServer.DefaultPort:=sServerPort.ToInteger;
 IdHTTPServer.Active:=True;

 SetListener;

 WriteLog_C(Format('#Attempting to start service %s', [sServiceName]));
 WriteLog_C('#Service started');
end;

{$REGION 'IdHTTPServerCommandGet'}
procedure TForm1.IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
 HandleHTTPRequest(ARequestInfo,AResponseInfo);
end;
{$ENDREGION 'IdHTTPServerCommandGet'}

end.
