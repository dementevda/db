create database my_DB
go

use my_DB

/****** table create  ******/
create table E8_cat_price_list(
cat_number int not null primary key identity,
cat_name varchar(20) not null unique,
)

create table E5_price_list(
cat_number int not null references E8_cat_price_list on delete no action,
price_number int not null identity,
price_date date not null, 
primary key (cat_number,price_number),
)

create table E1_Arendator(
ID int not null primary key identity,
cat_number int not null references E8_cat_price_list on delete no action,
phone char(18) not null,
CHECK(phone LIKE '+7-([0-9][0-9][0-9])-[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
adress varchar(50)not null,
type_person int not null,
check (type_person=0 or type_person=1)
)

create table E7_doc_rent(
number_rent_doc int not null primary key identity,
cat_number int not null,
price_number int not null,
foreign key (cat_number,price_number) references E5_price_list on delete no action,
id int not null references E1_Arendator on delete no action,
date_execution date default getdate(),
date_paid datetime null,
date_leave date null,
date_return date null,
time_for_rent int not null,
check (date_paid > date_execution),
check (date_leave > date_paid),
check (date_return > date_leave),
check (time_for_rent>=0),
)

create table E6_doc_payment(
number_payment int not null primary key identity,
number_rent_doc int not null references E7_doc_rent on delete no action,
pay_type int not null check (pay_type=0 or pay_type=1),
date_paid datetime null,
paid_sum money null,
check (paid_sum >0),
)

create table E2_jur_person(
id int not null references E1_arendator on delete no action,
primary key (id),
inn char(12) not null,
check (len(inn)=12 and inn like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
kpp char(9) not null,
check (len(kpp)=9 and kpp like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
unique (inn,kpp),
firm_type varchar(5) not null,
firm_name varchar(20) not null,
license_number int not null,
bank_account varchar(15) not null,
check (firm_type in ('OOO','OAO','3AO')),
)

alter table E2_jur_person add constraint bank_only_num check (bank_account like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')

create table E3_private_person(
id int not null references E1_arendator on delete no action,
primary key (id),
passport_number char(11) not null unique ,
FIO varchar(50) not null,
birthday date not null,
issued_passport varchar(50) not null,
CHECK(passport_number LIKE '[0-9][0-9][0-9][0-9]¹[0-9][0-9][0-9][0-9][0-9][0-9]'),
)

alter table E3_private_person add constraint true_fio check (fio like '% % %')

create table E4_product(
article int not null primary key identity,
certificate_quality int not null unique,
product_name varchar(25) not null,
manufacturer varchar(15) not null,
quantity int not null,
package varchar(15) not null,
date_arrival date not null, 
check (quantity >= 0),
check (certificate_quality >= 0),
)

create table E9_pricelist_product(
cat_number int not null,
price_number int not null,
foreign key (cat_number,price_number) references E5_price_list on delete no action,
article int not null references E4_product on delete no action,
primary key (cat_number,price_number,article),
price money not null check (price>0)
)

create table E10_product_docrent(
article int not null references E4_product on delete no action,
number_rent_doc int not null references E7_doc_rent on delete no action,
primary key (article, number_rent_doc),
rent_quantity int not null,
price money null check (price>0),
)

insert E8_cat_price_list values ('vip'),('standart'),('bad')

alter table E1_arendator add default 2 for cat_number

go