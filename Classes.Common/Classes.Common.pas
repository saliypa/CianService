unit Classes.Common;

interface

uses
 Winapi.Windows, Winapi.ShlObj, System.SysUtils, Winapi.Winsock2;

// iif с Integer'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Integer): Integer; overload;
// iif с Extended'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Extended): Extended; overload;
// iif с String'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: String): String; overload;
// iif с DateTime'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: TDateTime): TDateTime; overload;
// iif с Variant
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Variant): Variant; overload;
// Временная папка пользователя
function GetUserTempPath:string;
//Преобразовать Дату время формата 2019-08-24T14:15:22Z
function GetConvertDateTimeTZ(AValue:string):TDateTime;
function GetLocalIPdress:string;
function SplitText(AValue:string; ASize:integer=55):string;
function GetCurrentTimeAsString:string;


implementation

// iif с Integer'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Integer): Integer; overload;
begin
  if ACondition then
    Result := IfTrue
  else
    Result := IfFalse;
end;

// iif с Extended'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Extended): Extended; overload;
begin
  if ACondition then
    Result := IfTrue
  else
    Result := IfFalse;
end;

// iif с String'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: String): String; overload;
begin
  if ACondition then
    Result := IfTrue
  else
    Result := IfFalse;
end;

// iif с DateTime'ом
function iif(const ACondition: Boolean; const IfTrue, IfFalse: TDateTime): TDateTime; overload;
begin
  if ACondition then
    Result := IfTrue
  else
    Result := IfFalse;
end;

// iif с Variant
function iif(const ACondition: Boolean; const IfTrue, IfFalse: Variant): Variant; overload;
begin
  if ACondition then Result := IfTrue
  else Result := IfFalse;
end;

// Временная папка пользователя
function GetUserTempPath:string;
var
 Path: array[0..MAX_PATH] of Char;
begin
 Result:='\';
 if SHGetFolderPath(0,CSIDL_LOCAL_APPDATA,0,SHGFP_TYPE_CURRENT,Path) = S_OK
  then
   begin
    SetString(Result, Path, StrLen(Path));
    {$WARNINGS OFF}
    Result:=IncludeTrailingBackslash(Result) + 'Temp\';
    {$WARNINGS ON}
   end;
end;

//Преобразовать дату/время формата 2019-08-24T14:15:22Z
function GetConvertDateTimeTZ(AValue:string):TDateTime;
begin
 if AValue[Length(AValue)]='Z'
  then Delete(AValue,Length(AValue),1);

 AValue:=StringReplace(AValue,'T',' ', [rfReplaceAll]);

 Result:=StrToDateTime(AValue);
end;

function GetLocalIPdress:string;
var
 HostName:array[0..255] of Char;
 HostEntry:PHostEnt;
 Addr: PInAddr;
begin
 Result:=EmptyStr;
 if gethostname(PAnsiChar(@HostName), SizeOf(HostName))=0
  then
   begin
    HostEntry:=gethostbyname(PAnsiChar(@HostName));
    if Assigned(HostEntry)
     then
      begin
       Addr:=PInAddr(HostEntry^.h_addr_list^);
       {$WARNINGS OFF}
       Result:=inet_ntoa(Addr^);
       {$WARNINGS ON}
      end;
   end;
end;

function SplitText(AValue:string; ASize:integer=55):string;
var
 i:integer;
begin
 Result:=EmptyStr;
 for i:=1 to Length(AValue) do
  begin
   Result:=Result+AValue[i];
   if (i mod ASize)=0
    then Result:=Result+#13#10;
  end;
end;

function GetCurrentTimeAsString:string;
begin
 Result:=FormatDateTime('hh:nn:ss',Now);
end;

end.
