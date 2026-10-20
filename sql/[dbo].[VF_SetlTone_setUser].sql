USE [re2a]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC VF_SetlTone_setUser @access_token = 'EFDB6F30-F54E-46BB-9272-3EB0CD2C9FFB', @user_id = 'pejdfdinvegmd11a3qyrhwSS07',@fromSite = 'lk.pn.ru',@fromSiteStr='https://lk.pn.ru', @ip='91.214.40.4',@device_id = '53324479c69212a0SS07'
-- Modify Date:			2023-02-03		Соколов Д.А.		IK2022-934 замена ссылок
 
CREATE OR ALTER PROCEDURE [dbo].[VF_SetlTone_setUser] 
@access_token VARCHAR(50)='', 
--@Token VARCHAR(50), 
@user_id VARCHAR(150),
@ip VARCHAR(50), 
@FromSite varchar(500) = '', 
@FromSiteStr varchar(max) = '',
--@GMT VARCHAR(10),
@mobile BIT = 0, 
@UserAgent VARCHAR(MAX) = '',
@device_id VARCHAR(255) = '',
@full_access BIT = 0


AS
BEGIN
	
	SET NOCOUNT ON;
	
	declare	@MyXml as XML	
	declare @Session_Id INT
	declare @SiteNavigate_Id INT
	
	IF @full_access = 0
	BEGIN		
	  IF NOT EXISTS(
		  SELECT ObjectID FROM Attr1232 WHERE P12416 = @access_token 
		  )	
		  BEGIN
			  SELECT @MyXml = (
			  SELECT 
			  'invalid_grant' AS [error],
			  'Отказано в авторизации.' AS [error_description]
			  FOR XML PATH('setUser'), TYPE
			  )
      		
			  select @MyXml AS MyXml    		
      		
			  RETURN
		  END
    END 
    
    
	select @Session_Id = ObjectID  -- exec sel_tab 865
	from Attr865 with(nolock) where p9960 = @user_id -- А здесь если вдруг записано в БД уже с символом
	
	IF ISNULL(@device_id,'') <> '' -- Если передали id-мобильника по нему берем user_id
	BEGIN 
    	IF EXISTS(SELECT 1 FROM attr865 INNER JOIN attr2029 ON attr2029.ObjectID = attr865.ObjectID WHERE attr2029.P18078 = @device_id) -- exec sel_tab '2029' select top 10 * from attr865
    	BEGIN
		  select 
		  @Session_Id = Attr865.ObjectID,  -- exec sel_tab 865
		  @user_id = Attr865.p9960
		  from Attr865 with(nolock) INNER JOIN attr2029 ON attr2029.ObjectID = attr865.ObjectID WHERE attr2029.P18078 = @device_id 
    	END
    	ELSE
    	BEGIN
		  IF ISNULL(@Session_Id,0) = 0
		  BEGIN
		  	
		    select @user_id = REPLACE(@user_id,'~','X') -- По просьбе безопасников убираем '~' т.к. WAF типа не пропускает такой символ
		  	
			insert into Attr865 (ObjectClassID ,p9960, p9961, p9963, p9964, p17604/*, p12417*/)  -- exec sel_tab 865
			values (865, @user_id, @IP, @FromSite, @FromSiteStr, @mobile/*, @Token*/)
      	  
			SET @Session_Id = SCOPE_IDENTITY()
		  end
    			INSERT INTO attr2029(ObjectID, P18078)
    			VALUES(@Session_Id,@device_id)
    	END
    END 	 	
    
	IF ISNULL(@Session_Id,0) = 0
	BEGIN
		
	  select @user_id = REPLACE(@user_id,'~','X') -- По просьбе безопасников убираем '~' т.к. WAF типа не пропускает такой символ	
	  
	  insert into Attr865 (ObjectClassID ,p9960, p9961, p9963, p9964, p17604/*, p12417*/)  -- exec sel_tab 865
	  values (865, @user_id, @IP, @FromSite, @FromSiteStr, @mobile/*, @Token*/)
	  
	  SET @Session_Id = SCOPE_IDENTITY()
	end  
  
  
   select @user_id = REPLACE(@user_id,'~','X') -- По просьбе безопасников убираем '~' т.к. WAF типа не пропускает такой символ			
   
   insert into Attr889(ObjectClassID,p10069, p10071, p10074, p10075, P10165, p11344, P11386) -- exec sel_tab '889'
   values(889,@Session_Id, @user_id, @FromSite, @FromSiteStr, @IP, @mobile, @UserAgent)   	
   
   SET @SiteNavigate_Id = SCOPE_IDENTITY()
		   
--	exec VF_WebGetGeoIP @IP, 'GMT 0', 0, @SiteNavigate_Id	  
	
IF @full_access = 1
BEGIN
	SELECT @user_id AS [user_id]
	RETURN 
END
	
	  SELECT @MyXml = (
		  SELECT 
		  @user_id AS [user_id]
		  FOR xml path ('setUser') --, root('setUser')
		  )
  	
	  select @MyXml AS MyXml	
	
	 
END