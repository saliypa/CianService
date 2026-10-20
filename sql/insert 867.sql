begin transaction;

 begin try 
	if not exists (select 1 from Attr867 with(nolock) where p16050='Cian API')
		insert into Attr867 (ObjectClassID, p9965, p16050, p9966, p10540, p10541) values (867, 'https://public-api.cian.ru/', 'Cian API', '', 1, 0), (867, 'https://www.cian.ru/', 'Cian offers', '', 1, 0);


	if not exists (select 1 from Attr867 with(nolock) where p16050='Cian assignment API')
		insert into Attr867 (ObjectClassID, p9965, p16050, p9966, p10540, p10541) values (867, 'https://public-api.cian.assignment.ru/', 'Cian assignment API', '', 1, 0), (867, 'https://www.cian.assignment.ru/', 'Cian assignment offers', '', 1, 0);

	if not exists (select 1 from Attr867 with(nolock) where p16050='Cian FRT API')
		insert into Attr867 (ObjectClassID, p9965, p16050, p9966, p10540, p10541) values (867, 'https://public-api.cian.frt.ru/', 'Cian FRT API', '', 1, 0), (867, 'https://www.cian.frt.ru/', 'Cian fond razvitiia territorii offers', '', 1, 0);

	commit transaction;
	print 'ok'
 end try
 begin catch
	rollback transaction;
	print error_message();
 end catch;