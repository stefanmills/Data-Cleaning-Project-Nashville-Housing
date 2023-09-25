--Checking the Datatypes of all the columns
EXEC 
	sp_help DataCleaning_NashvilleHousing

--Routine To check all the data which has been imported
SELECT *
FROM DataCleaning_NashvilleHousing

--Changing the SalesDate and make it just date without the time
SELECT NewSaleDate, CONVERT(Date,SaleDate)
--The first parameter after the convert is the new datatype
FROM DataCleaning_NashvilleHousing

ALTER TABLE DataCleaning_NashvilleHousing
ADD NewSaleDate Date;

UPDATE DataCleaning_NashvilleHousing
SET NewSaleDate=CONVERT(Date,SaleDate)

--Populating the Property Address
--Routine Checks to see which property address is null
SELECT *
FROM DataCleaning_NashvilleHousing
WHERE PropertyAddress is null

--From checks Every ParcelID has an address linked to it
-- So we have to populate the PropertyAddress column with the addressed linked to the ParcelID in the case where the Property Address is null
SELECT Tab1.ParcelID,Tab1.PropertyAddress,Tab2.ParcelID,Tab2.PropertyAddress
FROM DataCleaning_NashvilleHousing Tab1
JOIN DataCleaning_NashvilleHousing Tab2 --SELFJOIN
ON Tab1.ParcelID=Tab2.ParcelID AND Tab1.UniqueID<>Tab2.UniqueID
WHERE Tab1.PropertyAddress is null 

--Update PropertyAddress Column which is Null with the Tab2PropertyAddress
UPDATE Tab1
SET PropertyAddress= ISNULL(Tab1.PropertyAddress,Tab2.PropertyAddress)
FROM DataCleaning_NashvilleHousing Tab1
JOIN DataCleaning_NashvilleHousing Tab2 --SELFJOIN
ON Tab1.ParcelID=Tab2.ParcelID AND Tab1.UniqueID<>Tab2.UniqueID
WHERE Tab1.PropertyAddress is null 

SELECT Tab1.ParcelID,Tab1.PropertyAddress,Tab2.ParcelID,Tab2.PropertyAddress
FROM DataCleaning_NashvilleHousing Tab1
JOIN DataCleaning_NashvilleHousing Tab2 --SELFJOIN
ON Tab1.ParcelID=Tab2.ParcelID AND Tab1.UniqueID<>Tab2.UniqueID


--Breaking Down Address into Individual Columns (Address,City,State)
SELECT PropertyAddress
FROM DataCleaning_NashvilleHousing
--(From the Data above you realized that there is a comma separating the address and city. Let's try spliting it)

SELECT 
--SUBSTRING Take 3 Parameters : ColumnName, StartCharacter, EndCharacter
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress )-1) AS Address,
--So we start with the PropertyAddress first character until we meet the ','
--Minus 1 because if we dont put it there the Address ends with a comma so the -1 will help eliminate the comma
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress )+1, LEN(PropertyAddress)) AS State
--So now the CHARINDEX becomes our first character
FROM DataCleaning_NashvilleHousing 

--Create New Columns

ALTER TABLE DataCleaning_NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE DataCleaning_NashvilleHousing
SET PropertySplitAddress=SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress )-1)

ALTER TABLE DataCleaning_NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE DataCleaning_NashvilleHousing
SET PropertySplitCity=SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress )+1, LEN(PropertyAddress))


--Using PARSENAME for delimiting (ParseName Works with instances where there are fullstop)
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM DataCleaning_NashvilleHousing

ALTER TABLE DataCleaning_NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);
ALTER TABLE DataCleaning_NashvilleHousing
ADD OwnerSplitCity nvarchar(255);
ALTER TABLE DataCleaning_NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE DataCleaning_NashvilleHousing
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.'),3)
UPDATE DataCleaning_NashvilleHousing
SET OwnerSplitCity=PARSENAME(REPLACE(OwnerAddress,',','.'),2)
UPDATE DataCleaning_NashvilleHousing
SET OwnerSplitState=PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--Work on the soldAsVacant
--Changing the Y to YES and N to No

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant= 'N' THEN 'NO'
	ELSE SoldAsVacant
	END
FROM DataCleaning_NashvilleHousing

UPDATE DataCleaning_NashvilleHousing
SET SoldAsVacant=CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant= 'N' THEN 'NO'
	ELSE SoldAsVacant
	END

	SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
	FROM DataCleaning_NashvilleHousing
	GROUP BY SoldAsVacant
	
--REMOVING DUPLICATES USING A CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	SalePrice,SaleDate,PropertyAddress,LegalReference --(we chose this data because we assume if these datas are the same, then its not useful)
	ORDER BY
		UniqueID) row_num
FROM DataCleaning_NashvilleHousing
)
SELECT * FROM RowNumCTE
 

DELETE  FROM RowNumCTE
WHERE row_num>1  


 

--Deleting Unused Columns
ALTER TABLE DataCleaning_NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress,SaleDate


