
create database if not exists testdb;

use testdb;

create table transactions(
	id INT auto_increment,
	customer_id int not null,
	order_id varchar(255) not null,
	transaction_date timestamp,
	status varchar(255),
	vendor varchar(255),
	primary key (id)
);

INSERT into transactions(customer_id, order_id, transaction_date, status, vendor)
values (422818,'TEST000001','2018-01-01 00:00:10','SHIPPED','Vendor A'),
(181820,'TEST000002','2018-01-01 00:10:09','SHIPPED','Vendor A'),
(999019,'TEST000003','2018-01-02 03:18:01','CANCELLED','Vendor A'),
(1923192,'TEST000004','2018-02-04 04:59:59','CANCELLED','Vendor C'),
(645532,'TEST000005','2018-02-10 16:00:09','SHIPPED','Vendor C'),
(1101011,'TEST000006','2018-02-11 11:00:11','SHIPPED','Vendor C'),
(1020000,'TEST000007','2018-02-10 00:00:00','SHIPPED','Vendor D'),
(40111234,'TEST000008','2018-03-11 06:30:11','SHIPPED','Vendor D'),
(1923192,'TEST000009','2018-03-12 10:00:11','CANCELLED','Vendor B'),
(1101011,'TEST000010','2018-03-12 15:30:11','SHIPPED','Vendor B'),
(999019,'TEST000011','2018-03-15 12:30:44','CANCELLED','Vendor A'),
(645532,'TEST000012','2018-04-01 09:30:22','SHIPPED','Vendor A'),
(650013,'TEST000013','2018-04-01 10:50:36','SHIPPED','Vendor C'),
(777734,'TEST000014','2018-04-02 13:45:19','SHIPPED','Vendor D');


-- PART 1 --

-- 1 --
select * from transactions
where (month(transaction_date) = 2
	and year(transaction_date) = 2018
	and lower(status) = 'shipped');

-- 2 --
select * from transactions
where ((hour(transaction_date) BETWEEN 0 and 9)
	and lower(status) = 'shipped');

-- 3 --
with lt as (
	select max(transaction_date) td, vendor from transactions
	group by vendor
)
select t.id, t.customer_id, t.order_id, t.transaction_date, t.vendor from transactions t
join lt on lt.td = t.transaction_date
	and lt.vendor = t.vendor;

-- 4 --
with lst as (
	select max(transaction_date) td, vendor from transactions
	where transaction_date not in (select max(transaction_date) from transactions group by vendor)
	group by vendor
)
select t.id, t.customer_id, t.order_id, t.transaction_date, t.vendor from transactions t
join lst on lst.td = t.transaction_date
	and lst.vendor = t.vendor;

--5--
select date(transaction_date) td, vendor, count(id) from transactions
where lower(status) = 'cancelled'
group by td, vendor
order by td;

-- 6 --
with ts as (
	select customer_id, count(status) t from transactions
	where lower(status) = 'shipped'
	group by customer_id
)
select customer_id from ts
where ts.t > 1;

-- 7 --
with ts as (
	select vendor, count(vendor) total from transactions
	where lower(status) = 'shipped'
	group by vendor
),
tc as (
	select vendor, count(vendor) total from transactions
	where lower(status) = 'cancelled'
	group by vendor
),
lv as (
	select DISTINCT vendor from transactions
),
s as (
	select lv.vendor,
		(COALESCE(ts.total,0) + COALESCE(tc.total,0)) total_transaction,
		COALESCE(ts.total,0) shipped,
		COALESCE(tc.total,0) cancelled from lv
	left join ts on ts.vendor = lv.vendor
	left join tc on tc.vendor = lv.vendor
),
vc as (
	select vendor, total_transaction,
		if(shipped > 2, if(cancelled > 0, 'Good', 'Superb'), 'Normal') as category
	from s
	order by (
	case category 
		when 'Superb' then 0 
     	when 'Good' then 1
     	when 'Normal' then 2
    end), total_transaction DESC
)
select * from vc;

