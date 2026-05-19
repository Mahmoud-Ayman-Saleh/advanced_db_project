

USE db52885;
GO

--------------------------------------------------------------------------------
-- User roles
--------------------------------------------------------------------------------

CREATE TABLE [User] (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    FirstName       NVARCHAR(50)  NOT NULL,
    LastName        NVARCHAR(50)  NOT NULL,
    Username        NVARCHAR(50)  UNIQUE,
    Email           NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash    NVARCHAR(255) NOT NULL,
    [Role]          NVARCHAR(20)  NOT NULL CHECK ([Role] IN ('Manager', 'Customer', 'Employee')),
    IsDeleted       BIT           NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2,
    CreatedAt       DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE RefreshToken (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    UserId      INT NOT NULL FOREIGN KEY REFERENCES [User](Id) ON DELETE CASCADE,
    Token       NVARCHAR(500) NOT NULL,
    ExpiresAt   DATETIME2     NOT NULL,
    CreatedAt   DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE Customer (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    UserId      INT NOT NULL UNIQUE FOREIGN KEY REFERENCES [User](Id),
    PhoneNumber NVARCHAR(20),
    IsDeleted   BIT           NOT NULL DEFAULT 0,
    DeletedAt   DATETIME2,
    CreatedAt   DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt   DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE Vehicle (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL FOREIGN KEY REFERENCES Customer(Id),
    Make            NVARCHAR(50) NOT NULL,
    Model           NVARCHAR(50) NOT NULL,
    [Year]          INT NOT NULL CHECK ([Year] >= 1950),
    LicensePlate    NVARCHAR(20) NOT NULL,
    VIN             NVARCHAR(50),
    IsDeleted       BIT           NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2,
    CreatedAt       DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO



--------------------------------------------------------------------------------

CREATE TABLE Employee (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    UserId              INT NOT NULL UNIQUE FOREIGN KEY REFERENCES [User](Id),
    IsActive            BIT NOT NULL DEFAULT 1,
    Title               NVARCHAR(50),
    WorkHoursPerDay     INT NOT NULL DEFAULT 8,
    EmploymentStartDate DATE NOT NULL,
    IsDeleted           BIT           NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2,
    CreatedAt           DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt           DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE EmployeeSalaryHistory (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeId      INT NOT NULL FOREIGN KEY REFERENCES Employee(Id),
    HourlyRate      DECIMAL(10,2) NOT NULL,
    EffectiveFrom   DATE NOT NULL,
    EffectiveTo     DATE,
    CreatedAt       DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE Appointment (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL FOREIGN KEY REFERENCES Customer(Id),
    VehicleId       INT NOT NULL FOREIGN KEY REFERENCES Vehicle(Id),
    ScheduledAt     DATETIME2,
    [Status]        NVARCHAR(20),
    CreatedAt       DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE WorkOrder (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    VehicleId   INT NOT NULL FOREIGN KEY REFERENCES Vehicle(Id),
    StartAt     DATETIME2,
    EndAt       DATETIME2,
    [State]     NVARCHAR(20) NOT NULL CHECK ([State] IN ('Scheduled', 'In_Progress', 'Completed', 'Cancelled')),
    IsDeleted   BIT           NOT NULL DEFAULT 0,
    DeletedAt   DATETIME2,
    CreatedAt   DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt   DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE WorkOrderEmployee (
    WorkOrderId  INT NOT NULL FOREIGN KEY REFERENCES WorkOrder(Id),
    EmployeeId   INT NOT NULL FOREIGN KEY REFERENCES Employee(Id),
    HoursWorked  DECIMAL(5,2),
    [Role]       NVARCHAR(50),
    PRIMARY KEY (WorkOrderId, EmployeeId)
);
GO

--------------------------------------------------------------------------------

CREATE TABLE RepairTask (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    Name                NVARCHAR(100) NOT NULL UNIQUE,
    EstimatedDuration   INT,  -- Duration in minutes
    DefaultLaborCost    DECIMAL(10,2) NOT NULL,
    IsDeleted           BIT           NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2,
    CreatedAt           DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt           DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE Part (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(255),
    CurrentCost     DECIMAL(10,2) NOT NULL,
    StockQuantity   INT NOT NULL DEFAULT 0,
    Category        NVARCHAR(50),
    Supplier        NVARCHAR(100),
    IsDeleted       BIT           NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2,
    CreatedAt       DATETIME2     NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE PartPriceHistory (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    PartId          INT NOT NULL FOREIGN KEY REFERENCES Part(Id),
    UnitCost        DECIMAL(10,2) NOT NULL,
    EffectiveFrom   DATETIME2 NOT NULL,
    EffectiveTo     DATETIME2,
    CreatedAt       DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE RepairTaskPart (
    RepairTaskId  INT NOT NULL FOREIGN KEY REFERENCES RepairTask(Id),
    PartId        INT NOT NULL FOREIGN KEY REFERENCES Part(Id),
    PRIMARY KEY (RepairTaskId, PartId)
);
GO

--------------------------------------------------------------------------------

CREATE TABLE WorkOrderRepairTask (
    WorkOrderId      INT NOT NULL FOREIGN KEY REFERENCES WorkOrder(Id),
    RepairTaskId     INT NOT NULL FOREIGN KEY REFERENCES RepairTask(Id),
    Quantity         DECIMAL(5,2) NOT NULL DEFAULT 1,
    LaborCostAtUse   DECIMAL(10,2) NOT NULL,
    Note             NVARCHAR(255),
    PRIMARY KEY (WorkOrderId, RepairTaskId)
);
GO

--------------------------------------------------------------------------------

CREATE TABLE WorkOrderPart (
    Id                INT IDENTITY(1,1) PRIMARY KEY,
    WorkOrderId       INT NOT NULL FOREIGN KEY REFERENCES WorkOrder(Id),
    PartId            INT NOT NULL FOREIGN KEY REFERENCES Part(Id),
    QuantityUsed      DECIMAL(10,2) NOT NULL,
    UnitPriceAtUse    DECIMAL(10,2) NOT NULL,
    CreatedAt         DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------

CREATE TABLE Invoice (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    WorkOrderId     INT NOT NULL UNIQUE FOREIGN KEY REFERENCES WorkOrder(Id),
    Subtotal        DECIMAL(12,2) NOT NULL,
    Discount        DECIMAL(12,2) NOT NULL DEFAULT 0,
    TaxRate         DECIMAL(5,2)  NOT NULL,
    TaxAmount       DECIMAL(12,2) NOT NULL,
    TotalAmount     DECIMAL(12,2) NOT NULL,
    PaymentStatus   NVARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (PaymentStatus IN ('Pending', 'Paid', 'Cancelled')),
    IssuedAt        DATETIME2 NOT NULL,
    IsDeleted       BIT           NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2,
    CreatedAt       DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- TRIGGERS FOR UPDATED_AT
--------------------------------------------------------------------------------

-- Trigger for User table
CREATE TRIGGER trg_User_UpdatedAt
ON [User]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u
    SET UpdatedAt = GETDATE()
    FROM [User] u
    INNER JOIN inserted i ON u.Id = i.Id;
END;
GO

-- Trigger for Customer table
CREATE TRIGGER trg_Customer_UpdatedAt
ON Customer
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET UpdatedAt = GETDATE()
    FROM Customer c
    INNER JOIN inserted i ON c.Id = i.Id;
END;
GO

-- Trigger for Vehicle table
CREATE TRIGGER trg_Vehicle_UpdatedAt
ON Vehicle
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE v
    SET UpdatedAt = GETDATE()
    FROM Vehicle v
    INNER JOIN inserted i ON v.Id = i.Id;
END;
GO

-- Trigger for Employee table
CREATE TRIGGER trg_Employee_UpdatedAt
ON Employee
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE e
    SET UpdatedAt = GETDATE()
    FROM Employee e
    INNER JOIN inserted i ON e.Id = i.Id;
END;
GO

-- Trigger for WorkOrder table
CREATE TRIGGER trg_WorkOrder_UpdatedAt
ON WorkOrder
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE wo
    SET UpdatedAt = GETDATE()
    FROM WorkOrder wo
    INNER JOIN inserted i ON wo.Id = i.Id;
END;
GO

-- Trigger for RepairTask table
CREATE TRIGGER trg_RepairTask_UpdatedAt
ON RepairTask
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE rt
    SET UpdatedAt = GETDATE()
    FROM RepairTask rt
    INNER JOIN inserted i ON rt.Id = i.Id;
END;
GO

-- Trigger for Part table
CREATE TRIGGER trg_Part_UpdatedAt
ON Part
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET UpdatedAt = GETDATE()
    FROM Part p
    INNER JOIN inserted i ON p.Id = i.Id;
END;
GO
