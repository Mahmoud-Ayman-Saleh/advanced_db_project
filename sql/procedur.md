| Stored Procedure Name         | Why It Was Created                                                                                                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sp_CreateWorkOrder`          | Creates a new work order for a vehicle while validating that the vehicle exists and initializing the repair workflow.                                               |
| `sp_AddPartToWorkOrder`       | Adds parts to a work order, locks the current part price (`UnitPriceAtUse`), and updates inventory stock automatically.                                             |
| `sp_AddRepairTaskToWorkOrder` | Adds repair tasks to a work order and locks the labor cost (`LaborCostAtUse`) at the time of assignment to prevent future price changes from affecting the invoice. |
| `sp_UpdateWorkOrderState`     | Controls valid work order state transitions (`Scheduled → In_Progress → Completed/Cancelled`) and enforces workflow rules.                                          |
| `sp_RecordPartUsage`          | Updates the actual quantity of parts used during repair and synchronizes inventory stock quantities accordingly.                                                    |
| `sp_GenerateInvoice`          | Generates invoices automatically for completed work orders by calculating subtotal, tax, discount, and total amount using locked prices and labor costs.            |
