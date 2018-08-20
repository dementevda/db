/******  #1  ******/
select	
	e4.product_name+' - art. '+cast(e4.article as varchar(3)) as name_art,
	e4.manufacturer, 
	e4.quantity, 
	sum(e10.rent_quantity)as in_rent,
	SUM(case when (ISNULL(e7.date_return,getdate())>(DATEADD(day,e7.time_for_rent,e7.date_leave)))then e10.rent_quantity else 0 end) as bad_rent 
	from E4_product e4
left join E10_product_docrent e10 on e4.article = e10.article 
left join e7_doc_rent e7 on e10.number_rent_doc=e7.number_rent_doc
	
group by e4.article, e4.product_name, e4.manufacturer, e4.quantity
order by e4.article


/******  #2  ******/
select 
	e1.cat_number,
	isnull(E2.firm_name,e3.fio) as name,
	e1.adress, 
	e1.phone, 
	count(distinct e7.number_rent_doc) as cont_docrent,
	SUM(e10.price) as sum_price,
	SUM(e6.paid_sum) as paid, 
	sum(case when ((ISNULL(e7.date_return,getdate())>(DATEADD(day,e7.time_for_rent,e7.date_leave))))then 1 else 0 end) as bad_rent_doc,
	sum(case when ((ISNULL(e7.date_return,getdate())>(DATEADD(day,e7.time_for_rent,e7.date_leave))))
		then cast(e10.price*0.01*(datediff(day,(DATEADD(day,e7.time_for_rent,e7.date_leave)),ISNULL(e7.date_return,getdate()))) as dec(20,2)) else 0 end) as penalty,
	sum(distinct case when ((e7.date_leave is not null)and(e7.date_return is null)) then 1 else 0 end) as not_return
from E1_Arendator e1
left join E2_jur_person e2 on e1.ID=e2.id
left join E3_private_person e3 on e1.ID=E3.id
left join E7_doc_rent e7 on e7.id=e1.ID
left join E10_product_docrent e10 on e10.number_rent_doc=e7.number_rent_doc
left join E6_doc_payment e6 on e7.number_rent_doc=e6.number_rent_doc

group by e1.cat_number,e2.firm_name,e3.FIO,e1.adress,e1.phone,e1.ID
order by e1.cat_number

/******  #3  ******/

with s3(name_art,sum_time_rent,avg_time_rent,maxcount_docrent,count_id,sum_price,quantity,quatity_in_rent) as
(select 
	e4.manufacturer+' - art. '+cast(e4.article as varchar) as name_art,
	SUM(e7.time_for_rent) as sum_time_rent,
	avg(e7.time_for_rent) as avg_time_rent,
	count(e10.article) as count_docrent,
	COUNT(distinct e1.id) as count_id,
	SUM(e10.price) as sum_price,
	e4.quantity,
	SUM(e10.rent_quantity) as quatity_in_rent
from E4_product e4 
left join E10_product_docrent e10 on e4.article=e10.article
join E7_doc_rent e7 on e10.number_rent_doc=e7.number_rent_doc
join E1_Arendator e1 on e1.id=e7.id

group by e4.article,e4.manufacturer,e4.quantity
)

select * from s3 where sum_time_rent=(select max(sum_time_rent)from s3)

/******  #4  ******/

with s4(cat_number,name,adress,phone,cont_docrent,sum_price,paid,rent_quantity,on_hands,sum_time_rent) as (
select
	e1.cat_number,
	isnull(E2.firm_name,e3.fio) as name,
	e1.adress, 
	e1.phone, 
	count(distinct e7.number_rent_doc) as cont_docrent,
	SUM( e10.price) as sum_price,
	SUM(distinct e6.paid_sum) as paid,
	SUM(e10.rent_quantity) as rent_quantity,
	sum( case when ((e7.date_leave is not null)and(e7.date_return is null)) then e10.rent_quantity else 0 end ) as on_hands,
	sUM(e7.time_for_rent) as sum_time_rent
from E1_Arendator e1
left join E7_doc_rent e7 on e7.id=e1.ID
left join E2_jur_person e2 on e1.ID=e2.id
left join E3_private_person e3 on e1.ID=E3.id
left join E10_product_docrent e10 on e7.number_rent_doc=e10.number_rent_doc
left join E6_doc_payment e6 on e7.number_rent_doc=e6.number_rent_doc

group by e2.firm_name,e3.FIO,e1.adress,e1.phone,e1.cat_number,e7.id
)

select * from s4 where cont_docrent=(select MAX(cont_docrent) from s4)

/******  #5  ******/
with s5(cat_name,avg_art_un_price,art_in_cat,count_ndr,count_id,id_execution) as (
select
	e8.cat_name,
	avg(e9.article) as avg_art_un_price,
	count(distinct e9_1.article) as art_in_cat,
	count(distinct e7.number_rent_doc) as count_ndr,
	COUNT(distinct e1.id) as count_id,
	count(distinct  e7.ID) as id_execution
from E8_cat_price_list e8
join E5_price_list e5 on e8.cat_number=e5.cat_number
join E9_pricelist_product e9 on e5.price_number=e9.price_number
join E9_pricelist_product e9_1 on e5.cat_number=e9.cat_number
join E7_doc_rent e7 on e8.cat_number=e7.cat_number
join E1_Arendator e1 on e8.cat_number=e1.cat_number

group by e8.cat_name
order by count_ndr desc
)

select * from s5 WHERE count_ndr=(select MAX(count_ndr) from s5)