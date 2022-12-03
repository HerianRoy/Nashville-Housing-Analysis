USE nash_housing;

SELECT 
    *
FROM
    nash_housing_table;

-- PROCESSING DATASET

-- Renaming Field
ALTER TABLE nash_housing_table
RENAME COLUMN ï»¿UniqueID TO UniqueID;


-- Getting Datatype of each field
SELECT 
    column_name, data_type
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    table_schema = 'nash_housing'
        AND table_name = 'nash_housing_table';


-- Populate PropertyAddress Field
SELECT
	*
FROM
    nash_housing_table
WHERE
    PropertyAddress IS NULL;

SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress) AS fillers
FROM
    nash_housing_table a
        JOIN
    nash_housing_table b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
WHERE
    a.PropertyAddress IS NULL
ORDER BY a.ParcelID;

UPDATE nash_housing_table a
        JOIN
    nash_housing_table b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID 
SET 
    a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE
    a.PropertyAddress IS NULL;

-- Breaking out address into separate columns
SELECT PropertyAddress
FROM nash_housing_table;

SELECT 
  SUBSTRING_INDEX(PropertyAddress, ',', 1)  AS Address,
  SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City
FROM
	nash_housing_table;

ALTER TABLE nash_housing_table
ADD Address VARCHAR(50)
	AFTER PropertyAddress,
ADD City VARCHAR(20)
	AFTER Address;

UPDATE nash_housing_table
SET 
    Address = SUBSTRING_INDEX(PropertyAddress, ',', 1),
    City = SUBSTRING_INDEX(PropertyAddress, ',', -1);

SELECT *
FROM nash_housing_table;

-- Formatting Date
SELECT 
    *
FROM
    nash_housing_table
WHERE
    SaleDate IS NULL;

UPDATE nash_housing_table
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

ALTER TABLE nash_housing_table
MODIFY COLUMN SaleDate DATE;

-- Changing Y/N to Yes/No in 'SoldAsVacant' field
SELECT 
    *
FROM
    nash_housing_table
WHERE
    SoldAsVacant IS NULL;

SELECT DISTINCT
    (SoldAsVacant), COUNT(SoldAsVacant)
FROM
    nash_housing_table
GROUP BY SoldAsVacant;

SELECT 
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'N' THEN 'No'
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        ELSE SoldAsVacant
    END AS NewCol
FROM
    nash_housing_table;

UPDATE nash_housing_table 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'N' THEN 'No'
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        ELSE SoldAsVacant
    END;
 
-- Filling NULL values in OwnerName with 'No Data'
SELECT 
    *
FROM
    nash_housing_table
WHERE
    OwnerName IS NULL;

UPDATE nash_housing_table 
SET 
    OwnerName = 'No Data'
WHERE
    OwnerName IS NULL;
 
-- Transforming Catagories in LandUse Field
SELECT 
    *
FROM
    nash_housing_table;

SELECT DISTINCT
    (LandUse), COUNT(LandUse) Count
FROM
    nash_housing_table
GROUP BY LandUse
ORDER BY Count DESC;

UPDATE
	nash_housing_table
SET
	LandUse = 'VACANT RESIDENTIAL LAND'
WHERE
	LandUse IN ('VACANT RES LAND', 'VACANT RESIENTIAL LAND');

UPDATE
	nash_housing_table
SET
	LandUse = 'OTHERS'
WHERE
	LandUse NOT IN ('SINGLE FAMILY', 'RESIDENTIAL CONDO', 'VACANT RESIDENTIAL LAND');
    
-- Removing Duplicates
WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY
		ParcelID,
        PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
    ORDER BY
		UniqueID) row_num
FROM
	nash_housing_table
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY
		ParcelID,
        PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
    ORDER BY
		UniqueID) row_num
FROM
	nash_housing_table
)
DELETE t1
FROM nash_housing_table t1
	JOIN
		RowNumCTE t2 ON t1.UniqueID = t2.UniqueID
WHERE t2.row_num > 1;

-- Deleting Columns
SELECT *
FROM nash_housing_table;

-- Deleting Rows
DELETE
FROM nash_housing_table
WHERE YEAR(SaleDate) = 2019;

-- EXPLORATORY DATA ANALYSIS
SELECT
	*
FROM
    nash_housing_table;

SELECT
	COUNT(SalePrice) CountPrice,
    MIN(SalePrice) MinPrice,
    MAX(SalePrice) MaxPrice,
   AVG(SalePrice) AvgPrice
FROM
    nash_housing_table;
 
-- EXTRACTING DATA FOR ANALYSIS

-- Annual Sales
SELECT 
    YEAR(SaleDate) AS CalendarYear,
    SUM(SalePrice) AS TotalPrice
FROM
    nash_housing_table
		
GROUP BY CalendarYear;

-- 2) Number of properties sold every year in every city
SELECT
	City,
    YEAR(SaleDate) AS CalendarYear,
    COUNT(ParcelID) AS No_of_Sold_Properties,
    SUM(SalePrice) AS TotalSales
FROM
	nash_housing_table
GROUP BY City, CalendarYear;

-- 3) Number of properties sold every year by Land Use
SELECT
	LandUse,
    YEAR(SaleDate) AS CalendarYear,
    COUNT(ParcelID) AS No_of_Sold_Properties,
    SUM(SalePrice) AS TotalSales
FROM
	nash_housing_table
GROUP BY LandUse, CalendarYear;

-- 4) Number of properties sold every year in every city by land use 
SELECT
	City,
    LandUse,
    YEAR(SaleDate) AS CalendarYear,
    COUNT(ParcelID) AS No_of_Sold_Properties,
    SUM(SalePrice) AS TotalSales
FROM
	nash_housing_table
GROUP BY City, LandUse, CalendarYear;

-- END