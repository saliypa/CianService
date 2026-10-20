unit Classes.Logs;
//Лог из основного проекта.
//Пусть пока так и остаётся

interface

uses
  Classes, SysUtils, DateUtils, Winapi.Windows, System.StrUtils, Vcl.Forms;

// -- Запись в лог c возможной архивацией
procedure WriteLog(const AText, ALogFilePath, AHistLogPath: string; const AMaxLogSize: integer); overload;
// -- Запись в лог без архивации
procedure WriteLog(const AText, ALogFilePath: string); overload;
// -- Запись в лог без архивации (лог в той же папке)
procedure WriteLog(const AText: string); overload;
// -- Запись в лог, используя общие настройки
procedure WriteLog_C(const AText: string);

// --------------------------------------------

// -- Архивирование лога
procedure ShrinkLog(const ALogFilePath, AHistLogPath: string; const AMaxLogSize: integer);
// --------------------------------------------

// -- Дельта в днях, часах, минутах, секундах
function GetUpTime(AFirstDate, ALastDate: TDateTime): string;

// -- Общие настройки
var
  LogFilePath, HistLogPath: string;
  MaxLogSize: integer;

implementation

uses
  System.SyncObjs;

var
  LogLock: TCriticalSection;


// -- Запись в лог
procedure WriteLog(const AText, ALogFilePath, AHistLogPath: string; const AMaxLogSize: integer);
var
  TxtFile: TextFile;
  LogStr: string;
begin
  try
    // Если задан AMaxLogSize -> архивируем (при необходимости)
    if (AMaxLogSize > 0) then ShrinkLog(ALogFilePath, AHistLogPath, AMaxLogSize);

    AssignFile(TxtFile, ALogFilePath);
    LogStr := Format('%s : %s', [FormatDateTime('DD-MM-YYYY hh:nn:ss.zzz', Now), AText]);
    try
      if FileExists(ALogFilePath) then Append(TxtFile)
        else Rewrite(TxtFile);
      Writeln(TxtFile, LogStr);
    finally
      CloseFile(TxtFile);
    end;
  except
  end;
end;

// -- Запись в лог
procedure WriteLog(const AText, ALogFilePath: string); overload;
begin
  WriteLog(AText, ALogFilePath, '', 0);
end;

// -- Запись в лог без архивации (лог в той же папке)
procedure WriteLog(const AText: string); overload;
begin
  WriteLog(AText, Format('%s%s_Log_%s', [ExtractFilePath(Application.ExeName)
    , ExtractFileName(Application.ExeName), ExtractFileExt(Application.ExeName)]));
end;

// -- Запись в лог, используя общие настройки
procedure WriteLog_C(const AText: string);
begin
  LogLock.Enter;
  try
    WriteLog(DateTimeToStr(now()) + ' ' + AText, LogFilePath, HistLogPath, MaxLogSize);
  finally
    LogLock.Leave;
  end;
end;



// -- Архивирование лога
procedure ShrinkLog(const ALogFilePath, AHistLogPath: string; const AMaxLogSize: integer);
var
  F: file of byte;
  Size: integer;
  HistLogFilePath{, LogFileName}: string;
begin
  if not(FileExists(ALogFilePath)) then exit; // Нет файла -> на выход
  // Определяем размер текущего лога
  AssignFile(F, ALogFilePath);
  try
    Reset(F);
    Size := Filesize(F);
  finally
    CloseFile(F);
  end;

  // Переносим, если перерос максимум
  if (Size > AMaxLogSize) then
  begin
    try
      ForceDirectories(AHistLogPath);
      HistLogFilePath := Format('%s\%s_%s%s', [AHistLogPath, ChangeFileExt(ExtractFileName(ALogFilePath), '')
        , FormatDateTime('YYYY-MM-DD_hh-nn-ss', Now), ExtractFileExt(ALogFilePath)]);
      MoveFile(PWideChar(ALogFilePath), PWideChar(HistLogFilePath));
    except
    end;
  end;
end;


// Дельта в днях, часах, минутах, секундах
function GetUpTime(AFirstDate, ALastDate: TDateTime): string;
var FYear, FMonth, FDays, FHours, FMinutes, FSeconds, FMSecs: word;
begin
  DecodeDateTime(TimeOf(ALastDate - AFirstDate), FYear, FMonth, FDays, FHours, FMinutes, FSeconds, FMSecs);
  FDays := DaysBetween(ALastDate, AFirstDate);
  Result := Format('%d дней %d часов %d минут %d секунд', [FDays, FHours, FMinutes, FSeconds]);
end;

initialization
  LogLock := TCriticalSection.Create;

finalization
  LogLock.Free;

end.
