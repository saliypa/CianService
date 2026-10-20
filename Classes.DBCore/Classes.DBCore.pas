unit Classes.DBCore;

interface

uses
 System.SysUtils, System.JSON, System.Classes, Winapi.Windows, Data.Win.ADODB, Data.DB, Classes.Inc;

type
  TCianDBCore = class
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create;
    procedure Free;

    function SetFileToDB(AChatId:string; APath:string; AConnection:TADOConnection):boolean;
    function SetOfflineMess(AFromSite:string; AName:string; AUserId:string; AConnection:TADOConnection):string;
    function UpdOfflineMess(AChatId:string; AValue:string; AConnection:TADOConnection):boolean;
    function SetUserSession(AExternalChatId:string; AMainURL:string; AMainDescription:string; AConnection:TADOConnection):string;
    function GetFreeOperator(AExternalChatId:string; AMainDescription:string; AConnection:TADOConnection):TResultAdv;
    function SetNewChat(AExternalChatId:string; AOperatorId:string; AMainURL:string; AMainDescription:string; AUserName:string; AValueText:string; AConnection:TADOConnection):TResultAdv;
  end;

 function CianDBCore:TCianDBCore;

implementation

uses
  Classes.Common, Classes.Logs;

{$REGION 'TCianDBCore_Instance'}
var
 CianDBCore_Instance:TCianDBCore;

function CianDBCore:TCianDBCore;
var
 newInstance:TCianDBCore;
begin
 Result:=nil;
 try
  if CianDBCore_Instance=nil
   then
    begin
     newInstance:=TCianDBCore.Create;

     if InterLockedCompareExchangePointer(Pointer(CianDBCore_Instance),Pointer(newInstance),nil)<>nil
      then FreeAndNil(newInstance);
    end;

  Result:=CianDBCore_Instance;
 except on e:Exception do WriteLog_C('*** Has error in TCianDBCore.CianDBCore: ['+E.ClassName+': '+e.Message+']'); end;
end;
{$ENDREGION 'TCianDBCore_Instance'}

{ TCianDBCore }

{$REGION 'Create'}
constructor TCianDBCore.Create;
begin

end;

procedure TCianDBCore.Free;
begin

end;
{$ENDREGION 'Create'}

{$REGION 'SetFileToDB'}
function TCianDBCore.SetFileToDB(AChatId:string; APath:string; AConnection:TADOConnection):boolean;
var
  SP: TADOStoredProc;
begin
 Result:=False;
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;
   SP.ProcedureName:='[dbo].[VF_SetlTone_setChatFile]';
   SP.Parameters.Refresh;
   SP.Parameters.ParamByName('@access_token').Value:='';
   SP.Parameters.ParamByName('@filePath').Value:=APath;
   SP.Parameters.ParamByName('@chat_id').Value:=AChatId;
   SP.Parameters.ParamByName('@FullAccess').Value:=True;
   SP.Open;

   WriteLog_C('+++ DB. SetFile. OfflineChat_ID='+AChatId);
   Result:=True;
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.SetFileToDB: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try SP.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'SetFileToDB'}

{$REGION 'SetOfflineMess'}
function TCianDBCore.SetOfflineMess(AFromSite:string; AName:string; AUserId:string; AConnection:TADOConnection):string;
var
 SP: TADOStoredProc;
begin
 Result:='0';
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;
   SP.ProcedureName := '[dbo].[VF_SetlTone_SetOfflineMessChatTel]';
   SP.Parameters.Refresh;
   SP.Parameters.ParamByName('@URL').Value:=AFromSite;
   SP.Parameters.ParamByName('@Name').Value:=AName;
   SP.Parameters.ParamByName('@user_id').Value:=AUserId;
   SP.Open;

   Result:=SP.FieldByName('ID').AsString;
   WriteLog_C('+++ DB. Set. OfflineChat_ID='+Result);
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.SetOfflineMess: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try SP.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'SetOfflineMess'}

{$REGION 'UpdOfflineMess'}
function TCianDBCore.UpdOfflineMess(AChatId:string; AValue:string; AConnection:TADOConnection):boolean;
var
 SP      : TADOStoredProc;
 sResult : String;
begin
 Result:=False;
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;
   SP.ProcedureName:='[dbo].[VF_SetlTone_UpdOfflineMessChatTel]';
   SP.Parameters.Refresh;
   SP.Parameters.ParamByName('@chat_id').Value:=AChatId;
   SP.Parameters.ParamByName('@Mess').Value:=AValue;
   SP.Open;
   sResult:=SP.FieldByName('chat_ID').AsString;

   Result:=sResult<>EmptyStr;
   WriteLog_C('+++ DB. Update. OfflineChat_ID='+sResult);
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.UpdOfflineMess: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try SP.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'UpdOfflineMess'}

{$REGION 'SetUserSession'}
function TCianDBCore.SetUserSession(AExternalChatId:string; AMainURL:string; AMainDescription:string; AConnection:TADOConnection):string;
var
 SP      : TADOStoredProc;
begin
 Result:=EmptyStr;
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;
   SP.ProcedureName:='[dbo].[VF_SetlTone_setUser]';
   SP.Parameters.Refresh;

   SP.Parameters.ParamByName('@full_access').Value:=True;
   SP.Parameters.ParamByName('@user_id').Value:=AExternalChatId;
   SP.Parameters.ParamByName('@ip').Value:=GetLocalIPdress;
   SP.Parameters.ParamByName('@FromSite').Value:=AMainDescription;
   SP.Parameters.ParamByName('@FromSiteStr').Value:=AMainURL;
   SP.Parameters.ParamByName('@UserAgent').Value:='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181';
   SP.Open;

   Result:=SP.Fields.Fields[0].AsString;

   WriteLog_C('+++ DB. SetUser. ID='+Result);
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.SetUserSession: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try SP.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'SetUserSession'}

{$REGION 'GetFreeOperator'}
function TCianDBCore.GetFreeOperator(AExternalChatId:string; AMainDescription:string; AConnection:TADOConnection):TResultAdv;
var
 SP         : TADOStoredProc;
begin
 Result.ResultType:=-1;
 SetLength(Result.ResultValue,3);
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;
   SP.ProcedureName:='[dbo].[VF_SetlTone_getFreeOperator_Cian]';
   SP.Parameters.Refresh;

   SP.Parameters.ParamByName('@user_id').Value:=AExternalChatId;
   SP.Parameters.ParamByName('@FromSite').Value:=AMainDescription;
   SP.Parameters.ParamByName('@full_access').Value:=True;
   //SP.Parameters.ParamByName('@DebugMode').Value:=sDebugMode;    //ќтключить

   SP.Open;

   //Ќеизвестный/забаненный клиент: процедура возвращает одну колонку myxml с ошибкой
   if SP.FieldCount<3
    then
     begin
      WriteLog_C('+++ DB. GetFreeOperator. Rejected: '+SP.Fields.Fields[0].AsString);
      Exit;
     end;

   Result.ResultValue[0]:=SP.Fields.Fields[0].AsString;
   Result.ResultValue[1]:=SP.Fields.Fields[1].AsString;
   Result.ResultValue[2]:=SP.Fields.Fields[2].AsString;
   Result.ResultType:=1;

   WriteLog_C('+++ DB. GetFreeOperator. OperatorAllow='+Result.ResultValue[1]+' Operator='+Result.ResultValue[2]+' Description='+Result.ResultValue[0]);
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.GetFreeOperator: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try SP.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'GetFreeOperator'}

{$REGION 'SetNewChat'}
function TCianDBCore.SetNewChat(AExternalChatId:string; AOperatorId:string; AMainURL:string; AMainDescription:string; AUserName:string; AValueText:string; AConnection:TADOConnection):TResultAdv;
var
 SP          : TADOStoredProc;
 AChatId     : string;
 AOperId     : string;
 ANewChat    : boolean;
begin
 Result.ResultType:=-1;
 ANewChat:=False;
 SetLength(Result.ResultValue,1);
 if not AConnection.Connected
  then Exit;

 SP:=TADOStoredProc.Create(nil);
 try
  try
   SP.Connection:=AConnection;
   SP.Close;

   SP.ProcedureName:='[dbo].[VF_SetlTone_newChat_Cian]';
   SP.Parameters.Refresh;

   SP.Parameters.ParamByName('@ExtChatId').Value:=AExternalChatId;
   SP.Parameters.ParamByName('@Chat_Var').Value:=AExternalChatId; //Ёто в развитее. ≈сли когда то понадобитс€ дробить чаты на несколько тредов по одному клиенту
   SP.Parameters.ParamByName('@FromSite').Value:=AMainDescription;
   SP.Parameters.ParamByName('@FromSiteStr').Value:=AMainURL;
   SP.Parameters.ParamByName('@ClientName').Value:=AUserName;
   SP.Parameters.ParamByName('@Operator_Id').Value:=AOperatorId;
   SP.Parameters.ParamByName('@Message').Value:=StringReplace(AValueText,#$A,Chr(13),[rfReplaceAll])+iif(sDebugMode, ' #'+GetCurrentTimeAsString, EmptyStr);
   SP.Open;

   AChatId:=SP.Fields.Fields[0].AsString;
   AOperId:=SP.Fields.Fields[2].AsString;
   if SP.FieldCount>4
    then ANewChat:=SP.Fields.Fields[4].AsBoolean;


   Result.ResultValue[0]:=AChatId;

   //chat_id=0: чат не создан (нет оператора/сессии) - не путать с продолжением чата
   if StrToIntDef(AChatId,0)<=0
    then
     begin
      WriteLog_C('+++ DB. SetNewChat. Chat is not created. OperatorId='+AOperId);
      Exit;
     end;

   if ANewChat
    then Result.ResultType:=0
    else Result.ResultType:=1;

   WriteLog_C('+++ DB. SetNewChat. NewChat='+ANewChat.ToString+' ChatId='+AChatId+' OperatorId='+AOperId);
  except on e:Exception do
    begin
     WriteLog_C('*** Has error in TCianDBCore.SetNewChat: ['+E.ClassName+': '+e.Message+']');
     raise;
    end;
  end;
 finally
  try Sp.Close; except end;
  FreeAndNil(SP);
 end;
end;
{$ENDREGION 'SetNewChat'}

end.
