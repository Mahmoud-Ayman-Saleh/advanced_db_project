USE db52885;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


-- CONFIG


DECLARE @AppointmentsCount INT = 50000;
DECLARE @WorkOrdersCount  INT = 300000;

DECLARE @VehicleCount     INT = (SELECT COUNT(*) FROM Vehicle);
DECLARE @EmployeeCount    INT = (SELECT COUNT(*) FROM Employee);
DECLARE @RepairTaskCount  INT = (SELECT COUNT(*) FROM RepairTask);
DECLARE @PartCount        INT = (SELECT COUNT(*) FROM Part);


-- NUMBERS TABLE


IF OBJECT_ID('tempdb..#Numbers') IS NOT NULL
    DROP TABLE #Numbers;

;WITH Numbers AS
(
    SELECT TOP (@WorkOrdersCount)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT n
INTO #Numbers
FROM Numbers;

CREATE CLUSTERED INDEX IX_Numbers_n ON #Numbers(n);


-- APPOINTMENTS


INSERT INTO Appointment
(
    CustomerId,
    VehicleId,
    ScheduledAt,
    [Status]
)
SELECT
    ((n - 1) % 30) + 1,
    ((n - 1) % @VehicleCount) + 1,
    DATEADD(DAY, -(n % 700), GETDATE()),
    CASE n % 4
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Cancelled'
        ELSE 'Scheduled'
    END
FROM #Numbers
WHERE n <= @AppointmentsCount;


-- WORK ORDERS


INSERT INTO WorkOrder
(
    VehicleId,
    StartAt,
    EndAt,
    [State]
)
SELECT
    ((n - 1) % @VehicleCount) + 1,

    DATEADD(DAY, -(n % 900), GETDATE()),

    CASE
        WHEN n % 4 = 0
        THEN DATEADD(HOUR, 4,
             DATEADD(DAY, -(n % 900), GETDATE()))
        ELSE NULL
    END,

    CASE n % 4
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'In_Progress'
        WHEN 2 THEN 'Scheduled'
        ELSE 'Cancelled'
    END
FROM #Numbers;


-- WORK ORDER EMPLOYEES


INSERT INTO WorkOrderEmployee
(
    WorkOrderId,
    EmployeeId,
    HoursWorked,
    [Role]
)
SELECT
    wo.Id,

    ((wo.Id - 1) % @EmployeeCount) + 1,

    CAST((ABS(CHECKSUM(NEWID())) % 8) + 1 AS DECIMAL(5,2)),

    'Lead Mechanic'
FROM WorkOrder wo;

INSERT INTO WorkOrderEmployee
(
    WorkOrderId,
    EmployeeId,
    HoursWorked,
    [Role]
)
SELECT
    wo.Id,

    ((wo.Id + 3) % @EmployeeCount) + 1,

    CAST((ABS(CHECKSUM(NEWID())) % 6) + 1 AS DECIMAL(5,2)),

    'Support'
FROM WorkOrder wo
WHERE wo.Id % 2 = 0;


-- WORK ORDER REPAIR TASKS


INSERT INTO WorkOrderRepairTask
(
    WorkOrderId,
    RepairTaskId,
    Quantity,
    LaborCostAtUse,
    Note
)
SELECT
    wo.Id,

    ((wo.Id - 1) % @RepairTaskCount) + 1,

    1,

    100 + (((wo.Id - 1) % 20) * 50),

    'Generated Task'
FROM WorkOrder wo;

INSERT INTO WorkOrderRepairTask
(
    WorkOrderId,
    RepairTaskId,
    Quantity,
    LaborCostAtUse,
    Note
)
SELECT
    wo.Id,

    ((wo.Id + 7) % @RepairTaskCount) + 1,

    1,

    150 + (((wo.Id + 7) % 20) * 40),

    'Generated Task 2'
FROM WorkOrder wo
WHERE wo.Id % 2 = 0;


-- WORK ORDER PARTS


INSERT INTO WorkOrderPart
(
    WorkOrderId,
    PartId,
    QuantityUsed,
    UnitPriceAtUse
)
SELECT
    wo.Id,

    ((wo.Id - 1) % @PartCount) + 1,

    (wo.Id % 4) + 1,

    50 + (((wo.Id - 1) % @PartCount) * 10)
FROM WorkOrder wo;

INSERT INTO WorkOrderPart
(
    WorkOrderId,
    PartId,
    QuantityUsed,
    UnitPriceAtUse
)
SELECT
    wo.Id,

    ((wo.Id + 5) % @PartCount) + 1,

    (wo.Id % 3) + 1,

    70 + (((wo.Id + 5) % @PartCount) * 15)
FROM WorkOrder wo
WHERE wo.Id % 2 = 0;

INSERT INTO WorkOrderPart
(
    WorkOrderId,
    PartId,
    QuantityUsed,
    UnitPriceAtUse
)
SELECT
    wo.Id,

    ((wo.Id + 11) % @PartCount) + 1,

    (wo.Id % 5) + 1,

    100 + (((wo.Id + 11) % @PartCount) * 12)
FROM WorkOrder wo
WHERE wo.Id % 3 = 0;


-- INVOICES


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
SELECT
    wo.Id,

    1000 + (wo.Id % 5000),

    CASE
        WHEN wo.Id % 5 = 0 THEN 100
        ELSE 0
    END,

    14,

    ROUND((1000 + (wo.Id % 5000)) * 0.14, 2),

    ROUND(
        ((1000 + (wo.Id % 5000))
        - CASE WHEN wo.Id % 5 = 0 THEN 100 ELSE 0 END)
        + ((1000 + (wo.Id % 5000)) * 0.14),
    2),

    CASE wo.Id % 3
        WHEN 0 THEN 'Paid'
        WHEN 1 THEN 'Pending'
        ELSE 'Cancelled'
    END,

    DATEADD(HOUR, 5, wo.StartAt)

FROM WorkOrder wo
WHERE wo.[State] = 'Completed';

GO