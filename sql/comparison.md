| Query                                                 | Before Indexes                               | After Indexes                            | Improvement                                       |
| ----------------------------------------------------- | -------------------------------------------- | ---------------------------------------- | ------------------------------------------------- |
| Employee Dashboard Query (`WorkOrderEmployee`)        | 3883 logical reads, 31 ms CPU, 48 ms elapsed | 5 logical reads, 15 ms CPU, 6 ms elapsed | Massive reduction in reads and execution time     |
| Customer Vehicles Query (`Vehicle`)                   | 126 logical reads, 16 ms CPU, 1 ms elapsed   | 10 logical reads, 0 ms CPU, 0 ms elapsed | Faster lookup with fewer reads                    |
| Work Order Parts Query (`WorkOrderPart`)              | 3211 logical reads, 31 ms CPU, 30 ms elapsed | 3 logical reads, 0 ms CPU, 0 ms elapsed  | Extremely improved performance                    |
| Work Order Repair Tasks Query (`WorkOrderRepairTask`) | 3 logical reads, 0 ms CPU, 0 ms elapsed      | 3 logical reads, 0 ms CPU, 0 ms elapsed  | Already optimized by clustered PK                 |
| Employee Salary History Query                         | 28 logical reads, 16 ms CPU, 1 ms elapsed    | 2 logical reads, 0 ms CPU, 0 ms elapsed  | Improved historical lookup efficiency             |
| Part Price History Query                              | 2 logical reads, 0 ms CPU, 1 ms elapsed      | 2 logical reads, 0 ms CPU, 0 ms elapsed  | Slight improvement                                |
| Appointment Lookup Query                              | Large table scan behavior                    | Efficient indexed lookup                 | Significant improvement in filtering and ordering |

Overall, the indexes significantly reduced logical reads, CPU time, and elapsed time by converting expensive table scans into efficient index seeks, especially on large transactional tables such as `WorkOrderEmployee` and `WorkOrderPart`. 
