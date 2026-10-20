program CianChatExecute;

uses
  Vcl.Forms,
  Classes.CianChatExecute in 'Classes.CianChatExecute\Classes.CianChatExecute.pas' {Form1},
  Classes.Inc in 'Classes.Predestinations\Classes.Inc.pas',
  Classes.Logs in 'Classes.Logs\Classes.Logs.pas',
  Classes.Common in 'Classes.Common\Classes.Common.pas',
  Classes.DBCore in 'Classes.DBCore\Classes.DBCore.pas',
  Classes.CianApiCore in 'Classes.CianCore\Classes.CianApiCore.pas',
  Classes.CianResponseCore in 'Classes.CianCore\Classes.CianResponseCore.pas',
  Classes.CianHandler in 'Classes.CianCore\Classes.CianHandler.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
