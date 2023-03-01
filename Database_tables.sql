create table Categories
(
    categoryId          int                               not null
        constraint Categories_pk
            primary key,
    categoryName        varchar(255)                      not null,
    categoryDescription varchar(255) default 'brak opisu' not null
)
go

create table Customers
(
    customerId int not null
        constraint Customers_pk
            primary key
)
go

create table CompanyCustomers
(
    customerId  int          not null
        constraint key_name
            primary key
        constraint foreign_key_name
            references Customers,
    companyName varchar(255) not null,
    nip         char(32)     not null
        constraint uniqueNip
            unique
        constraint validNip
            check ([nip] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
)
go

create table DiscountParameters
(
    startDate datetime   not null,
    endDate   datetime,
    paramName varchar(2) not null
        constraint validParamName
            check ([paramName] = 'D1' OR [paramName] = 'Z1' OR [paramName] = 'R2' OR [paramName] = 'R1' OR
                   [paramName] = 'K2' OR [paramName] = 'K1'),
    paramVal  int        not null
        constraint validParamVal
            check ([paramVal] >= 0),
    paramId   int        not null
        constraint DiscountParameters_pk
            primary key,
    constraint validDiscountParamEndDate
        check ([DiscountParameters].[startDate] <= isnull([endDate], '3000-01-01 23:59:59'))
)
go

create table Dishes
(
    dishId          int                               not null
        constraint StockKey
            primary key,
    dishName        varchar(255)                      not null,
    categoryId      int                               not null
        constraint Stock_Categories_null_fk
            references Categories,
    dishDescription varchar(255) default 'brak opisu' not null
)
go

create table Employees
(
    employeeId int          not null
        constraint Employees_pk
            primary key,
    firstName  varchar(255) not null,
    lastName   varchar(255) not null,
    phone      char(32)     not null
        constraint uniquePhone
            unique
        constraint validPhone
            check ([phone] like '+[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    email      varchar(32)  not null
        constraint uniqueEmail
            unique
        constraint validEmail
            check ([email] like '%@%.%'),
    position   varchar(255) not null
)
go

create table IndividualCustomers
(
    customerId int          not null
        constraint individualCustomers_pk
            primary key
        constraint individualCustomers_Customers_null_fk
            references Customers,
    firstName  varchar(255) not null,
    lastName   varchar(255) not null,
    phone      varchar(32)  not null
        constraint uniqueCustomerPhone
            unique
        constraint validCustomerPhone
            check ([phone] like '+[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
)
go

create table Discounts
(
    discountType bit      not null,
    disountId    int      not null
        constraint Discounts_pk
            primary key,
    customerId   int      not null
        constraint Discounts_IndividualCustomers_null_fk
            references IndividualCustomers,
    appliesSince datetime not null
)
go

create table DiscountHistory
(
    appliedDate   datetime not null,
    discountId    int      not null
        constraint DiscountHistory_Discounts_null_fk
            references Discounts,
    discountValue float    not null
        constraint discountValueCheck
            check ([discountValue] >= 0),
    orderId       int      not null
)
go

create table MenuPositions
(
    menuPositionId int      not null
        constraint MenuPositions_pk
            primary key,
    price          money    not null
        constraint validPrice
            check ([price] > 0),
    dishId         int      not null
        constraint MenuPositions_Products_null_fk
            references Dishes,
    startDate      datetime not null,
    endDate        datetime,
    inStock        int      not null
        constraint check_name
            check ([inStock] >= 0),
    constraint validDate
        check (isnull([endDate], '3000-01-01 23:59:59') >= [startDate])
)
go

create table Orders
(
    orderId             int      not null
        constraint Orders_pk
            primary key,
    orderDate           datetime not null,
    customerId          int      not null
        constraint Orders_Customers_null_fk
            references Customers,
    employeeId          int      not null
        constraint Orders_Employees_null_fk
            references Employees,
    isTakeaway          bit      not null,
    orderCollectionDate datetime,
    isPaidBefore        bit      not null,
    constraint validCollectionDate
        check (isnull([orderCollectionDate], '3000-01-01 23:59:59') >= [orderDate]),
    constraint validCollectionDate1
        check ([isTakeaway] = 1 AND [orderCollectionDate] IS NOT NULL OR
               [isTakeaway] = 0 AND [orderCollectionDate] IS NULL)
)
go

create table OrderDetails
(
    orderId        int not null
        constraint OrderDetails_Orders_null_fk
            references Orders,
    quantity       int not null
        constraint validQuantity
            check ([quantity] > 0),
    menuPositionId int not null
        constraint OrderDetails_MenuPositions_null_fk
            references MenuPositions
)
go

create table ReservationParameters
(
    paramName varchar(2) not null
        constraint validParamName1
            check ([paramName] = 'WK' OR [paramName] = 'WZ'),
    paramVal  int        not null
        constraint validParamVal1
            check ([paramVal] >= 0)
)
go

create table SeaFoodReservations
(
    customerId                int      not null
        constraint SeaFoodReservations_Customers_null_fk
            references Customers,
    quantity                  int      not null
        constraint ValidNumber
            check ([quantity] > 0),
    reservationDate           datetime not null,
    reservationCollectionDate datetime not null,
    dishId                    int      not null
        constraint SeaFoodReservations_Dishes_null_fk
            references Dishes,
    constraint ValidSeaFoodReservationDate
        check (datepart(weekday, [reservationCollectionDate]) = 5 AND
               dateadd(day, 3, [reservationDate]) <= [reservationCollectionDate] OR
               datepart(weekday, [reservationCollectionDate]) = 6 AND
               dateadd(day, 4, [reservationDate]) <= [reservationCollectionDate] OR
               datepart(weekday, [reservationCollectionDate]) = 7 AND
               dateadd(day, 5, [reservationDate]) <= [reservationCollectionDate])
)
go

create table Tables
(
    tableId       int not null
        constraint Tables_pk
            primary key,
    tableCapacity int not null
        constraint validTableCapacity
            check ([tableCapacity] > 0)
)
go

create table Reservations
(
    reservationId int      not null
        constraint Reservations_pk
            primary key,
    tableId       int
        constraint Reservations_Tables_null_fk
            references Tables,
    isAccepted    bit      not null,
    startDate     datetime not null,
    endDate       datetime
)
go

create table CompanyReservations
(
    reservationId int not null
        constraint CompanyReservations_pk
            primary key
        constraint CompanyReservations_Reservations_null_fk
            references Reservations,
    customerId    int not null
        constraint CompanyReservations_CompanyCustomers_null_fk
            references CompanyCustomers
)
go

create table CompanyEmployeeReservations
(
    reservationId int          not null
        constraint CompanyEmployeeReservations_CompanyReservations_null_fk
            references CompanyReservations,
    firstName     varchar(255) not null,
    lastName      varchar(255) not null
)
go

create table IndividualReservations
(
    reservationId int not null
        constraint IndividualReservations_pk
            unique
        constraint IndividualReservations_Reservations_null_fk
            references Reservations,
    customerId    int not null
        constraint IndividualReservations_Customers_null_fk
            references IndividualCustomers,
    orderId       int not null
        constraint IndividualReservations_pk3
            unique
        constraint IndividualReservations_Orders_null_fk
            references Orders
)
go
