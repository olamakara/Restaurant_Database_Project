CREATE TRIGGER UpdateInStockTrigger
ON OrderDetails
FOR INSERT as
BEGIN
    declare @menuPositionId INT
    select @menuPositionId = I.menuPositionId
           from inserted I

    declare @inStock INT
    select @inStock = M.inStock
        from MenuPositions M
        where M.menuPositionId = @menuPositionId

    declare @newQuantity INT
    select @newQuantity = @inStock - I.quantity
           from inserted I

EXEC [dbo].UpdateMenuPositionInStock @menuPositionId, @newQuantity
END
go

CREATE TRIGGER UpdateDiscountsOnOrderInsert
ON Orders
FOR INSERT as
begin
    declare @customerId INT
    select @customerId = I.orderId from inserted I

    if exists (
        select * from IndividualCustomers
        where IndividualCustomers.customerId = @customerId
        )
    begin
        declare @discountsId int

        if not exists (
            select * from Discounts
            where Discounts.customerId = @customerId and Discounts.discountType = 0
            ) and [dbo].shouldGetDiscountType0(@customerId) = 1
        begin

            select @discountsId = isnull(max(disountId),0) + 1 from Discounts
            insert into Discounts
            values(0, @discountsId, @customerId, getdate())
        end

        if not exists (
            select * from Discounts
            where Discounts.customerId = @customerId and Discounts.discountType = 1
            ) and [dbo].shouldGetDiscountType1(@customerId) = 1
        begin
            select @discountsId = isnull(max(disountId),0) + 1 from Discounts
            insert into Discounts
            values(1, @discountsId, @customerId, getdate())
        end
    end
END
go

CREATE trigger DeleteOutdatedReservations
    on Reservations
    for insert,delete,update
    as
    begin
        declare @cursor cursor
        set @cursor = cursor for
        select reservationId from dbo.Reservations
        where isAccepted = 0 and getdate() > startDate
        declare @reservationToDelete int
        open @cursor
        fetch next from @cursor
        into @reservationToDelete

        while @@fetch_status = 0
            begin
                exec [dbo].RemoveReservation @reservationToDelete
                fetch next from @cursor
                into @reservationToDelete
            end
        close @cursor
        deallocate @cursor
    end
go