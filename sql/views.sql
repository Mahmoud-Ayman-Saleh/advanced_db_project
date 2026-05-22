CREATE OR ALTER VIEW dbo.vw_ManagerDashboard
AS
SELECT
    wo.Id AS WorkOrderId,
    wo.[State],
    wo.StartAt,
    wo.EndAt,
    wo.CreatedAt,
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.[Year],
    v.LicensePlate,
    COUNT(DISTINCT woe.EmployeeId) AS AssignedEmployeesCount,
    COUNT(DISTINCT wort.RepairTaskId) AS RepairTasksCount,
    COUNT(DISTINCT wop.Id) AS PartsCount,
    inv.Id AS InvoiceId,
    inv.PaymentStatus,
    inv.TotalAmount
FROM dbo.WorkOrder wo
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
LEFT JOIN dbo.WorkOrderEmployee woe
    ON woe.WorkOrderId = wo.Id
LEFT JOIN dbo.WorkOrderRepairTask wort
    ON wort.WorkOrderId = wo.Id
LEFT JOIN dbo.WorkOrderPart wop
    ON wop.WorkOrderId = wo.Id
LEFT JOIN dbo.Invoice inv
    ON inv.WorkOrderId = wo.Id
WHERE wo.IsDeleted = 0
GROUP BY
    wo.Id, wo.[State], wo.StartAt, wo.EndAt, wo.CreatedAt,
    c.Id, u.FirstName, u.LastName,
    v.Id, v.Make, v.Model, v.[Year], v.LicensePlate,
    inv.Id, inv.PaymentStatus, inv.TotalAmount;
GO

CREATE OR ALTER VIEW dbo.vw_WorkOrderDetails
AS
SELECT
    wo.Id AS WorkOrderId,
    wo.[State],
    wo.StartAt,
    wo.EndAt,
    wo.CreatedAt,
    wo.UpdatedAt,
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.[Year],
    v.LicensePlate,
    ISNULL(emp.AssignedEmployeesCount, 0) AS AssignedEmployeesCount,
    ISNULL(rt.RepairTasksCount, 0) AS RepairTasksCount,
    ISNULL(pt.PartsCount, 0) AS PartsCount,
    ISNULL(pt.PartsTotal, 0) AS PartsTotal,
    ISNULL(rt.LaborTotal, 0) AS LaborTotal,
    inv.Id AS InvoiceId,
    inv.Subtotal,
    inv.Discount,
    inv.TaxRate,
    inv.TaxAmount,
    inv.TotalAmount,
    inv.PaymentStatus,
    inv.IssuedAt
FROM dbo.WorkOrder wo
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
LEFT JOIN (
    SELECT
        WorkOrderId,
        COUNT(*) AS AssignedEmployeesCount
    FROM dbo.WorkOrderEmployee
    GROUP BY WorkOrderId
) emp
    ON emp.WorkOrderId = wo.Id
LEFT JOIN (
    SELECT
        WorkOrderId,
        COUNT(*) AS RepairTasksCount,
        SUM(LaborCostAtUse) AS LaborTotal
    FROM dbo.WorkOrderRepairTask
    GROUP BY WorkOrderId
) rt
    ON rt.WorkOrderId = wo.Id
LEFT JOIN (
    SELECT
        WorkOrderId,
        COUNT(*) AS PartsCount,
        SUM(QuantityUsed * UnitPriceAtUse) AS PartsTotal
    FROM dbo.WorkOrderPart
    GROUP BY WorkOrderId
) pt
    ON pt.WorkOrderId = wo.Id
LEFT JOIN dbo.Invoice inv
    ON inv.WorkOrderId = wo.Id
WHERE wo.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_InvoiceDetails
AS
SELECT
    inv.Id AS InvoiceId,
    inv.WorkOrderId,
    wo.[State] AS WorkOrderState,
    wo.StartAt,
    wo.EndAt,
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.LicensePlate,
    inv.Subtotal,
    inv.Discount,
    inv.TaxRate,
    inv.TaxAmount,
    inv.TotalAmount,
    inv.PaymentStatus,
    inv.IssuedAt,
    ISNULL(pt.PartsTotal, 0) AS PartsTotal,
    ISNULL(rt.LaborTotal, 0) AS LaborTotal
FROM dbo.Invoice inv
JOIN dbo.WorkOrder wo
    ON wo.Id = inv.WorkOrderId
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
LEFT JOIN (
    SELECT
        WorkOrderId,
        SUM(QuantityUsed * UnitPriceAtUse) AS PartsTotal
    FROM dbo.WorkOrderPart
    GROUP BY WorkOrderId
) pt
    ON pt.WorkOrderId = wo.Id
LEFT JOIN (
    SELECT
        WorkOrderId,
        SUM(LaborCostAtUse) AS LaborTotal
    FROM dbo.WorkOrderRepairTask
    GROUP BY WorkOrderId
) rt
    ON rt.WorkOrderId = wo.Id
WHERE inv.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_LowStockParts
AS
SELECT
    p.Id AS PartId,
    p.Name,
    p.Description,
    p.Category,
    p.Supplier,
    p.CurrentCost,
    p.StockQuantity,
    p.CreatedAt,
    p.UpdatedAt
FROM dbo.Part p
WHERE p.IsDeleted = 0
  AND p.StockQuantity <= 10;
GO


CREATE OR ALTER VIEW dbo.vw_EmployeeWorkOrders
AS
SELECT
    woe.WorkOrderId,
    woe.EmployeeId,
    u.FirstName + ' ' + u.LastName AS EmployeeName,
    e.Title AS EmployeeTitle,
    woe.HoursWorked,
    woe.[Role] AS AssignmentRole,
    wo.[State],
    wo.StartAt,
    wo.EndAt,
    wo.CreatedAt,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.LicensePlate,
    c.Id AS CustomerId,
    cu.FirstName + ' ' + cu.LastName AS CustomerName
FROM dbo.WorkOrderEmployee woe
JOIN dbo.Employee e
    ON e.Id = woe.EmployeeId
JOIN dbo.[User] u
    ON u.Id = e.UserId
JOIN dbo.WorkOrder wo
    ON wo.Id = woe.WorkOrderId
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] cu
    ON cu.Id = c.UserId
WHERE wo.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_EmployeeWorkOrderTasks
AS
SELECT
    wort.WorkOrderId,
    wort.RepairTaskId,
    rt.Name AS RepairTaskName,
    rt.EstimatedDuration,
    rt.DefaultLaborCost,
    wort.Quantity,
    wort.LaborCostAtUse,
    wort.Note
FROM dbo.WorkOrderRepairTask wort
JOIN dbo.RepairTask rt
    ON rt.Id = wort.RepairTaskId
WHERE rt.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_EmployeeWorkOrderParts
AS
SELECT
    wop.WorkOrderId,
    wop.Id AS WorkOrderPartId,
    wop.PartId,
    p.Name AS PartName,
    p.Category,
    p.Supplier,
    wop.QuantityUsed,
    wop.UnitPriceAtUse,
    wop.CreatedAt
FROM dbo.WorkOrderPart wop
JOIN dbo.Part p
    ON p.Id = wop.PartId
WHERE p.IsDeleted = 0;
GO



CREATE OR ALTER VIEW dbo.vw_EmployeeSalaryCurrent
AS
WITH SalaryRanked AS
(
    SELECT
        esh.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY esh.EmployeeId
            ORDER BY esh.EffectiveFrom DESC, esh.Id DESC
        ) AS rn
    FROM dbo.EmployeeSalaryHistory esh
)
SELECT
    e.Id AS EmployeeId,
    u.FirstName + ' ' + u.LastName AS EmployeeName,
    e.Title,
    sr.HourlyRate,
    sr.EffectiveFrom,
    sr.EffectiveTo
FROM SalaryRanked sr
JOIN dbo.Employee e
    ON e.Id = sr.EmployeeId
JOIN dbo.[User] u
    ON u.Id = e.UserId
WHERE sr.rn = 1;
GO


CREATE OR ALTER VIEW dbo.vw_CustomerProfile
AS
SELECT
    c.Id AS CustomerId,
    c.UserId,
    u.FirstName,
    u.LastName,
    u.Username,
    u.Email,
    c.PhoneNumber,
    c.CreatedAt,
    c.UpdatedAt
FROM dbo.Customer c
JOIN dbo.[User] u
    ON u.Id = c.UserId
WHERE c.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_CustomerVehicles
AS
SELECT
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.[Year],
    v.LicensePlate,
    v.VIN,
    v.CreatedAt,
    v.UpdatedAt
FROM dbo.Vehicle v
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
WHERE v.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_CustomerWorkOrders
AS
SELECT
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.LicensePlate,
    wo.Id AS WorkOrderId,
    wo.[State],
    wo.StartAt,
    wo.EndAt,
    wo.CreatedAt,
    wo.UpdatedAt
FROM dbo.WorkOrder wo
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
WHERE wo.IsDeleted = 0;
GO


CREATE OR ALTER VIEW dbo.vw_CustomerInvoices
AS
SELECT
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    v.Id AS VehicleId,
    v.Make,
    v.Model,
    v.LicensePlate,
    inv.Id AS InvoiceId,
    inv.WorkOrderId,
    wo.[State] AS WorkOrderState,
    inv.Subtotal,
    inv.Discount,
    inv.TaxRate,
    inv.TaxAmount,
    inv.TotalAmount,
    inv.PaymentStatus,
    inv.IssuedAt
FROM dbo.Invoice inv
JOIN dbo.WorkOrder wo
    ON wo.Id = inv.WorkOrderId
JOIN dbo.Vehicle v
    ON v.Id = wo.VehicleId
JOIN dbo.Customer c
    ON c.Id = v.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
WHERE inv.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_CustomerAppointments
AS
SELECT
    c.Id AS CustomerId,
    u.FirstName + ' ' + u.LastName AS CustomerName,
    a.Id AS AppointmentId,
    a.VehicleId,
    v.Make,
    v.Model,
    v.LicensePlate,
    a.ScheduledAt,
    a.[Status],
    a.CreatedAt
FROM dbo.Appointment a
JOIN dbo.Customer c
    ON c.Id = a.CustomerId
JOIN dbo.[User] u
    ON u.Id = c.UserId
JOIN dbo.Vehicle v
    ON v.Id = a.VehicleId;
GO
