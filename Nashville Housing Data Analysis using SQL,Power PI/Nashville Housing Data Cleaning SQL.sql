/* Cleaning Nashville Housing Data using SQl */

select * from Nashville_Housing

-- convert date format

Alter Table Nashville_Housing
add saledateconverted Date;

Update Nashville_Housing
set saledateconverted=CONVERT(Date,SaleDate)

-- Where PropertyAddress is null

select * from Nashville_Housing
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from Nashville_Housing a
join Nashville_Housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- If two entries share the same ParcelID but one has a property address and the other does not,
-- then the property address from one entry will be added to the row lacking one. 

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from Nashville_Housing a
join Nashville_Housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
from Nashville_Housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
from Nashville_Housing

alter table Nashville_Housing
Add PropertySplitAddress Nvarchar(255);

update Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

alter table Nashville_Housing
Add PropertySplitCity Nvarchar(255);

update Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

select * from Nashville_Housing

Select OwnerAddress
From Nashville_Housing

-- I used the Replace command to replace the commas in the OWNER’s ADDRESS COLUMN with periods.
-- Then once that was complete the Parsename command is able to separate the address, city, and sate with the periods that were placed.

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Nashville_Housing

ALTER TABLE Nashville_Housing
Add OwnerSplitAddress Nvarchar(255);

Update Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE Nashville_Housing
Add OwnerSplitCity Nvarchar(255);

Update Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE Nashville_Housing
Add OwnerSplitState Nvarchar(255);

Update Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

select * from Nashville_Housing

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
from Nashville_Housing
Group by SoldAsVacant
order by 2

update Nashville_Housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- checking to see if there is any duplicate rows

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Nashville_Housing
)
Select *
From RowNumCTE
Where row_num > 1

-- First, I used a combination of ROW_Number which create a temporary value calculated when the query is run and Partition by which specifies the columns I want to aggregate. 
-- In this particular query I am specifying the PropertyAddress, SalePrice, SaleDate, and LegalReference which I am using as the main components needed to know if a row is a duplicate or not. 
-- Once the query is able to verify a rows info matches another row in the data set that row is then labeled as row_num 2. 
-- Then to get these duplicated rows in one table I created a common table expression where my generated row_num is greater than 1. 
-- This CTE creates a temporary table once the query was finished executing containing all the duplicate rows.

-- Deleting Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By
				 UniqueID
				 ) row_num

From Nashville_Housing
)

DELETE
From RowNumCTE
Where row_num > 1

select * from Nashville_Housing

-- Delete Unused Columns

ALTER TABLE Nashville_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

select * from Nashville_Housing