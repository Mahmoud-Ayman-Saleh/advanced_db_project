
USE db52885;
GO

-- VEHICLE
CREATE NONCLUSTERED INDEX IX_Vehicle_CustomerId
ON dbo.Vehicle(CustomerId);
GO


-- WORK ORDER EMPLOYEE

CREATE NONCLUSTERED INDEX IX_WorkOrderEmployee_EmployeeId
ON dbo.WorkOrderEmployee(EmployeeId)
INCLUDE (WorkOrderId, HoursWorked, [Role]);
GO


-- WORK ORDER

CREATE NONCLUSTERED INDEX IX_WorkOrder_VehicleId_State_StartAt
ON dbo.WorkOrder(VehicleId, [State], StartAt);
GO


-- EMPLOYEE SALARY HISTORY

CREATE NONCLUSTERED INDEX IX_EmployeeSalaryHistory_EmployeeId_EffectiveFrom
ON dbo.EmployeeSalaryHistory(EmployeeId, EffectiveFrom DESC)
INCLUDE (HourlyRate, EffectiveTo);
GO


-- PART PRICE HISTORY

CREATE NONCLUSTERED INDEX IX_PartPriceHistory_PartId_EffectiveFrom
ON dbo.PartPriceHistory(PartId, EffectiveFrom DESC)
INCLUDE (UnitCost, EffectiveTo);
GO


-- WORK ORDER PART

CREATE NONCLUSTERED INDEX IX_WorkOrderPart_WorkOrderId
ON dbo.WorkOrderPart(WorkOrderId)
INCLUDE (PartId, QuantityUsed, UnitPriceAtUse);
GO

CREATE NONCLUSTERED INDEX IX_WorkOrderPart_PartId
ON dbo.WorkOrderPart(PartId);
GO


-- WORK ORDER REPAIR TASK

CREATE NONCLUSTERED INDEX IX_WorkOrderRepairTask_WorkOrderId
ON dbo.WorkOrderRepairTask(WorkOrderId)
INCLUDE (RepairTaskId, Quantity, LaborCostAtUse);
GO


-- REPAIR TASK PART

CREATE NONCLUSTERED INDEX IX_RepairTaskPart_PartId
ON dbo.RepairTaskPart(PartId);
GO


-- APPOINTMENT

CREATE NONCLUSTERED INDEX IX_Appointment_CustomerId_ScheduledAt
ON dbo.Appointment(CustomerId, ScheduledAt);
GO
