# **CianChatService**

Сервис предназначен для обмена ИК модуля "чаты" с открытым public-api.cian.ru

Подробное описание, установка и диагностика: [WIKI.md](WIKI.md)

## Содержание

- [Установка](#установка)
- [Структура](#структура)
- [Использование](#использование)
- [Управление](#управление)



## Установка

Инструкция по размещению репозитория

```
git clone git@git.setl.ru:ik/servises/cianchatservice.git
cd cianchatservice
```


## Структура
1. **Classes.CianChat** 
   1.  **Classes.CianChat.pas** - основной файл-модуль для рабочего (сервиса) исполняемого файла;
   2.  **Classes.CianChat.dfm** - основная файл-форма для рабочего (сервиса) исполняемого файла;
2. **Classes.CianChatExecute** 
   1.  **Classes.CianChatExecute.pas** - основной файл-модуль для демонстрационного исполняемого файла;
   2.  **Classes.CianChatExecute.dfm** - основная файл-форма для демонстрационного исполняемого файла;
3. **Classes.CianCore** 
   1.  **Classes.CianApiCore.pas** - модуль, содержащий класс обмена api-cian;
   2.  **Classes.CianResponseCore.pas** - модуль, содержащий класс парсинга ответов api-cian;
   3.  **Classes.CianHandler.pas** - общая логика сервиса и демо: настройки, подписка на вебхуки, обработка входящих запросов;
4. **Classes.Common** 
   1.  **Classes.Common.pas** - модуль, содержащий вспомагательные методы;
5. **Classes.DBCore** 
   1.  **Classes.DBCore.pas** - модуль, содержащий методы для работы с БД;
6. **Classes.Logs** 
   1.  **Classes.Logs.pas** -  модуль, содержащий класс логирования (базовый из ИК);
7. **Classes.Predestinations** 
   1.  **Classes.Inc.pas** - модуль, содержащий общие константы и переменные;
8. Проекты (`.dpr` + `.dproj` + `.res`), код у всех общий, версия **1.1.0.0**:
   1.  **CianChatService** / **CianChatExecute** - основная служба и демонстрационное приложение;
   2.  **CianChatAssignmentService** / **CianChatAssignmentExecute** - служба и приложение для переуступок;
   3.  **CianChatFRTService** / **CianChatFRTExecute** - служба и приложение FRT (ключ Циан будет выдан позже);
9. **ini.Debug** 
   1.  **CianChatExecute.ini** - конфигурационный файл для демонстрационного исполняемого файла Debug;
   2.  **CianChatService.ini** - конфигурационный файл для рабочего (сервиса) исполняемого файла Debug;
   3.  **CianChatFRTExecute.ini**, **CianChatFRTService.ini** - то же для пары FRT (порт 8116, `Token` пустой);
10. **ini.Release** 
   1.  **CianChatExecute.ini** - конфигурационный файл для демонстрационного исполняемого файла Release;
   2.  **CianChatService.ini** - конфигурационный файл для рабочего (сервиса) исполняемого файла Release;
11. **bat** 
   1.  **register_service_create.bat** - bat файл для регистрации сервиса первым способом;
   2.  **unregister_service_create.bat** - bat файл для отмены регистрации сервиса первым способом;
   3.  **register_service_install.bat** - bat файл для регистрации сервиса вторым способом;
   4.  **unregister_service_install.bat** - bat файл для отмены регистрации сервиса вторым способом;


## Использование

Регистрация сервиса через консоль командами:

````
.\CianChatService.exe /install
````
Так же доступна регистрация через bat файлы
либо:
````
register_service_create.bat
````

либо:
````
register_service_install.bat
````

Имя службы равно имени исполняемого файла без расширения (`CianChatService`, `CianChatAssignmentService`, `CianChatFRTService`).
При регистрации вручную (`sc create`) имя службы должно совпадать с именем exe, иначе служба не запустится (ошибка 1053).

Рядом с исполняемым файлом читается ini (`<имя exe>.ini`) и сохраняется лог работы (`<имя exe>_Log.txt`)


## Управление

Управление сервисом и демо исполняемым файлом осуществляется по средствам ini файла

```
[Parameters]
# ServerPort: порт, на котором размещён слушатель
ServerPort=8114
# LogHistPath: Папка хранения логов
LogHistPath=LogHistory
# MaxLogSize: Максимальный размер лог-файла (Byt)
MaxLogSize=1000000
# Директория временного размещения файлов чатов
PathTempFiles=\\mserver\kk\Документы_по_чатам\
# Имя сервера (mossqlcrp.corppn.ru, mosqa01\instance1)
ServerName=mossqlcrp.corppn.ru
# Имя БД (re2a, re2a_stand)
DBName=re2a
#Получить текущие подписки вебхуков при старте
CheckSubscribe=1
#Зарегистрировать получателя вебхуков при старте если нет активных подписок
SetSubscribe=1
#Отписать получателя от вебхуков при старте. При включении, перекрывает параметр SetSubscribe
SetUnSubscribe=0
#Адрес на который будет осуществляться пересылка (включает секретный сегмент WebhookSecret)
WebhooksURL=https://tone.setl.ru/chatcian2/<WebhookSecret>/
#Секретный сегмент пути вебхука (не короче 32 символов). Пусто - вебхуки принимаются без проверки
WebhookSecret=<секретная строка>
#Адрес по которому будет идентифицироваться токен
MainDescription=public-api.cian.ru
#Токен подключения к Циан (свой для каждой службы). Пусто - служба не работает с Циан
Token=<ключ Циан>
#Защитный токен SETL: передаётся в запросах From=SETL заголовком X-Setl-Token или параметром SetlToken
SetlToken=<секретная строка>
```

Токен Циан у каждой службы свой и задаётся в её ini (`Token`). Ключа по умолчанию в коде нет: если `Token` не задан, служба запускается, но с Циан не работает — не подписывается на вебхуки, а запросы `From=SETL` и вебхуки получают `503`.

### Защитный токен SETL

Запросы на отправку сообщений в Циан (`From=SETL`) принимаются только с правильным `SetlToken`:

```
POST http://<сервер>:8114/
X-Setl-Token: <SetlToken из ini>
Content-Type: application/x-www-form-urlencoded

From=SETL&ChatId=123&Message=Текст
```

Вместо заголовка можно передать параметр `SetlToken=<...>` в теле запроса. Если `SetlToken` в ini не задан, все запросы `From=SETL` отклоняются (403). Значение токена в лог не пишется.

Сообщение отправляется в Циан до ответа: `200` — Циан принял сообщение, `502` — Циан вернул ошибку или недоступен (текст ошибки в теле ответа).

### Секрет вебхука

Циан не подписывает вебхуки, поэтому адрес вебхука содержит секретный сегмент пути (`WebhookSecret`). Запросы на адрес без него отклоняются (404). Подробнее: [WIKI.md](WIKI.md), раздел 2.

