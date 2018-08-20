/****** trigger1  ******/
create trigger trigger1 on E6_doc_payment 
instead of insert,update
as
declare @ndr int --number rent doc
declare @pt int -- pay type
declare @ps money -- paid sum
declare @ns money -- need sum
set @ndr=(select  number_rent_doc from inserted)
set @ps=(select paid_sum from inserted)
set @ns=(select sum(price) from E10_product_docrent where number_rent_doc=@ndr)
begin
	if not exists (select number_rent_doc from E6_doc_payment where number_rent_doc=@ndr)
		begin
			if exists (select number_rent_doc from E7_doc_rent where number_rent_doc=@ndr)
				begin
					if (@ps = @ns)
						begin
							insert into E6_doc_payment(number_rent_doc,pay_type,date_paid,paid_sum) values (@ndr,(select pay_type from inserted),GETDATE(),@ps)
							update E7_doc_rent set date_paid=GETDATE() where number_rent_doc=@ndr
						end
					else
						begin
							raiserror ('the amount paid is not correct',11,1)
							rollback transaction
						end
				end
			else 
				begin 
					raiserror ('document does not exist',11,1)
					rollback transaction
				end
		end
	else
		begin
			raiserror ('this order is alredy paid',11,1)
			rollback transaction
		end
end
go

/****** trigger2  ******/
create trigger trigger2 on E10_product_docrent 
after insert,update 
as
declare @ndr int
declare @art int
declare @nqu int --need quantity
declare @hqu int --have quantity
declare @uqu int --update quantity
declare @curpr money --current price
declare @interval int
set @ndr=(select number_rent_doc from inserted)
set @art=(select article from inserted)
set @nqu=(select rent_quantity from inserted)
declare @pl int = (select price_number from E7_doc_rent where number_rent_doc=@ndr)
set @hqu=(select quantity from E4_product where article=@art)
set @uqu=(select rent_quantity from deleted where article=@art and number_rent_doc=@ndr) 
set @curpr=(select price from E9_pricelist_product where (article=@art and price_number=@pl))
set @interval=(select time_for_rent from E7_doc_rent where number_rent_doc=@ndr)
	if (@uqu is NULL) 
		begin
			set @uqu=0
		end
	if not exists (select number_rent_doc from E6_doc_payment where number_rent_doc=@ndr)
		begin
							if  (@nqu<=(@hqu+@uqu))
								begin
											update E4_product set quantity=@hqu+@uqu-@nqu where article=@art
											update E10_product_docrent set price=(@nqu*@curpr*@interval) where article=@art and number_rent_doc=@ndr
								end
							else
								begin
									raiserror ('the required quantity is not in stock',11,1)
									rollback transaction
								end	
		end
	else
		begin
			raiserror ('this order is alredy paid',11,1)
			rollback transaction
		end
go