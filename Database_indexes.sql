create index isAcceptedAndStartDate
    on Reservations (isAccepted, startDate)
go

create index reservationIdAndIsAccepted
    on Reservations (reservationId, isAccepted)
go

create index tableIdAndIsAcceptedAndStartDateAndEndDate
    on Reservations (tableId, isAccepted, startDate, endDate)
go

create index startDateAndEndDate
    on Reservations (startDate, endDate)
go

create index reservationCollectionDate
    on SeaFoodReservations (reservationCollectionDate)
go

create index isPaidAndCollectionDate
    on Orders (isPaidBefore, orderCollectionDate)
go

create index orderDate
    on Orders (orderDate)
go

create index ordersCustomerId
    on Orders (customerId)
go

create index menuStartDateAndEndDate
    on MenuPositions (startDate, endDate)
go

create index menuPositionIdAndEndDate
    on MenuPositions (menuPositionId, endDate)
go

create index customerIdAndDiscountType
    on Discounts (customerId, discountType)
go

create index dishName
    on Dishes (dishName)
go

create index paramNameAndEndDate
    on DiscountParameters (paramName, endDate)
go

create index categoryName
    on Categories (categoryName)
go

