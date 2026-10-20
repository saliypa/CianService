unit Classes.Inc;

interface

const
 cWebhooksURL     = 'https://tone.setl.ru/cian_send/';

 cDescription     = 'CianChat.Setl.Corppn.ru';
 cServiceName     = 'CianChatService';
 cLogExt          = '_Log.txt';
 cServerStand     = 'MOSQA01\INSTANCE1';
 cServerWork      = 'mossqlcrp.corppn.ru';
 cDBNameStand     = 're2a_stand';
 cDBNameWork      = 're2a';

 //Запрос ИК на отправку в Циан: параметр From=SETL
 cSendParam       = 'From';
 cSendValue       = 'SETL';
 cRespCmd         = 'cian';

 //Папка (рядом с exe) для тел вебхуков, которые не удалось обработать
 cFailedWebhooksPath = 'FailedWebhooks';

 //Защитный токен SETL: передаётся заголовком X-Setl-Token либо параметром SetlToken
 cSetlTokenHeader = 'X-Setl-Token';
 cSetlTokenParam  = 'SetlToken';

 cPathFile        = '\\mserver\kk\Документы_по_чатам\';


var
 sServiceName     : string;
 sServerName      : string;
 sDBName          : string;
 sServerPort      : string;
 sPathFile        : string;
 sWebhooksURL     : string;
 sToken           : string;
 sSetlToken       : string;
 sWebhookSecret   : string;
 sFailedWebhooksPath : string;
 sMainDescription : string;
 sConnectionString: string;

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
