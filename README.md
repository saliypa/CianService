# **CianChatService**

Сервис предназначен для обмена ИК модуля "чаты" с открытым public-api.cian.ru

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
4. **Classes.Common** 
   1.  **Classes.Common.pas** - модуль, содержащий вспомагательные методы;
5. **Classes.DBCore** 
   1.  **Classes.DBCore.pas** - модуль, содержащий методы для работы с БД;
6. **Classes.Logs** 
   1.  **Classes.Logs.pas** -  модуль, содержащий класс логирования (базовый из ИК);
7. **Classes.Predestinations** 
   1.  **Classes.Inc.pas** - модуль, содержащий общие константы и переменные;
8. **CianChatExecute.res** - ресурс файл для демонстрационного исполняемого файла;
9. **CianChatService.res** - ресурс файл для рабочего (сервиса) исполняемого файла;
10. **CianChatExecute.dpr** - проект для демонстрационного исполняемого файла;
11. **CianChatService.dpr** - проект для рабочего (сервиса) исполняемого файла;
12. **ini.Debug** 
   1.  **CianChatExecute.ini** - конфигурационный файл для демонстрационного исполняемого файла Debug;
   2.  **CianChatService.ini** - конфигурационный файл для рабочего (сервиса) исполняемого файла Debug;
13. **ini.Release** 
   1.  **CianChatExecute.ini** - конфигурационный файл для демонстрационного исполняемого файла Release;
   2.  **CianChatService.ini** - конфигурационный файл для рабочего (сервиса) исполняемого файла Release;
14. **bat** 
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

Рядом с исполняемым файлом сохраняется лог работы


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
#Адрес на который будет осуществляться пересылка
WebhooksURL=https://tone.setl.ru/
#Адрес по которому будет идентифицироваться токен
MainDescription=public-api.cian.ru
#Токен подключения к Циан
Token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjcxMTA0NzEwfQ.jsGkyyY_uOw_YskneXT_V2Iom0VVcp14UsUyXmq99c0
```

