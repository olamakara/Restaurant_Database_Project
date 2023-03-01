create view AllDishes as
select dishName, categoryName, dishDescription from Dishes
inner join Categories C on C.categoryId = Dishes.categoryId
go

create view CheckTypeOfReservation as
select R1.reservationId, 'Company' as ReservationType
from Reservations R1 inner join CompanyReservations CR on R1.reservationId = CR.reservationId
union
select R2.reservationId, 'Individual' as ReservationType from Reservations R2 inner join IndividualReservations IR on R2.reservationId = IR.reservationId
go

CREATE view CompanyCustomersOrdersStats as
select ex.customerId as 'customerId', ex.companyName as 'companyName',
(
select count(*)
from Orders where Orders.customerId = ex.customerId
) as numberOfOrders,
(
select sum(OD.unitPrice * OD.quantity)
from Orders O inner join OrderDetails OD on O.orderId = OD.orderId
where O.customerId = ex.customerId
) as totalOrdersValue,
(
select top 1 orderDate
from Orders
where Orders.customerId = ex.customerId
order by orderDate desc
) as lastOrderDate
from CompanyCustomers ex
go

CREATE view CurrentMenu as
select menuPositionId, D.dishId, dishName, dishDescription, categoryName, price,inStock from MenuPositions
         inner join Dishes D on MenuPositions.dishId = D.dishId
            inner join Categories C on D.categoryId = C.categoryId
where endDate is null
go

CREATE view CurrentMenuChangedPositionsStats as
select ((
select count(*)
from DishesInMenuStats
where DishesInMenuStats.daysPassedSinceAdded > 14
) * 100 / (
select count(*)
from DishesInMenuStats
)) as percentOfMenuPositionsOlderThan2Weeks
go

create view DiscountsReportsMonthly as
select year(appliedDate) as 'year', month(appliedDate) as 'month', discountType,
       sum(discountValue) as 'totalDiscountsValue'
from DiscountHistory inner join Discounts D on DiscountHistory.discountId = D.disountId
group by year(appliedDate), month(appliedDate), discountType
go

create view DiscountsReportsWeekly as
select year(appliedDate) as 'year', datepart(week, appliedDate) as 'week', discountType,
       sum(discountValue) as 'totalDiscountsValue'
from DiscountHistory inner join Discounts D on DiscountHistory.discountId = D.disountId
group by year(appliedDate), datepart(week, appliedDate), discountType
go

CREATE view DishesInMenuStats as
select menuPositionId, D.dishName as 'dishName', datediff(day, MenuPositions.startDate, getdate()) as 'daysPassedSinceAdded'
from MenuPositions
inner join Dishes D on D.dishId = MenuPositions.dishId
where endDate is null
go

CREATE view DishesStatistic as
select dishName, sum(quantity) as sumOfBoughtDishes, max(orderDate) as lastOrderDate from MenuPositions
inner join Dishes D on D.dishId = MenuPositions.dishId
inner join OrderDetails OD on MenuPositions.menuPositionId = OD.menuPositionId
inner join Orders O on O.orderId = OD.orderId
group by dishName
go

create view DishesToPrepare as
select D.dishName as 'dishName', OD.quantity as 'quantity', orderCollectionDate as 'collectionDate', OD.orderId as 'orderId'
from Orders
inner join OrderDetails OD on Orders.orderId = OD.orderId
inner join MenuPositions MP on MP.menuPositionId = OD.menuPositionId
inner join Dishes D on MP.dishId = D.dishId
where orderCollectionDate >= getdate()
go

CREATE view FreeTables as
select distinct T.tableId, T.tableCapacity
from Tables T
where T.tableId not in (select Tables.tableId from Tables inner join Reservations R2 on Tables.tableId = R2.tableId
 where getdate() > startDate and getdate() <= isnull(endDate, getdate()))
go

CREATE view IndividualCustomersOrdersStats as
select ex.customerId as 'customerId', ex.firstName as 'customerFirstName', ex.lastName as 'customerLastName',
(
select count(*)
from Orders where Orders.customerId = ex.customerId
) as numberOfOrders,
(
select sum(OD.unitPrice * OD.quantity)
from Orders O inner join OrderDetails OD on O.orderId = OD.orderId
where O.customerId = ex.customerId
) as totalOrdersValue,
isnull((
select sum(discountValue)
from DiscountHistory inner join Discounts D on D.disountId = DiscountHistory.discountId
where D.customerId = ex.customerId
), 0) as totalDiscountValue,
(
select top 1 orderDate
from Orders
where Orders.customerId = ex.customerId
order by orderDate desc
) as lastOrderDate
from IndividualCustomers ex
go

create view OrderHistory as
select OD.orderId as 'orderId', customerId as 'customerId', orderDate, orderCollectionDate, sum(unitPrice * quantity) as totalPrice
from Orders
inner join OrderDetails OD on Orders.orderId = OD.orderId
group by OD.orderId, orderDate, orderCollectionDate, customerId, isTakeaway
go

create view OrdersToBePaid as
select Orders.orderId as 'orderId', customerId, sum(unitPrice * quantity) as toPay
from Orders inner join OrderDetails OD on Orders.orderId = OD.orderId
where isPaidBefore = 0 and orderCollectionDate >= getdate()
group by Orders.orderId, customerId
go

CREATE view SeaFoodFutureOrders as
select dishName, quantity, reservationCollectionDate, customerId, SeaFoodReservations.dishId
from SeaFoodReservations
inner join Dishes D on D.dishId = SeaFoodReservations.dishId
where reservationCollectionDate >= getdate()
go

create view TableReservationsReportMonthly as
select year(startDate) as 'year', month(startDate) as 'month', tableId, count(*) as 'numberOfReservations' from Reservations
group by year(startDate), month(startDate), tableId
go

create view TableReservationsReportWeekly as
select year(startDate) 'year', datepart(week, startDate) 'week', tableId as 'tableId', count(*) as 'numberOfReservations' from Reservations
group by year(startDate), datepart(week, startDate), tableId
go

CREATE view UnconfirmedReservations as
select C.customerId, Reservations.reservationId, tableCapacity, Reservations.startDate from Reservations
inner join Tables T on T.tableId = Reservations.tableId
inner join IndividualReservations IR on Reservations.reservationId = IR.reservationId
inner join Orders O on O.orderId = IR.orderId
inner join Customers C on C.customerId = O.customerId
where isAccepted = 0 and startDate > getdate()
union
select C2.customerId, r.reservationId, tableCapacity, r.startDate from Reservations as r
inner join Tables T on T.tableId = r.tableId
inner join CompanyReservations CR on r.reservationId = CR.reservationId
inner join CompanyCustomers CC on CC.customerId = CR.customerId
inner join Customers C2 on C2.customerId = CC.customerId
where isAccepted = 0 and startDate > getdate()
go

