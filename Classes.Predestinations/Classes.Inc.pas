unit Classes.Inc;

interface

const
 cToken           = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjcxMTA0NzEwfQ.jsGkyyY_uOw_YskneXT_V2Iom0VVcp14UsUyXmq99c0';
 cWebhooksURL     = 'https://tone.setl.ru/cian_send/';

 cDescription     = 'CianChat.Setl.Corppn.ru';
 cServiceName     = 'CianChatService';
 cLogExt          = '_Log.txt';
 cServerStand     = 'MOSQA01\INSTANCE1';
 cServerWork      = 'mossqlcrp.corppn.ru';
 cDBNameStand     = 're2a_stand';
 cDBNameWork      = 're2a';

 cSendCmd         = 'From=SETL';
 cRespCmd         = 'cian';

 cPathFile        = '\\mserver\kk\Документы_по_чатам\';
 cMainPath        = 'C:\WebService\CianChatService\';
 cMainAssigPath   = 'C:\WebService\CianChatAssignmentService\';
 cMainExe         = 'CianChatService.exe';
 cMainAssigExe    = 'CianChatAssignmentService.exe';


var
 sServerName      : string;
 sDBName          : string;
 sServerPort      : string;
 sPathFile        : string;
 sWebhooksURL     : string;
 sToken           : string;
 sMainDescription : string;

 sSetSubscribe    : boolean;
 sSetUnSubscribe  : boolean;
 sCheckSubscribe  : boolean;
 sDebugMode       : boolean;

 type
   TResultEnumerate=record
    ResultType  : integer;
    ResultValue : array of string;
  end;

  TResultAdv=TResultEnumerate;

implementation

end.
