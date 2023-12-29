drop table if exists portugal_prop ;
create table portugal_prop(
district text,
rooms varchar(15),
price int,
area numeric,
bathrooms smallint,
conditions varchar(25),
adstype varchar(10) check(adstype in ('Rent', 'Vacation', 'Sell')),
property_type varchar(10)
);
-- using '\copy' we copied 62658 rows.


/** Create "portugal_prop_clean" table by only keep name of district name from "portugal_prop" table 'district' column .
We will use new table only and keep main table 'portugal_prop' untouched. **/
drop table if exists portugal_prop_clean ;
create table portugal_prop_clean as (
select 
	split_part(district, ',', -1) as district,
	rooms,
	price,
	area,
	bathrooms,
	conditions,
	adstype,
	property_type
	from 
	portugal_prop
)

--1)We have a space in beginning or after in 'district' column value .
   select district , 
       length(district), 
       length(trim(both ' ' from district)) as after_trim
   from portugal_prop_clean ;

--Remove begining and ending spaces from district column
update portugal_prop_clean
set district = trim(both ' ' from district) ;


--2)District column
    select *
    from portugal_prop_clean
    where district is null    -- NO NULL ROWS

--3)rooms column 
    select distinct rooms , 
	count(*)
    from portugal_prop_clean
    group by 1
    order by rooms asc
--NO NULL VALUE, 11 distinct types.We change '10 ou superior' to '10' and data type to int .
   update portugal_prop_clean
   set rooms = 10
   where rooms = '10 ou superior'  ;

   alter table portugal_prop_clean
   alter column rooms type int using rooms::int;


--4)price column 
    select count(*) as num_of_Pricenull ,
	        round((100.00 * count(*) / (select count(*) from portugal_prop_clean)),2) as null_percentage
    from portugal_prop_clean
    where price is null
/** 1170 rows have null value in 'price' column, which is  1.87 % of total rows . So we delete thoes 1170 rows and now we
have   61488 rows **/
     delete from portugal_prop_clean
     where price is null ;

--5)area column
    select *
    from portugal_prop_clean
    where area is null    -- no null rows

--6)bathrooms 
    select * 
    from portugal_prop_clean
    where bathrooms is null   
--12282 rows do not have bathrooms, so we set 1 bathrooms for all null values.
    update portugal_prop_clean
    set bathrooms = '1'
    where bathrooms is null ;

--7)conditions
    select * 
    from portugal_prop_clean
    where conditions is null
--24665 rows are null , we update and fill with 'Used' 
    update portugal_prop_clean
    set conditions = 'Used'
    where conditions is null

--8)adstype column
    select *
    from portugal_prop_clean
    where adstype is null  -- no null rows

--9)property_type
   select *
   from portugal_prop_clean
   where property_type is null  --no null rows 


--10)duplicate rows with all columns same .
   with cte as (
      select * ,  
         rank()  over(partition by district, rooms, price, area, bathrooms, conditions, adstype, property_type) as rnk
   from portugal_prop_clean
    )
      select *
      from cte
      where rnk > 1       --no duplicate


--11)numbers of adstypes and their max and min price .
     select adstype, 
	     count(*) as num_count, 
		      max(price) as maximum_price , 
		     	     min(price) as minimum_price
     from portugal_prop_clean
     group by 1


--12)average room price in different district by different adstypes . 
     select distinct district,
	     adstype ,
		     (sum(price)/ sum(rooms)) as avg_price_for_room
     from portugal_prop_clean 
     group by 1 , 2
     order by district, adstype ,(sum(price)/ sum(rooms)) desc
 
 
--13)average price for different adstypes for per 100 area . 
      select distinct district, 
	      adstype , 
		      round(100 * sum(price)/ sum(area), 2) as price_per_100_area
	  from portugal_prop_clean  
	  group by 1, 2

--14)Rooms Count
     select rooms, 
	      count(*)
     from portugal_prop_clean
     group by 1
     order by 1 asc

--15)Average Rental Prices by Number of Rooms
      select rooms, 
	      round(avg(price), 2) as avg_price
      from portugal_prop_clean
      where adstype = 'Rent'
      group by 1
      order by 1 asc
--There is one property in libon, i.e 0 rooms and 3 bathrooms for 250000,which increase the overall average price for 0 rooms properties. 

   
--16)Largest Rental Properties: Selecting Those with Areas Above the 90th Percentile .
     select *
     from portugal_prop_clean
     where area > (select percentile_cont(0.9) within group (order by area) as largest_area
     from portugal_prop_clean )
          and adstype = 'Rent'
  ;

--17)Smallest Rental Properties: Areas Below the 5th Percentile
     select *
     from portugal_prop_clean
     where area < (select percentile_cont(0.05) within group (order by area) as smallest_area
            from portugal_prop_clean )
     and adstype = 'Rent'
  ;  
  
--18)Expensive Rental Properties: Prices Above the 90th Percentile .
      select *
      from portugal_prop_clean
      where price > (select percentile_cont(0.9) within group (order by price) as largest_price
          from portugal_prop_clean )
      and adstype = 'Rent'
  ; 
 
--19)Affordable Rental Properties: Prices Below the 5th Percentile
     select *
     from portugal_prop_clean
     where price < (select percentile_cont(0.05) within group (order by price) as largest_price
         from portugal_prop_clean )
     and adstype = 'Rent'
  ; 
 