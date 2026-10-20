USE [re2a]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Author: Салий П.А.
-- Create date: 2025-08-01
-- Description:	Получение автоответа для чат Циан
-- Modify date: 2026-10-20 -- 
-- ===========================================================
-- GRANT EXEC ON [dbo].[VF_SetlTone_GetAutoAnswer_Cian] TO PUBLIC
CREATE OR ALTER PROCEDURE [dbo].[VF_SetlTone_GetAutoAnswer_Cian]
(
	 @OperatorId int
	,@TypesMsg varchar(500) = ''
	,@ClientName varchar(255) = null
	,@AutoAnswerText varchar(8000)	= '' output
)
as
begin
 set nocount on;

 -- '-' по умолчанию: если оператора нет в Attr6, select не меняет переменную,
 -- и Replace с NULL обнулял весь текст автоответа
 declare
	@OperatorName varchar(255) = '-'

 select
	@OperatorName=isnull(nullif(rtrim(isnull(Attr6.p38,'')),''),'-') --	sel_tab 6
 from Attr6  with (nolock)
 where
	Attr6.ObjectID=@OperatorId

 set @AutoAnswerText=
		'Спасибо что обратились к нам!'+char(10)+
		'Вам ответит оператор %OperatorName%';


 declare
	@AutoAnswerId int = null,
	@AutoAnswerTemplate varchar(8000) = null;

 select top 1
	 @AutoAnswerId = Attr1877.ObjectId
	,@AutoAnswerTemplate = Attr1877.p17207
 from Attr1877 (nolock)
 where Attr1877.ObjectId in (1,2,3,4)
 order by Attr1877.p17213

 -- пустой шаблон не затирает текст по умолчанию
 if isnull(@AutoAnswerTemplate, '') <> ''
	set @AutoAnswerText = @AutoAnswerTemplate


 --Апдейтим дату этого шаблона чтобы в следующий раз брать другой 	
 if (@AutoAnswerId is not null)
	update Attr1877 set Attr1877.p17213 = getdate() where Attr1877.ObjectID = @AutoAnswerId		--	select * from Attr1877

 --делаем реплейс
 if isnull(@AutoAnswerText, '') <> ''
	set @AutoAnswerText = Replace(@AutoAnswerText, '%OperatorName%', @OperatorName)
end

/*
	declare
		@AutoAnswerText varchar(8000);    

	exec [dbo].[VF_SetlTone_GetAutoAnswer_Cian]
	  @OperatorId=101462
	 ,@TypesMsg=''
	 ,@ClientName=null
	 ,@AutoAnswerText=@AutoAnswerText output;

	select @AutoAnswerText
*/