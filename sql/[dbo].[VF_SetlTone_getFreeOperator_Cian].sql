USE [re2a]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Author: Салий П.А.
-- Create date: 2025-06-19
-- Description:	Оператор для чатов Циан
-- Modify date: 2026-10-20 -- 
-- ===========================================================
-- GRANT EXEC ON [dbo].[VF_SetlTone_getFreeOperator_Cian] TO PUBLIC

--exec [dbo].[VF_SetlTone_getFreeOperator_Cian] @user_id = '1', @FromSite = 'public-api.cian.ru', @full_access = 1, @DebugMode = 1

CREATE OR ALTER PROCEDURE [dbo].[VF_SetlTone_getFreeOperator_Cian] 
	 @user_id varchar(150) = ''
	,@FromSite varchar(500) = ''
	,@full_access bit = 1
	-- ,@DebugMode bit = 0
AS
BEGIN	
 set nocount on;
	
 declare @myxml as xml	
 declare @session_id int
 declare @operator_id int
 declare @fiofull as varchar(50)
 declare @dolgn varchar(100) 
 declare @phone varchar(50)
 declare @noop bit = 0
 declare @chat_id int
	
 select @session_id = objectid
 from
	attr865 with(nolock)
 where
	p9960 = @user_id    		

 if isnull(@session_id,0) = 0 
  begin
	set @myxml = (
		select 
			'invalid_user' as [error],
			'Не определен клиент.' as [error_description]
		for xml path('getfreeoperator'), type
		)
    		
	select @myxml as myxml    		
    		
	return
 end	

-- ban	  
if (select count(objectid) from attr865 with(nolock) where objectid = @session_id and p10483 = 1) > 0 
 begin
	set @myxml = (
		select 
			'invalid_user' as [error],
			'Клиент забанен операторами. Плохой клиент' as [error_description]
		for xml path('getfreeoperator'), type
		)
    		
	select @myxml as myxml    		
    		
	return
 end	 	                                                                                                        	  

-- #region 1  
if isnull(@session_id,0) > 0 
 begin
  -- #region 2
  if not exists(select top 1 objectid from attr884 with(nolock) where p10036 = @session_id and p10040 is null) 
	begin -- exec sel_tab 884
		--------------------------------------------------------------------------------------------
		--вначале берутся операторы в статусе = 1, это те которые онлайн но нет ни одного чата
		--------------------------------------------------------------------------------------------
			-- из свободных берём того, у кого меньше архивных чатов, как и среди занятых (раньше всегда min(id))
			select top 1
				@operator_id = op.p10061
			from
				dbo.re2a_operatorsgrouptreefunc op
			where
				(p10357 = 1 and p10364 > 0)  -- статус 1 - это если оператор онлайн но у него нету не одного чата, по этому тут нету условий на количество чатов
				and
				(select dbo.vf_getoperatorsite(isnull(op.p10061,0), @fromsite, '')) = 1
			order by [dbo].[vf_webcountarhchats](op.p10061), op.p10061

		--------------------------------------------------------------------------------------------
		--если нету свободных, смотрим в статусе = 3, это те которые онлайн, но  уних есть чаты, типо "занят"
		--------------------------------------------------------------------------------------------
		if isnull(@operator_id,0) = 0
		begin			
		 select dbo.vf_webcountonlinechats(tuo.p10061) cc, [dbo].[vf_webcountarhchats](tuo.p10061) arhch, tuo.p10061 operator_id, tuo.p10364 maxchats, tuo.fiofull operator
			    into #ttt
				from dbo.re2a_operatorsgrouptreefunc tuo
			    where 
				tuo.p10357 = 3 -- статус 3 - это если оператор онлайн и у него есть хоть один чат.				
				and
				(select dbo.vf_getoperatorsite(isnull(tuo.p10061,0), @fromsite, '')) = 1		     				
				and  dbo.vf_webcountonlinechats(tuo.p10061) < tuo.p10364
			
			declare @op_id int, @cc int, @arhch int, @minarhch int
			if (select count(1) from #ttt) > 0 
			 begin
				select top 1 @cc = q.cc, @arhch = q.arhch, @op_id = q.operator_id 
				from #ttt q			 
				order by cc
             
				if (select count(1) from #ttt where cc = @cc) = 1
				 begin
					select @operator_id = @op_id
				 end    	
				else 
				 begin				
					select top 1
						@minarhch = min(arhch)
					from
						#ttt q
					where
						cc = @cc

					select top 1
						@operator_id = operator_id 
					from
						#ttt q
					where
						arhch = @minarhch and cc = @cc
				 end	
			 end
			     
			/*
			if @debugmode = 1		-- для теста из приложения
			 begin
				set @operator_id = 35016  --33937
				set @noop = 0		 
			 end		 
			*/		

			if  (isnull(@operator_id,0) > 0)
				select top 1 @fiofull = op.fiofull, @dolgn = isnull(op.dolgn_tochat, ''), @phone = isnull(op.p407,'8(812)33-55555')
				from dbo.re2a_operatorsgrouptreefunc op
				where op.p10061 = @operator_id
		end			
		else
		 begin
	   		select top 1
					@fiofull = op.fiofull,
					@dolgn = isnull(op.dolgn_tochat, ''),
					@phone = isnull(op.p407,'8(812)33-55555')
				from
					dbo.re2a_operatorsgrouptreefunc op
				where
					op.p10061 = @operator_id	
		 end		
		--------------------------------------------------------------------------------------------
		
		if isnull(@operator_id,0) = 0 -- вообще нет никого
		 begin
			select top 1 @fiofull = op.fiofull, @dolgn = isnull(op.dolgn, ''), @phone = isnull(op.p407,'')
			from dbo.re2a_operatorsgrouptreefunc op
			where objectid = 0  

			set @noop = 1
		 end	
		
		set @chat_id = 0
	end
	-- #endregion
	else 
	 -- есть чат
	 begin 	 
		select top 1
			@operator_id = op.p10061,
			@fiofull = op.fiofull,
			@dolgn = isnull(op.dolgn_tochat, ''),
			@phone = isnull(op.p407,'8(812)33-55555'),
			@chat_id = attr884.objectid ---есть чат с этим оператором
		from
			dbo.re2a_operatorsgrouptreefunc op
			inner join attr884 (nolock) on op.p10061 = attr884.p10038
		where
			attr884.p10036 = @session_id and attr884.p10040 is null           
	 end  
	 -- есть чат
end  
-- #endregion	

 declare @department varchar(100) = 'отдел: ---'

 -- set @phone02 = @phone   --показывать тел  
 if isnull((select top 1 p10400 from attr932 with(nolock) where p10360 = @operator_id),0) = 0
	set @phone = ''	 	
	
 -- скрыть информация для ксс
 if exists (
   select objectid
   from attr688
   where (p8280 = @operator_id)
   and (p8284 = 60) and (not exists (select 1 from attr688 where p8284 = 155 and p8280 = @operator_id))
 )
 begin
 	set @fiofull = ' оператор'
 	set @phone = ''
 	set @department = @department +' клиентская служба сервиса'
 end	
	
	
 if @full_access = 1 
  begin
   if @noop = 1 
    begin
	 select 
		'Добрый день!'+char(10)+'Благодарим, что обратились к нам.'+char(10)+'В ближайшее время с вами свяжется один из наших менеджеров.'+char(10)+' Пожалуйста, подождите.' as [error_description],
		0 as [res],
		0 as [operator_id]
	 return
	end		 	
end


 if @full_access = 1 
  begin
	declare
		@AutoAnswerText varchar(8000) = '';

	-- Автоответ нужен только для нового чата: при активном чате сервис его не отправляет,
	-- а каждый вызов сдвигает ротацию шаблонов в Attr1877
	if isnull(@chat_id,0) = 0
		exec [dbo].[VF_SetlTone_GetAutoAnswer_Cian]
		  @OperatorId=@operator_id
		 ,@TypesMsg=''
		 ,@ClientName=null
		 ,@AutoAnswerText=@AutoAnswerText output;


	select 	
		@AutoAnswerText as [description],
		1 as [res],
		@operator_id as [operator_id]	
		
		/*
		'Спасибо что обратились к нам!'+char(10)+
		'Вам ответит '+@dolgn+char(10)+
		@fiofull+char(10)--+'телефон: '+'8(812)33-55555'--+char(10)+@department --+'телефон: '+@phone as [description],		 
		as [description],
		1 as [res],
		@operator_id as [operator_id]
		*/
	return		
 end
	 
END