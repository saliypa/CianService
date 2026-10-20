USE [re2a]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Author: Салий П.А.
-- Create date: 25.12.2024
-- Description:	Создание чата и/или добавление собщения в чат для Циан
-- Modify date: 2026-10-20 -- 
-- ===========================================================
---- GRANT EXEC ON [dbo].[VF_SetlTone_newChat_Cian] TO PUBLIC
CREATE OR ALTER PROCEDURE [dbo].[VF_SetlTone_newChat_Cian]
(
    @ExtChatId varchar(150)
  , @FromSite varchar(500) = ''
  , @FromSiteStr varchar(MAX) = ''
  , @ClientName varchar(255)
  , @Chat_Var varchar(255)
  , @Operator_Id int
  , @Message varchar(MAX)
)
as
begin
 set nocount on;
 set xact_abort on;

 declare
   @newchat bit = 0
 , @chat_id int = 0
 , @session_id int = 0
 , @agent_id int
 , @lock_result int
 , @message_code varchar(MAX)
 , @last_message varchar(MAX)

	---найдем клиента, на момент создания чата он должен уже быть
	select @session_id = objectid
		from attr865 with(nolock) where p9960 = @ExtChatId

	if (@clientname <> '' and isnull(@session_id,0) > 0)
	    update attr865
	    set p10252 = [dbo].[VF_WebGetSCode](@clientname)
	    where objectid = @session_id

 begin transaction;

	-- Сообщения одного треда обрабатываются строго по очереди: без блокировки два одновременных
	-- вызова не видят активного чата и создают два чата
	declare @lock_resource nvarchar(255) = N'VF_SetlTone_newChat_Cian:' + isnull(@Chat_Var,'')

	exec @lock_result = sp_getapplock
		  @Resource    = @lock_resource
		, @LockMode    = 'Exclusive'
		, @LockOwner   = 'Transaction'
		, @LockTimeout = 30000

	if @lock_result < 0
	begin
		rollback transaction;
		raiserror('VF_SetlTone_newChat_Cian: не удалось получить блокировку для чата %s', 16, 1, @Chat_Var);
		return
	end

	-- проверим есть ли активный чат и по чату определим оператора и сам чат
 	if exists (
 		select 1 from attr884 with (nolock) where p14989 = @Chat_Var and p10040 is null
 		)
 	begin
 		select @operator_id = p10038,
 		       @chat_id     = attr884.objectid
 		from   attr884 with (nolock)
 		       left join attr865 with (nolock)
 		            on  attr865.objectid = attr884.p10036
 		where  p14989 = @Chat_Var
 		       and p10040 is null
 		       and attr865.objectid = @session_id
 	end

	--если нет активного чата создаем (только для найденного клиента)
    if isnull(@chat_id,0) = 0 and isnull(@operator_id,0) > 0 and isnull(@session_id,0) > 0
    begin
		   insert into attr884
		     (
		       objectclassid,
		       p10036,
		       p10038,
		       p10041,
		       p10042,
		       p10611,
		       p14989
		     )
		   values
		     (
		       884,
		       @session_id,
		       @operator_id,
		       @fromsite,
		       @fromsitestr,
		       1,
		       @chat_var
		     )

		   set @newchat = 1

		   set @chat_id = scope_identity()
    end

	-- добавим сообщение в новый чат
    if isnull(@newchat,0) = 1
    begin
	  if isnull(@chat_id,0) > 0 and isnull(@message,'') <> ''
	  begin
		  insert into attr885
			(
			  objectclassid,
			  p10043,
			  p10045,
			  p10051,
			  p10052,
			  p10047
			)
		  values
			(
			  885,
			  @chat_id,
			  'оффер: ' + [dbo].[VF_SetWebLink](isnull(@fromsitestr, @fromsite)),
			  1, -- от клиента
			  @operator_id,
			  2
			)

	  end
    end

    ----добавим сообщение клиента
	-- Защита от повторной доставки: сравниваем только с последним сообщением клиента в чате.
	-- Раньше сравнение шло по всему чату, и повторное "Да" от клиента терялось
 	if isnull(@chat_id,0) > 0 and isnull(@message,'') <> ''
	begin
		set @message_code = [dbo].[VF_WebGetSCode](@message)

		select top 1 @last_message = p10045
		from attr885 with (nolock)
		where p10043 = @chat_id
		  and p10051 = 1 -- от клиента
		  and isnull(p10047,0) <> 2 -- не служебное сообщение с оффером
		order by objectid desc

		if isnull(@last_message,'') <> @message_code
		begin
		  insert into attr885
			(
			  objectclassid,
			  p10043,
			  p10045,
			  p10051,
			  p10052,
			  p21736
			)
		  values
			(
			  885,
			  @chat_id,
			  @message_code,
			  1, -- от клиента
			  @operator_id,
			  0
			)
		end
	end

 commit transaction;

	select
	isnull(@chat_id,0) as [chat_id],
	@ExtChatId as [user_id],
	@operator_id as [operator_id],
	@chat_var as [chat_var],
	isnull(@newchat,0) as [newchat]

end
