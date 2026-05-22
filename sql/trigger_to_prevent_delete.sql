USE master;
GO

CREATE OR ALTER TRIGGER trg_PreventDropDatabase_ExceptManager
ON ALL SERVER
FOR DROP_DATABASE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoginName sysname = ORIGINAL_LOGIN();

    -- allow only the manager/admin login
    IF @LoginName <> N'YourManagerLogin'
    BEGIN
        ROLLBACK;
        THROW 50001, 'Only the admin/manager is allowed to delete a database.', 1;
    END
END;
GO