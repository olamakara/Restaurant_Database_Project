CREATE function CheckIfCanBeBought(
@menuPositionId INT, @quantity INT)
    returns bit as
    begin
    if not exists(
        select menuPositionId from MenuPositions
        where menuPositionId = @menuPositionId
        and menuPositionId in (select c.menuPositionId from CurrentMenu c)
        and inStock >= @quantity
        )
    begin
         return 0
    end
    return 1
    end
go

CREATE function GetAvailableDoscountsForCustomerId(@id int)
    returns table
    as
    return
            (
            select discountType,disountId
            from Discounts
            where discountType = 0 and customerId = @id
            union
            select discountType,disountId
            from Discounts
            where discountType = 1 and customerId = @id
              and datediff(day,appliesSince,getDate()) <= (select paramVal from DiscountParameters
                                                        where paramName = 'D1' and endDate IS NULL)
              and Discounts.disountId not in (select DiscountHistory.discountId from DiscountHistory)
            )
go

CREATE function GetCustomerByOrderId(@id int)
    returns table
    as
    return select distinct firstName + ' ' + lastName as name, phone as 'nip/phone'
    from IndividualCustomers inner join Customers C on C.customerId = IndividualCustomers.customerId
    inner join Orders O on C.customerId = O.customerId
    where orderId = @id
union
    select distinct companyName as name, nip as 'nip/phone'
    from CompanyCustomers inner join Customers C on C.customerId = CompanyCustomers.customerId
    inner join Orders O on C.customerId = O.customerId
    where orderId = @id
go

create function GetCustomersThatOrderedMoreThanXValue(@x int)
    returns table as
    return
    select firstName + ' ' + lastName as ClientName, sum(OD.unitPrice * OD.quantity) as SumOrders, 'Individual' as ClientType
    from IndividualCustomers inner join Customers C on C.customerId = IndividualCustomers.customerId
inner join Orders O on C.customerId = O.customerId
inner join OrderDetails OD on O.orderId = OD.orderId
group by firstName + ' ' + lastName
having sum(OD.unitPrice * OD.quantity) > @x
union
select companyName as ClientName, sum(D.quantity * D.unitPrice) as SumOrders, 'Company' as ClientType
from CompanyCustomers inner join Customers C2 on C2.customerId = CompanyCustomers.customerId
inner join Orders O2 on C2.customerId = O2.customerId
inner join OrderDetails D on O2.orderId = D.orderId
group by companyName
having sum(D.quantity * D.unitPrice) > @x
go

CREATE function GetDiscountsValueByCustomerId(@id int) returns int
    as
    begin
        return (select isnull(sum(discountValue),0) from IndividualCustomers
        inner join Discounts D on IndividualCustomers.customerId = D.customerId
        inner join DiscountHistory DH on D.disountId = DH.discountId
        where IndividualCustomers.customerId = @id)
    end
go

CREATE function GetMenuByDay(@date date)
   returns table as
   return
   select d.dishName, c.categoryName, d.dishDescription, price
   from MenuPositions
   inner join Dishes d on d.dishId = MenuPositions.dishId
   inner join Categories c on c.categoryId = d.categoryId
   where (startDate <= @date and isnull(endDate, @date) >= @date)
go

CREATE function GetMostSoldDishOnDay(@date date) returns table
    as
    return (
        select top 1 Dishes.dishId, Dishes.dishName, sum(quantity) as "SoldQuantity" from Dishes
                      inner join MenuPositions MP on Dishes.dishId = MP.dishId
                      inner join OrderDetails OD on MP.menuPositionId = OD.menuPositionId
                      inner join Orders O on OD.orderId = O.orderId
                      where year(orderDate) = year(@date)
                      and month(orderDate) = month(@date)
                      and day(orderDate) = day(@date)
                      group by Dishes.dishId, Dishes.dishName
                      order by sum(quantity)desc )
go

create function GetNumberOfOrdersOnDay(@date date) returns int
    as
    begin
        return (select count(*) from Orders
                               where year(orderDate) = year(@date)
                               and month(orderDate) = month(@date)
                               and day(orderDate) = day(@date))
    end
go

create function GetOrderInfoByOrderId(@id int)
    returns table
    as
    return select dishName, quantity, price
    from Dishes inner join MenuPositions MP on Dishes.dishId = MP.dishId
    inner join OrderDetails OD on MP.menuPositionId = OD.menuPositionId
    where orderId = @id
go

CREATE function GetOrderValueByOrderId(@orderId int) returns money
    as
    begin
        return
        (
            select sum(quantity * MenuPositions.price) - isnull(
                (select discountValue from DiscountHistory
                where @orderId = DiscountHistory.orderId), 0)
            from OrderDetails inner join MenuPositions on OrderDetails.menuPositionId = MenuPositions.menuPositionId
            where orderId = @orderId
        )
    end
go

CREATE function GetOrdersByCustomerId(@id int)
    returns table as
    return
    select Orders.orderId ,orderDate, sum(quantity * unitPrice) as OrderValue
    from Orders inner join OrderDetails OD on Orders.orderId = OD.orderId
    where customerId = @id
    group by Orders.orderId, orderDate
go

create function GetSoldQuantityByDishID(@id int) returns int
    as
    begin
        return (select sum(quantity) as Quantity from Dishes
                         inner join MenuPositions MP on Dishes.dishId = MP.dishId
                         inner join OrderDetails OD on MP.menuPositionId = OD.menuPositionId
                         where Dishes.dishId = @id)
    end
go

create function GetValueOfOrdersOnDay(@date date) returns int
    as
    begin
        return (select sum(OD.quantity * OD.unitPrice) from Orders
                         inner join OrderDetails OD on Orders.orderId = OD.orderId
                         where year(orderDate) = year(@date)
                         and month(orderDate) = month(@date)
                         and day(orderDate) = day(@date))

    end
go

CREATE function GetXMostOftenSoldDishes(@id int) returns table
    as
    return
    select  top (@id) Dishes.dishId,Dishes.dishName, sum(quantity) as "UnitsSold" from Dishes
        inner join MenuPositions MP on Dishes.dishId = MP.dishId
        inner join OrderDetails OD on MP.menuPositionId = OD.menuPositionId
        group by Dishes.dishId, Dishes.dishName
        order by sum(quantity) desc
go

create function OrderedSeaFoodForTheWeekend(@thursday date)
    returns table as
    return
select * from SeaFoodFutureOrders
where (year(reservationCollectionDate) = year(@thursday) and
      month(reservationCollectionDate) = month(@thursday) and
      day(reservationCollectionDate) = day(@thursday)) or
      (year(reservationCollectionDate) = year(dateadd(day, 1, @thursday)) and
      month(reservationCollectionDate) = month(dateadd(day, 1, @thursday)) and
      day(reservationCollectionDate) = day(dateadd(day, 1, @thursday))) or
      (year(reservationCollectionDate) = year(dateadd(day, 2, @thursday)) and
      month(reservationCollectionDate) = month(dateadd(day, 2, @thursday)) and
      day(reservationCollectionDate) = day(dateadd(day, 2, @thursday)))
go

CREATE function shouldGetDiscountType0(@customerId int)
returns bit
as
begin
    if not exists (
        select * from IndividualCustomers
        where IndividualCustomers.customerId = @customerId
        )
    begin
        return 0
    end

    declare @Z1 INT
    select @Z1 = DP.paramVal
    from DiscountParameters DP
    where DP.paramName = 'Z1' and DP.endDate is null

    declare @K1 INT
    select @K1 = DP.paramVal
    from DiscountParameters DP
    where DP.paramName = 'K1' and DP.endDate is null

    declare @o INT
    select @o = count(*) from Orders
    where
        [dbo].GetOrderValueByOrderId(Orders.orderID) > @K1 and
        Orders.customerId = @customerId

    if @o >= @Z1
    begin
        return 1
    end

    return 0
end
go

CREATE function shouldGetDiscountType1(@customerId int)
returns bit
as
begin
    if not exists (
        select * from IndividualCustomers
        where IndividualCustomers.customerId = @customerId
        )
    begin
        return 0
    end

    declare @K2 INT
    select @K2 = DP.paramVal
    from DiscountParameters DP
    where DP.paramName = 'K2' and DP.endDate is null

    declare @o INT
    select @o = sum([dbo].GetOrderValueByOrderId(Orders.orderID)) from Orders
    where
        Orders.customerId = @customerId

    if @o >= @K2
    begin
        return 1
    end

    return 0
end
go