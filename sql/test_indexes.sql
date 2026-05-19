
USE db52885;
GO



SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

--------------------------------------------------------------------------------
-- TEST 1: Employee Dashboard
-- Tests:
-- IX_WorkOrderEmployee_EmployeeId
--------------------------------------------------------------------------------

DECLARE @EmployeeId INT = 1;

SELECT
    wo.Id,
    wo.[State],
    wo.StartAt,
    wo.EndAt,
    v.Make,
    v.Model,
    we.HoursWorked
FROM dbo.WorkOrderEmployee we
JOIN dbo.WorkOrder wo
    ON wo.Id = we.WorkOrderId
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
WHERE we.EmployeeId = @EmployeeId
ORDER BY wo.StartAt DESC;
GO

--------------------------------------------------------------------------------
-- TEST 2: Customer Vehicles
-- Tests:
-- IX_Vehicle_CustomerId
--------------------------------------------------------------------------------

DECLARE @CustomerId INT = 1;

SELECT *
FROM dbo.Vehicle
WHERE CustomerId = @CustomerId;
GO

--------------------------------------------------------------------------------
-- TEST 3: Work Order Invoice Parts
-- Tests:
-- IX_WorkOrderPart_WorkOrderId
--------------------------------------------------------------------------------

DECLARE @WorkOrderId INT = 5000;

SELECT
    PartId,
    QuantityUsed,
    UnitPriceAtUse,
    QuantityUsed * UnitPriceAtUse AS Total
FROM dbo.WorkOrderPart
WHERE WorkOrderId = @WorkOrderId;
GO

--------------------------------------------------------------------------------
-- TEST 4: Work Order Repair Tasks
-- Tests:
-- IX_WorkOrderRepairTask_WorkOrderId
--------------------------------------------------------------------------------

DECLARE @WorkOrderId2 INT = 10000;

SELECT
    RepairTaskId,
    Quantity,
    LaborCostAtUse
FROM dbo.WorkOrderRepairTask
WHERE WorkOrderId = @WorkOrderId2;
GO

--------------------------------------------------------------------------------
-- TEST 5: Historical Employee Salary Lookup
-- Tests:
-- IX_EmployeeSalaryHistory_EmployeeId_EffectiveFrom
--------------------------------------------------------------------------------

DECLARE @EmployeeId2 INT = 5;
DECLARE @WorkDate DATE = '2025-05-01';

SELECT TOP 1
    EmployeeId,
    HourlyRate,
    EffectiveFrom,
    EffectiveTo
FROM dbo.EmployeeSalaryHistory
WHERE EmployeeId = @EmployeeId2
AND EffectiveFrom <= @WorkDate
ORDER BY EffectiveFrom DESC;
GO

--------------------------------------------------------------------------------
-- TEST 6: Historical Part Price Lookup
-- Tests:
-- IX_PartPriceHistory_PartId_EffectiveFrom
--------------------------------------------------------------------------------

DECLARE @PartId INT = 10;
DECLARE @UsedDate DATETIME2 = '2025-06-01';

SELECT TOP 1
    PartId,
    UnitCost,
    EffectiveFrom,
    EffectiveTo
FROM dbo.PartPriceHistory
WHERE PartId = @PartId
AND EffectiveFrom <= @UsedDate
ORDER BY EffectiveFrom DESC;
GO

--------------------------------------------------------------------------------
-- TEST 7: Appointment Lookup
-- Tests:
-- IX_Appointment_CustomerId_ScheduledAt
--------------------------------------------------------------------------------

DECLARE @CustomerId2 INT = 10;

SELECT *
FROM dbo.Appointment
WHERE CustomerId = @CustomerId2
ORDER BY ScheduledAt DESC;
GO

--------------------------------------------------------------------------------
-- TEST 8: Reverse Part Lookup
-- Tests:
-- IX_RepairTaskPart_PartId
--------------------------------------------------------------------------------

DECLARE @PartId2 INT = 7;

SELECT *
FROM dbo.RepairTaskPart
WHERE PartId = @PartId2;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
