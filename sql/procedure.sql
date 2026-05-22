USE db52885;
GO

-- 1) CREATE WORK ORDER

CREATE OR ALTER PROCEDURE sp_CreateWorkOrder
(
    @VehicleId INT,
    @StartAt DATETIME2,
    @State NVARCHAR(20) = 'Scheduled'
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Vehicle
            WHERE Id = @VehicleId
            AND IsDeleted = 0
        )
        BEGIN
            THROW 50001, 'Vehicle does not exist.', 1;
        END

        INSERT INTO WorkOrder
        (
            VehicleId,
            StartAt,
            [State]
        )
        VALUES
        (
            @VehicleId,
            @StartAt,
            @State
        );

        SELECT SCOPE_IDENTITY() AS NewWorkOrderId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2) ADD PART TO WORK ORDER

CREATE OR ALTER PROCEDURE sp_AddPartToWorkOrder
(
    @WorkOrderId INT,
    @PartId INT,
    @QuantityUsed DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentCost DECIMAL(10,2);
    DECLARE @StockQuantity INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @CurrentCost = CurrentCost,
            @StockQuantity = StockQuantity
        FROM Part
        WHERE Id = @PartId
        AND IsDeleted = 0;

        IF @CurrentCost IS NULL
        BEGIN
            THROW 50002, 'Part not found.', 1;
        END

        IF @StockQuantity < @QuantityUsed
        BEGIN
            THROW 50003, 'Not enough stock quantity.', 1;
        END

        INSERT INTO WorkOrderPart
        (
            WorkOrderId,
            PartId,
            QuantityUsed,
            UnitPriceAtUse
        )
        VALUES
        (
            @WorkOrderId,
            @PartId,
            @QuantityUsed,
            @CurrentCost
        );

        UPDATE Part
        SET StockQuantity = StockQuantity - @QuantityUsed
        WHERE Id = @PartId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 3) ADD REPAIR TASK TO WORK ORDER

CREATE OR ALTER PROCEDURE sp_AddRepairTaskToWorkOrder
(
    @WorkOrderId INT,
    @RepairTaskId INT,
    @Quantity DECIMAL(5,2) = 1,
    @Note NVARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DefaultLaborCost DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @DefaultLaborCost = DefaultLaborCost
        FROM RepairTask
        WHERE Id = @RepairTaskId
        AND IsDeleted = 0;

        IF @DefaultLaborCost IS NULL
        BEGIN
            THROW 50004, 'Repair task not found.', 1;
        END

        INSERT INTO WorkOrderRepairTask
        (
            WorkOrderId,
            RepairTaskId,
            Quantity,
            LaborCostAtUse,
            Note
        )
        VALUES
        (
            @WorkOrderId,
            @RepairTaskId,
            @Quantity,
            @DefaultLaborCost,
            @Note
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4) UPDATE WORK ORDER STATE

CREATE OR ALTER PROCEDURE sp_UpdateWorkOrderState
(
    @WorkOrderId INT,
    @NewState NVARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentState NVARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @CurrentState = [State]
        FROM WorkOrder
        WHERE Id = @WorkOrderId;

        IF @CurrentState IS NULL
        BEGIN
            THROW 50005, 'Work order not found.', 1;
        END

        IF
        (
            (@CurrentState = 'Scheduled' AND @NewState NOT IN ('In_Progress', 'Cancelled'))
            OR
            (@CurrentState = 'In_Progress' AND @NewState NOT IN ('Completed', 'Cancelled'))
            OR
            (@CurrentState IN ('Completed', 'Cancelled'))
        )
        BEGIN
            THROW 50006, 'Invalid work order state transition.', 1;
        END

        UPDATE WorkOrder
        SET
            [State] = @NewState,
            EndAt = CASE
                        WHEN @NewState = 'Completed'
                        THEN GETDATE()
                        ELSE EndAt
                    END
        WHERE Id = @WorkOrderId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5) RECORD PART USAGE

CREATE OR ALTER PROCEDURE sp_RecordPartUsage
(
    @WorkOrderPartId INT,
    @NewQuantityUsed DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQuantity DECIMAL(10,2);
    DECLARE @PartId INT;
    DECLARE @Difference DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @OldQuantity = QuantityUsed,
            @PartId = PartId
        FROM WorkOrderPart
        WHERE Id = @WorkOrderPartId;

        IF @OldQuantity IS NULL
        BEGIN
            THROW 50007, 'WorkOrderPart record not found.', 1;
        END

        SET @Difference = @NewQuantityUsed - @OldQuantity;

        UPDATE WorkOrderPart
        SET QuantityUsed = @NewQuantityUsed
        WHERE Id = @WorkOrderPartId;

        UPDATE Part
        SET StockQuantity = StockQuantity - @Difference
        WHERE Id = @PartId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 6) GENERATE INVOICE

CREATE OR ALTER PROCEDURE sp_GenerateInvoice
(
    @WorkOrderId INT,
    @Discount DECIMAL(12,2) = 0,
    @TaxRate DECIMAL(5,2) = 14
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PartsTotal DECIMAL(12,2);
    DECLARE @LaborTotal DECIMAL(12,2);
    DECLARE @Subtotal DECIMAL(12,2);
    DECLARE @TaxAmount DECIMAL(12,2);
    DECLARE @TotalAmount DECIMAL(12,2);
    DECLARE @State NVARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @State = [State]
        FROM WorkOrder
        WHERE Id = @WorkOrderId;

        IF @State IS NULL
        BEGIN
            THROW 50008, 'Work order not found.', 1;
        END

        IF @State <> 'Completed'
        BEGIN
            THROW 50009, 'Invoice can only be generated for completed work orders.', 1;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Invoice
            WHERE WorkOrderId = @WorkOrderId
        )
        BEGIN
            THROW 50010, 'Invoice already exists for this work order.', 1;
        END

        SELECT
            @PartsTotal =
                ISNULL(SUM(QuantityUsed * UnitPriceAtUse), 0)
        FROM WorkOrderPart
        WHERE WorkOrderId = @WorkOrderId;

        SELECT
            @LaborTotal =
                ISNULL(SUM(LaborCostAtUse), 0)
        FROM WorkOrderRepairTask
        WHERE WorkOrderId = @WorkOrderId;

        SET @Subtotal = @PartsTotal + @LaborTotal;

        SET @TaxAmount =
            (@Subtotal - @Discount) * (@TaxRate / 100.0);

        SET @TotalAmount =
            (@Subtotal - @Discount) + @TaxAmount;

        INSERT INTO Invoice
        (
            WorkOrderId,
            Subtotal,
            Discount,
            TaxRate,
            TaxAmount,
            TotalAmount,
            PaymentStatus,
            IssuedAt
        )
        VALUES
        (
            @WorkOrderId,
            @Subtotal,
            @Discount,
            @TaxRate,
            @TaxAmount,
            @TotalAmount,
            'Pending',
            GETDATE()
        );

        SELECT
            @WorkOrderId AS WorkOrderId,
            @Subtotal AS Subtotal,
            @Discount AS Discount,
            @TaxAmount AS TaxAmount,
            @TotalAmount AS TotalAmount;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO