CREATE procedure AcceptReservation @reservationId int, @tableId int
as
begin
    begin try
        if not exists(
            select * from Reservations
            where reservationId = @reservationId)
        begin
            ;throw 60000,'Reservation not found',1
        end
        if not exists(
            select * from Tables
            where tableId = @tableId)
        begin
            ;throw 60000, 'Table not found', 1
        end
        if exists(
            select * from Reservations
            where reservationId = @reservationId
            and isAccepted = 1)
        begin
            ;throw 60000, 'Reservation already accepted',1
        end
        declare @startDate date;
        declare @endDate date;

        select @startDate = startDate
        from Reservations
        where reservationId = @reservationId

        select @endDate = endDate
        from Reservations
        where reservationId = @reservationId

        if exists(select * from Reservations
            where tableId = @tableId and
                  isAccepted = 1 and
                  ((startDate < @startDate and endDate > @startDate)
                      or (startDate < @endDate and endDate > @endDate)
                       or (startDate > @startDate and endDate < @endDate)))
            begin
            ;throw 60000,'Reservation date already taken',1
            end

        update Reservations
            set isAccepted = 1, tableId = @tableId
            where reservationId = @reservationId;
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to accept reservation' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

CREATE Procedure AddCategory
    @categoryName varchar(255),
    @categoryDescription varchar(255)
    as
    begin
        begin try
            if exists(
                select * from Categories
                where Categories.categoryName = @categoryName)
                begin
                    ;throw 60000, 'Category with given name already exists', 1
                end
                declare @newId INT
                select @newId = ISNULL(MAX(categoryID), 0) + 1 from Categories
                insert into Categories
                values (@newId, @categoryName, @categoryDescription);
        end try
        begin catch
                declare @msg varchar(255) =
                    'Error while trying to add new Category: ' + ERROR_MESSAGE()
                ;throw 60000, @msg, 1
        end catch
    end
go

CREATE procedure AddCompanyCustomer
@companyName varchar(255),
@nip char(32)
as
begin
    begin try
        if exists(
            select companyName from CompanyCustomers
            where @companyName = companyName
            )
        begin
            ;throw 60000, 'Company customer with given name already exists', 1
        end
        declare @customerId INT
        select @customerId = isnull(max(customerId), 0) + 1 from Customers
        insert Customers
        values(@customerId)

        insert CompanyCustomers
        values (@customerId, @companyName, @nip)
    end try
    begin catch
        declare @msg varchar(255) = 'Error while inserting a company customer:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure AddCompanyEmployeeToReservation @reservationId int,
                                            @firstName varchar(255),
                                            @lastName varchar(255)
as
begin
    begin try
        if not exists(select * from CompanyReservations where reservationId = @reservationId)
            begin
                ;throw 60000,'Reservation not found',1
            end
        insert into CompanyEmployeeReservations(reservationId, firstName, lastName)
        values (@reservationId,@firstName,@lastName)
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add employee to company reservation' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

CREATE procedure AddDiscountParameter @paramVal int,
                                @paramName varchar(255)
as
begin
    begin try
        if @paramVal < 0
            begin
                ;throw 60000, 'Incorrect parameter value',1
            end
        declare @startDate datetime = getdate()
        declare @endDate datetime = null
        declare @paramId int
        select @paramId = isnull(max(paramId),0) + 1 from DiscountParameters
        update DiscountParameters
            set endDate = @startDate
            where paramName = @paramName
            and endDate is null
        insert into DiscountParameters(startDate, endDate, paramName, paramVal, paramId)
        values (@startDate, @endDate, @paramName, @paramVal, @paramId)
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add new DiscountParameter' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch

end
go

CREATE procedure AddDiscountToOrder
@discountType BIT,
@orderId INT
as
begin
    begin try
        if not exists(
            select * from Orders O
            where @orderId = O.orderId
            )
        begin
            ;throw 60000, 'Wrong orderId', 1
        end

        declare @customerId INT
        select @customerId = O.customerId
        from Orders O
        where @orderId = O.orderId

        declare @orderDate datetime
        select @orderDate = O.orderDate
        from Orders O
        where @orderId = O.orderId

        if not exists(
            select * from [dbo].GetAvailableDoscountsForCustomerId(@customerId) D
            where discountType = @discountType
            )
        begin
            ;throw 60000, 'Discount not avaliable', 1
        end

        declare @discountId INT
        select @discountId =  disountId
        from [dbo].GetAvailableDoscountsForCustomerId(@customerId) D
        where discountType = @discountType

        declare @totalCost money = [dbo].GetOrderValueByOrderId(@orderId)

        if @discountType = 0
        begin
            declare @R1 int
            select @R1 = DP.paramVal
            from DiscountParameters DP
            where DP.paramName = 'R1' and DP.endDate is null

            declare @discountValue money = @totalCost * @R1 * 0.01

            insert into DiscountHistory
            values(@orderDate, @discountId, @discountValue, @orderId)
        end
        else
        begin
            declare @R2 int
            select @R2 = DP.paramVal
            from DiscountParameters DP
            where DP.paramName = 'R2' and DP.endDate is null

            declare @discountVal money = @totalCost * @R2 * 0.01

            insert into DiscountHistory
            values(@orderDate, @discountId, @discountVal, @orderId)
        end

    end try
    begin catch
        declare @msg varchar(255) = 'Error while adding discount: ' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure AddDish @categoryName varchar(255),
                        @dishName varchar(255),
                        @dishDescription varchar(255)
as
begin
    begin try
        if exists(
                select * from Dishes
                where dishName = @dishName)
            begin
                ;throw 60000, 'Dish name already exists',1
            end
        if not exists(
                select * from Categories
                where categoryName = @categoryName)
            begin
                ;throw 60000, 'Category name not found',1
            end
        declare @dishId int
        select @dishId = isnull(max(dishId),0) + 1 from Dishes
        declare @categoryId int

        select @categoryId = categoryId from Categories
                            where categoryName = @categoryName

        insert into Dishes(dishId, dishName, categoryId,dishDescription)
        values (@dishId,@dishName,@categoryId,@dishDescription)
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add new Dish' + ERROR_MESSAGE()
        ;throw  60000,@errorMessage,1
    end catch
end
go

CREATE procedure AddEmployee @firstName varchar(255),
                            @lastName varchar(255),
                            @phone varchar(12),
                            @email varchar(255),
                            @position varchar(255)
    as
    begin
        begin try
            if exists(select * from Employees
                     where @phone = Employees.phone)
                begin
                    ;Throw 60000, 'Number already exists',1
                end
            if exists(select * from Employees
                    where @email = Employees.email)
                begin
                    ;Throw 60000, 'Email already exists',1
                end
            declare @employeeId int
            select @employeeId = isnull(max(employeeId),0) + 1 from Employees
            insert into Employees(employeeId, firstName, lastName, phone, email, position)
                values(@employeeId, @firstName, @lastName, @phone, @email, @position)
        end try
        begin catch
            declare @errorMessage nvarchar(255) = 'Error while trying to add Employee' + ERROR_MESSAGE()
            ;throw 60000,@errorMessage,1
        end catch
    end
go

CREATE procedure AddIndividualCustomer
@firstName varchar(255),
@lastName varchar(255),
@phone varchar(255)
as
begin
    begin try
        if exists(
            select phone from IndividualCustomers
            where @phone = phone
            )
        begin
            ;throw 60000, 'Customer with given phone number already exists', 1
        end
        declare @customerId INT
        select @customerId = isnull(max(customerId), 0) + 1 from Customers
        insert Customers
        values(@customerId)

        insert IndividualCustomers
        values (@customerId, @firstName, @lastName, @phone)
    end try
    begin catch
        declare @msg varchar(255) = 'Error while inserting a individual customer:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure AddOrderNew
    @customerId int,
    @employeeId int,
    @orderDate datetime,
    @isPaidBefore bit,
    @isTakeaway bit,
    @orderCollectionDate datetime,
    @transactionTable TransactionTable readonly
as
begin
    begin try
        if not exists(
            select * from Customers
            where customerId = @customerId)
        begin
            ;throw 60000,'Customer not found',1
        end
        if not exists(
            select * from Employees
            where employeeId = @employeeId)
        begin
            ;throw 60000,'Employee not found',1
        end
    declare @orderId int
    select @orderId = isnull(max(orderId),0) + 1 from Orders
    insert into Orders(orderId, orderDate, customerId, employeeId, isTakeaway, orderCollectionDate, isPaidBefore)
        values (@orderId,@orderDate,@customerId,@employeeId,@isTakeaway,@orderCollectionDate,@isPaidBefore)

    if exists(
        select 1 from @transactionTable as t
        where [dbo].CheckIfCanBeBought(t.menuPositionId, t.quantity) = 0
        )
    begin
        ;throw 60000, 'Wrong transaction item', 1
    end

    if exists(
        select 1 from (@TransactionTable t inner join MenuPositions MP on MP.menuPositionId = t.menuPositionId)
        where (select D.categoryId from MenuPositions inner join Dishes D on D.dishId = MenuPositions.dishId
                                   where t.menuPositionId = MenuPositions.menuPositionId) = 4 and
        not exists(
            select 1 from SeaFoodFutureOrders f
            where convert(date, @orderDate) = convert(date, f.reservationCollectionDate) and
                  MP.dishId =  f.dishId and
                  @customerId = f.customerId and
                  t.quantity =  f.quantity
            ))
    begin
        ;throw 60000, ': Seafood reservation have not been made', 1
    end

    insert into OrderDetails
    select @orderId, quantity, menuPositionId
    from @transactionTable

    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add new Order' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

CREATE procedure AddOrderWithReservationForIndividual
@customerId int,
@employeeId int,
@transactionTable TransactionTable readonly,
@startDate datetime,
@endDate datetime
as
begin
    begin try
        exec AddOrderNew @customerId, @employeeId, @startDate, 1, 0, null, @transactionTable
        declare @orderId INT
        select @orderId = max(orderId) from Orders
        exec AddReservation null, 0, @endDate, @endDate, @customerId, @orderId
    end try
    begin catch
        declare @msg varchar(255) = 'Error while adding reservation and order:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure AddPositionToMenu
@dishId INT,
@price money,
@inStock INT
as
begin
    begin try
        if not exists(
            select dishId from Dishes
            where dishId = @dishId
            )
        begin
            throw 60000, 'Dish doesnt exist', 1
        end
        if exists(
            select dishId from MenuPositions
            where @dishId = dishId and endDate is null
            )
        begin
            ;throw 60000, 'Dish already in menu', 1
        end

        declare @menuPositionId INT
        select @menuPositionId = isnull(max(menuPositionId), 0) + 1 from MenuPositions
        insert MenuPositions
        values(@menuPositionId, @price, @dishId, getdate(), null, @inStock)
    end try
    begin catch
        declare @msg varchar(255) = 'Error while inserting a menu position:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure AddReservation @tableId int,
                                @isAccepted bit,
                                @startDate datetime,
                                @endDate datetime,
                                --
                                @customerId int,--companyId / individualCustomerId

                                @orderId int --dla individualCustomer

as
begin
    begin try
        declare @reservationId int
        select @reservationId = isnull(max(reservationId),0) + 1 from Reservations
        --Sprawdzamy czy taka rezerwacja jest mozliwa
        if not exists(select customerId from IndividualCustomers where customerId = @customerId
                   union
                   select customerId from CompanyReservations where customerId = @customerId)
                begin
                ;throw 60000,'Incorrect customerId',1
                end
        if exists(select * from IndividualCustomers where customerId = @customerId)
            begin
                if not exists(select * from Orders where orderId = @orderId)
                    begin
                        ;throw 60000,'Incorrect orderId',1
                    end
                if ((select isnull(count(*),0) from Orders
                    where customerId = @customerId)>=(select paramVal from ReservationParameters
                                                                      where paramName = 'WK'))
                    and( [dbo].GetOrderValueByOrderId(@orderId) > (select paramVal from ReservationParameters
                                                                             where paramName = 'WZ'))
                    begin
                        insert into Reservations(reservationId, tableId, isAccepted, startDate, endDate)
                        values(@reservationId,@tableId,@isAccepted,@startDate,@endDate)
                        insert into IndividualReservations(reservationId, customerId, orderId)
                        values (@reservationId,@customerId,@orderId)
                    end
                else
                    begin
                        ;throw 60000,'WZ, WK not fullfilled',1
                    end
            end
        if exists(select * from CompanyCustomers where customerId = @customerId)
           -- Jest to rezerwacja firmowa
            begin
                insert into Reservations(reservationId, tableId, isAccepted, startDate, endDate)
                values(@reservationId,@tableId,@isAccepted,@startDate,@endDate)
                insert into CompanyReservations(reservationId, customerId)
                values (@reservationId,@customerId)
            end
        else
            begin
                if exists(select * from CompanyCustomers where customerId = @customerId)
                    --Jest to rezerwacja firmowa
                    begin
                        insert into CompanyReservations(reservationId, customerId)
                        values (@reservationId,@customerId)
                    end
            end

    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add new Order ' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

create procedure AddSeaFoodReservation @customerId int,
                                    @quantity int,
                                    @reservationDate datetime,
                                    @reservationCollectionDate datetime,
                                    @dishId int
as
begin
    begin try
        if not exists(select * from Customers where customerId = @customerId)
            begin
                throw 60000,'Customer not found',1
            end
        if not exists(select * from Dishes
            inner join Categories C on C.categoryId = Dishes.categoryId
            where categoryName = N'Dania z ryb i owoców morza'
            and dishId = @dishId)
            begin
                throw 60000, 'Incorrect dishId',1
            end
        insert into SeaFoodReservations (customerId, quantity, reservationDate, reservationCollectionDate, dishId)
        values(@customerId,@quantity,@reservationDate,@reservationCollectionDate,@dishId)
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add sea food reservation: ' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

create procedure AddTable @tableCapacity int
as
begin
    begin try
        if @tableCapacity <= 0
            begin
                ;throw 60000,'Incorrect capacity',1
            end
        declare @tableId int
        select @tableId = isnull(max(tableId),0) + 1 from Tables

        insert into Tables(tableId, tableCapacity)
        values (@tableId,@tableCapacity)
    end try
    begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add Table' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
    end catch
end
go

CREATE procedure ChangeCategoryDescription
@categoryName varchar(255),
@categoryDescripton varchar (255)
as
    begin
        begin try
            if not exists (select categoryId from Categories where categoryName = @categoryName)
            begin
                ;throw 60000, 'Category with given name doesnt exists', 1
            end
            update Categories
            set categoryDescription = @categoryDescripton
            where categoryName = @categoryName
        end try
        begin catch
            declare @msg varchar(255) =
                'Error while trying to update category description: ' + ERROR_MESSAGE()
                ;throw 60000, @msg, 1
        end catch
    end
go

CREATE procedure ChangeDishDescription
@dishName varchar(255),
@dishDescription varchar(255)
as
begin
    begin try
        if not exists(
            select dishName from Dishes
            where dishName = @dishName
            )
        begin
            ;throw 60000, 'Dish not found', 1
        end

        update Dishes
        set dishDescription = @dishDescription
        where dishName = @dishName
    end try
    begin catch
        declare @msg varchar(255) = 'Error updating dish description:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure RemoveCategory
@categoryName varchar(255)
as
    begin
        begin try
            if not exists (select categoryId from Categories where categoryName = @categoryName)
            begin
                ;throw 60000, 'Category with given name doesnt exists', 1
            end
            delete from Categories where categoryName = @categoryName
        end try
        begin catch
            declare @msg varchar(255) =
                'Error while trying to remove new a Category: ' + ERROR_MESSAGE()
                ;throw 60000, @msg, 1
        end catch
    end
go

CREATE procedure RemoveOrder(@id int)
as
begin
    begin try
        if not exists(select * from Orders
            where orderId = @id)
            begin
                ;throw 60000, 'Order not found',1
            end
        delete from OrderDetails where orderId = @id
        declare @customerId int
        select @customerId = customerId from Orders where orderId = @id
        delete Orders where orderId = @id
        if [dbo].shouldGetDiscountType0(@customerId) = 0
            begin
                delete from Discounts where customerId = @customerId and discountType = 0
            end
        if [dbo].shouldGetDiscountType1(@customerId) = 0
            begin
                delete from Discounts where customerId = @customerId and discountType = 1
            end
    end try
    begin catch
        declare @msg varchar(255) = 'Error while trying to remove orded: '+ ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure RemovePositionFromMenu
@menuPositionId INT
as
begin
    begin try
        if not exists(
            select dishId from MenuPositions
            where @menuPositionId = menuPositionId and endDate is null
            )
        begin
            ;throw 60000, 'Menu position not in current menu', 1
        end

        update MenuPositions
        set endDate = getdate()
        where menuPositionId = @menuPositionId
    end try
    begin catch
        declare @msg varchar(255) = 'Error while removing a menu position:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure RemoveReservation(@id int)
as
begin
    begin try
        if not exists(
            select * from Reservations
            where reservationId = @id)
            begin
                ;throw 60000,'Reservation not found',1
            end
        if exists(
            select * from CompanyReservations
            where reservationId = @id)
            begin
                delete from CompanyEmployeeReservations where reservationId = @id
                delete from CompanyReservations where reservationId = @id
                delete from Reservations where reservationId = @id
            end
        if exists(
            select * from IndividualReservations
            where reservationId = @id)
            begin
                declare @orderId int
                select @orderId = orderId from IndividualReservations where reservationId = @id
                delete from IndividualReservations where reservationId = @id
                exec [dbo].RemoveOrder @orderId
                delete from Reservations where reservationId = @id
            end
    end try
    begin catch
        declare @msg varchar(255) =
            'Error while trying to remove reservation" '+ ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

create procedure RemoveTable @tableId int
as
    begin
        begin try
            if not exists(select * from Tables
                where tableId = @tableId)
                begin
                    ;throw 60000, 'Table does not exist',1
                end
            delete from Tables
                where tableId = @tableId
        end try
        begin catch
        declare @errorMessage nvarchar(255) = 'Error while trying to add new Order' + ERROR_MESSAGE()
        ;throw 60000,@errorMessage,1
        end catch
    end
go

CREATE procedure UpdateMenuPositionInStock
@menuPositionId INT,
@inStock INT
as
begin
    begin try
        if not exists(
            select dishId from MenuPositions
            where @menuPositionId = menuPositionId and endDate is null
            )
        begin
            ;throw 60000, 'Menu position not in current menu', 1
        end

        update MenuPositions
        set inStock = @inStock
        where menuPositionId = @menuPositionId
    end try
    begin catch
        declare @msg varchar(255) = 'Error updating inStock value:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

CREATE procedure UpdateReservationParameter
@paramName varchar(2),
@paramVal INT
as
begin
    begin try
        if @paramName not in ('WZ', 'WK')
        begin
            ;throw 60000, 'Wrong parameter name', 1
        end

        update ReservationParameters
        set paramVal = @paramVal
        where paramName = @paramName
    end try
    begin catch
        declare @msg varchar(255) = 'Error updating reservation parameter val:' + ERROR_MESSAGE()
        ;throw 60000, @msg, 1
    end catch
end
go

