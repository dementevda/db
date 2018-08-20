/****** proc1  ******/
create procedure proc1 
	@art int,
	@cert int = null,
	@name varchar(25) =null,
	@manuf varchar(15)=null,
	@nqu int=null,
	@pack varchar(15)=null,
	@arrival date=null,
	@msg varchar(100) output
as
	if not exists(select article from E4_product where article=@art)
		begin
			set @msg=('this product does not exist')
			return
		end;
	if (@arrival<=(select date_arrival from E4_product where article=@art))
		begin
			set @msg='date of arrival is not correct'
			return
		end;
	if (exists (select certificate_quality from E4_product where certificate_quality=@cert) and ((select certificate_quality from E4_product where article=@art)!=@cert))	
		begin
			set @msg='not a valid certificate of quality'
			return 	
		end;
	if (@name is not null)	update E4_product set product_name=@name where article=@art
	if ((@nqu is not null) and (@nqu>0))
			begin
				update E4_product set quantity=(select quantity from E4_product where article=@art)+@nqu where article=@art
			end
	else
			begin
				set @msg='quantity of goods is not correct'
				return
			end
if (@name is not null)	update E4_product set product_name=@name where article=@art
if (@manuf is not null)	update E4_product set manufacturer=@manuf where article=@art
if (@pack is not null)	update E4_product set package=@pack where article=@art
if (@arrival is not null)update E4_product set date_arrival=@arrival where article=@art
if (@cert is not null) update E4_product set certificate_quality=@cert where article=@art
declare @printqu int
set @printqu=(select quantity from E4_product where article=@art)
set @name=(select product_name from E4_product where article=@art)
set @msg='quantity '+@name+'(art.'+cast (@art as varchar)+') = '+cast (@printqu as varchar)
go

/****** proc2  ******/
create procedure proc2
	@str varchar(max),
	@msg varchar(100) output
as
	set @str=replace(@str,' ','')
	declare @parser char =','
		set @str=(select @str + @parser)
	declare @t table (find int identity, product int, quantity int)
	declare @pos int = charindex(@parser,@str)
	declare @prod nvarchar(4)
	declare @count nvarchar(4)
	declare @test int = (select len(@str)-LEN(replace(@str,',','')))	
if ((@test%2)!=0)
	begin
		set @msg='not the correct number of parameters'
		return
	end
if (@str like '%[A-z]%')
	begin
		set @msg='can not enter letters'
		return
	end
declare @id int = SUBSTRING(@str, 1, @pos-1)
		set @str = SUBSTRING(@str, @pos+1, LEN(@str))
		set @pos = CHARINDEX(@parser,@str)
if not exists (select ID from E1_Arendator where ID=@id)
	begin
		set @msg='there is no such tenant'
		return 
	end
declare @time int = SUBSTRING(@str, 1, @pos-1)
		set @str = SUBSTRING(@str, @pos+1, LEN(@str))
		set @pos = CHARINDEX(@parser,@str)
if (@time<1)
	begin
		set @msg='you can not rent less than a day'
		return
	end
if (@pos=0)	
	begin
		set @msg='you can not rent less than a day'
		return
	end	
declare @test_of_prod int =0
while (@pos != 0)
	begin
		set @prod = SUBSTRING(@str, 1, @pos-1)
		set @str = SUBSTRING(@str, @pos+1, LEN(@str))
		set @pos = CHARINDEX(@parser,@str)	
		set @count = SUBSTRING(@str, 1, @pos-1)
		set @str = SUBSTRING(@str, @pos+1, LEN(@str))
		set @pos = CHARINDEX(@parser,@str)
		if not exists (select article from E4_product where article=@prod)
			begin
				raiserror ('goods does not exist',11,1)
				continue
			end
		if ((select quantity from E4_product where article=@prod)<@count)
			begin
				raiserror ('The required quantity is not in stock',11,1)
				continue
			end	
		if ((select COUNT(product) from @t where product=@prod)>0)
			begin
				raiserror ('This product has already been ordered',11,1)
				continue
			end
		insert into @t values ((cast(@prod as int)),(cast(@count as int)))
		set @test_of_prod=@test_of_prod+1
	end
if (@test_of_prod=0)
			begin
				set @msg='empty order'
				return
			end
insert into E7_doc_rent(cat_number,price_number,id,time_for_rent) values ((select cat_number from E1_Arendator where ID=@id),
		 (select MAX(price_number) from E5_price_list where cat_number=(select cat_number from E1_Arendator where ID=@id)),@id,@time)
	
set @test=(select MAX(find) from @t)
while (@test!=0)
	begin
		set @count=(select quantity from @t where find=@test)
		set @prod=(select product from @t where find=@test)
		insert into E10_product_docrent(article,number_rent_doc,rent_quantity) values (@prod,(select MAX(number_rent_doc) from E7_doc_rent),@count)
		set @test=@test-1
	end

declare @ndr int =(select MAX(number_rent_doc) from E7_doc_rent)
declare @price money = (select sum(price) from E10_product_docrent where number_rent_doc=@ndr)
set @msg='Order price ¹'+cast (@ndr as varchar)+' = '+cast (@price as varchar)
go

/****** proc3  ******/
create table E11_log_file(
id int not null unique,
last_date datetime not null default (getdate()),
count_docrent int null,
sum_docrent money null
)
go
alter procedure proc3
as
begin

declare @lastdate date
declare @id int
declare @sum money
declare @count int
declare @old int

merge e11_log_file as a
using e1_arendator as b
on a.id=b.id
when not matched by source then delete
when not matched by target then
insert (id,last_date,count_docrent,sum_docrent) values (b.id,default,(select count(number_rent_doc) from E7_doc_rent where b.id=id),(select SUM(price) from E10_product_docrent where number_rent_doc in (select number_rent_doc from E7_doc_rent where id=b.id)));
declare my_cur cursor
	for select * from E11_log_file 
	open my_cur
		fetch next from my_cur into @id,@lastdate,@count,@sum
		while @@FETCH_STATUS=0
			begin
				set @old=@count
				update e11_log_file set count_docrent=(select count(number_rent_doc) from E7_doc_rent where id=@id) where ID=@id
				set @count=(select count_docrent from e11_log_file where ID=@id)
				if (isnull(@old,0)!=@count)
					begin
						update e11_log_file set last_date=GETDATE() where ID=@id
						update e11_log_file set sum_docrent=(select SUM(price) from E10_product_docrent where number_rent_doc in (select number_rent_doc from E7_doc_rent where id=@id)) where ID=@id
					end;
				fetch next from my_cur into @id,@lastdate,@count,@sum
			end
	close my_cur
	deallocate my_cur
end
go

/****** exec_plan  ******/
create table E12_log_file_exec_plan(
id int not null unique,
last_date datetime not null default (getdate()),
count_docrent int null,
sum_docrent money null
)
go

alter procedure proc4_exec_plan
as
begin
declare @lastdate date
declare @id int
declare @count int
declare my_cur1 cursor
	for select ID from E1_Arendator 
	open my_cur1
		fetch next from my_cur1 into @id
		while @@FETCH_STATUS=0
			begin
				if not exists (select id from e12_log_file_exec_plan where ID=@id)
					begin
						insert into e12_log_file_exec_plan(id) values (@id)
					end;
				set @count=(select count_docrent from e12_log_file_exec_plan where ID=@id)
				set @lastdate=(select last_date from e12_log_file_exec_plan where ID=@id)
				if (isnull(@count,0)!=(select count(distinct number_rent_doc) from E7_doc_rent where id=@id))
					begin
						update e12_log_file_exec_plan set count_docrent=(select count(distinct number_rent_doc) from E7_doc_rent where id=@id)where ID=@id
						update e12_log_file_exec_plan set sum_docrent=(select SUM(price) from E10_product_docrent where number_rent_doc in (select number_rent_doc from E7_doc_rent where id=@id)) where ID=@id
						update e12_log_file_exec_plan set last_date= GETDATE() where ID=@id
					end
				
				fetch next from my_cur1 into @id
			end
	close my_cur1
	deallocate my_cur1
end
go

