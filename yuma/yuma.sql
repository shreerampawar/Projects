select * from sales;

START TRANSACTION;


-- Counting Nulls, nans and ''
SELECT 
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN TransactionID IS NULL OR TransactionID = '' OR TransactionID = 'nan' THEN 1 ELSE 0 END) AS TransactionID_Missing,
    SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' OR CustomerID = 'nan' THEN 1 ELSE 0 END) AS CustomerID_Missing,
    SUM(CASE WHEN TransactionDate IS NULL OR TransactionDate = '' OR TransactionDate = 'nan' THEN 1 ELSE 0 END) AS TransactionDate_Missing,
    SUM(CASE WHEN ProductID IS NULL OR ProductID = '' OR ProductID = 'nan' THEN 1 ELSE 0 END) AS ProductID_Missing,
    SUM(CASE WHEN ProductCategory IS NULL OR ProductCategory = '' OR ProductCategory = 'nan' THEN 1 ELSE 0 END) AS ProductCategory_Missing,
    SUM(CASE WHEN Quantity IS NULL OR Quantity = '' OR Quantity = 'nan' THEN 1 ELSE 0 END) AS Quantity_Missing,
    SUM(CASE WHEN PricePerUnit IS NULL OR PricePerUnit = '' OR PricePerUnit = 'nan' THEN 1 ELSE 0 END) AS PricePerUnit_Missing,
    SUM(CASE WHEN TotalAmount IS NULL OR TotalAmount = '' OR TotalAmount = 'nan' THEN 1 ELSE 0 END) AS TotalAmount_Missing,
    SUM(CASE WHEN TrustPointsUsed IS NULL OR TrustPointsUsed = '' OR TrustPointsUsed = 'nan' THEN 1 ELSE 0 END) AS TrustPointsUsed_Missing,
    SUM(CASE WHEN PaymentMethod IS NULL OR PaymentMethod = '' OR PaymentMethod = 'nan' THEN 1 ELSE 0 END) AS PaymentMethod_Missing,
    SUM(CASE WHEN DiscountApplied IS NULL OR DiscountApplied = '' OR DiscountApplied = 'nan' THEN 1 ELSE 0 END) AS DiscountApplied_Missing
FROM 
    yuma.sales;

-- Replace empty strings and 'nan' with NULL
UPDATE yuma.sales
SET 
    CustomerID = NULLIF(NULLIF(CustomerID, ''), 'nan'),
    TransactionDate = NULLIF(NULLIF(TransactionDate, ''), 'nan'),
    PricePerUnit = NULLIF(NULLIF(PricePerUnit, ''), 'nan'),
    TotalAmount = NULLIF(NULLIF(TotalAmount, ''), 'nan'),
    PaymentMethod = NULLIF(NULLIF(PaymentMethod, ''), 'nan'),
    DiscountApplied = NULLIF(NULLIF(DiscountApplied, ''), 'nan');


-- Adjusting the date and time values
UPDATE yuma.sales
SET TransactionDate = STR_TO_DATE(TransactionDate, '%d/%m/%y %H:%i')
WHERE TransactionDate IS NOT NULL;

ALTER TABLE yuma.sales
MODIFY COLUMN TransactionDate DATETIME;


-- Changing the datatypes
ALTER TABLE yuma.sales
MODIFY COLUMN CustomerID INT;

ALTER TABLE yuma.sales
MODIFY COLUMN PricePerUnit FLOAT;

ALTER TABLE yuma.sales
MODIFY COLUMN TotalAmount FLOAT;

ALTER TABLE yuma.sales
MODIFY COLUMN Quantity INT;

ALTER TABLE yuma.sales
MODIFY COLUMN TrustPointsUsed INT;

ALTER TABLE yuma.sales
MODIFY COLUMN DiscountApplied FLOAT;


-- Removing rows with null values
DELETE FROM yuma.sales
WHERE CustomerID IS NULL
   OR TransactionDate IS NULL;
   
   
-- Converting negative values to positive
UPDATE yuma.sales
SET 
    TotalAmount = ABS(TotalAmount),
    Quantity = ABS(Quantity),
    TrustPointsUsed = ABS(TrustPointsUsed);


-- Imputation inplace of nulls
-- Find the mode value for PaymentMethod
SET @mode_payment_method = (
    SELECT PaymentMethod
    FROM yuma.sales
    GROUP BY PaymentMethod
    ORDER BY COUNT(*) DESC
    LIMIT 1
);
-- Replace NULL values with the mode payment method
UPDATE yuma.sales
SET PaymentMethod = @mode_payment_method
WHERE PaymentMethod IS NULL;
-- Commit changes for mode imputation


-- Calculate the median value for PricePerUnit and update NULLs in the same query
-- Initialize row index
SET @rowindex := -1;

UPDATE yuma.sales
SET PricePerUnit = (
    SELECT AVG(d.PricePerUnit)
    FROM (
        SELECT @rowindex := @rowindex + 1 AS rowindex,
               y.PricePerUnit AS PricePerUnit
        FROM yuma.sales y
        WHERE y.PricePerUnit IS NOT NULL
        ORDER BY y.PricePerUnit
    ) AS d
    WHERE d.rowindex IN (FLOOR(@rowindex / 2), CEIL(@rowindex / 2))
)
WHERE PricePerUnit IS NULL;


-- Calculate the median value for Discount Applied and update NULLs in the same query
-- Initialize row index
SET @rowindex := -1;

UPDATE yuma.sales
SET DiscountApplied = (
    SELECT AVG(d.DiscountApplied) AS Median
    FROM (
        SELECT @rowindex := @rowindex + 1 AS rowindex,
               y.DiscountApplied AS DiscountApplied
        FROM yuma.sales y
        WHERE y.DiscountApplied IS NOT NULL
        ORDER BY y.DiscountApplied
    ) AS d
    WHERE d.rowindex IN (FLOOR(@rowindex / 2), CEIL(@rowindex / 2))
)
WHERE DiscountApplied IS NULL;


-- Replace 0s in Quantity with the calculated median
-- Initialize row index
SET @rowindex := -1;

UPDATE yuma.sales
SET Quantity = (
    SELECT AVG(d.Quantity) AS Median
    FROM (
        SELECT @rowindex := @rowindex + 1 AS rowindex,
               y.Quantity AS Quantity
        FROM yuma.sales y
        WHERE y.Quantity > 0
        ORDER BY y.Quantity
    ) AS d
    WHERE d.rowindex IN (FLOOR(@rowindex / 2), CEIL(@rowindex / 2))
)
WHERE Quantity = 0;


-- Replacing nulls in Total Amount by the product of quantity and price per unit
UPDATE yuma.sales
SET TotalAmount = Quantity * PricePerUnit
WHERE TotalAmount IS NULL;
COMMIT;