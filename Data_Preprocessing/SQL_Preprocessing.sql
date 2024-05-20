CREATE DATABASE proj;
USE proj;

SELECT * FROM data_set;

/********* First Moment Business Decision/Measures of central Tendency(Mean, Median, Mode) *********/
                  /***** Calculation of Mean *****/ 
SELECT AVG(No_of_kits) AS mean_No_of_kits
FROM data_set;

                  /***** Calculation of Median *****/
SELECT No_of_kits AS median_No_of_kits
FROM (
    SELECT No_of_kits, ROW_NUMBER() OVER (ORDER BY No_of_kits) AS row_num,
           COUNT(*) OVER () AS total_count
    FROM Data_set
) AS subquery
WHERE row_num = (total_count + 1) / 2 OR row_num = (total_count + 2) / 2; 
    
               /***** Calculation of Mode *****/    
select Customer_Code, count(Customer_Code) as frequency from data_set
group by Customer_Code
order by frequency desc limit 1;

select Customer_Name, count(Customer_Name) as frequency from data_set
group by Customer_Name
order by frequency desc 
limit 1;

select KIT_ITEM, count(KIT_ITEM) as frequency from data_set
group by KIT_ITEM
order by frequency desc ;

select OEM, count(OEM) as frequency from data_set
group by OEM
order by frequency desc ;

select Item_Description, count(Item_Description) as frequency from data_set
group by Item_Description
order by frequency desc
limit 1 ;

select Product_type, count(Product_type) as frequency 
      from data_set
	  group by Product_type
order by frequency desc ;

select Item_Code, count(Item_Code) as frequency 
        from data_set
        group by Item_Code
        order by frequency desc
limit 1 ;

select No_of_kits, count(No_of_kits) as frequency from data_set
group by No_of_kits
order by frequency desc limit 1 ;

/********* Second Moment Business Decision/Measures of Dispersion *********/
           /***** Calculation of  Variance *****/ 
SELECT VARIANCE(No_of_kits) AS No_of_kits_variance
FROM data_set;

		   /***** Calculation of  Standard Deviation *****/ 
SELECT STDDEV(No_of_kits) AS No_of_kits_stddev
FROM data_set;

           /***** Calculation of  Range *****/ 
select max(No_of_kits) as max_value, 
	   min(No_of_kits) as min_value,
	   max(No_of_kits) - min(No_of_kits)
 as range_value from data_set;

/*********  3RD  And 4TH Moment Business Decision *********/ 
	    /***** Skewness and Kurtosis  *****/
/** Skewness **/
SELECT 
    (
        SUM(POWER(No_of_kits - (SELECT AVG(No_of_kits) FROM data_set), 3)) /
        (COUNT(*) * POWER((SELECT STDDEV(No_of_kits) FROM data_set), 3))
    ) AS skewness
FROM 
    data_set;

/** Kurtosis **/
SELECT 
    (
        (
            SUM(POWER(No_of_kits - (SELECT AVG(No_of_kits) FROM data_set), 4)) /
            (COUNT(*) * POWER((SELECT STDDEV(No_of_kits) FROM data_set), 4))
        ) - 3
    ) AS Kurtosis
FROM 
    data_set
LIMIT 0, 50000;


        /******************** Data Preprocessing ********************/
                          /** Typecasting **/
ALTER TABLE data_set 
MODIFY COLUMN customer_name VARCHAR(20),
MODIFY COLUMN customer_code int,
MODIFY COLUMN kit_item VARCHAR(20),
MODIFY COLUMN oem VARCHAR(30),
MODIFY COLUMN item_description VARCHAR(255),
MODIFY COLUMN item_code VARCHAR(40);
UPDATE data_set 
SET Date = STR_TO_DATE(Date, '%m/%d/%Y %H:%i');
ALTER TABLE data_set MODIFY COLUMN Date DATE;

                          /************** Missing Values ***************/
/***** item_description *****/
UPDATE data_set
SET No_of_kits = NULL
WHERE No_of_kits = '-' ;
select count(*) from data_set where item_description IS NULL;

/***** Mode Imputation for item_description *****/
UPDATE data_set
SET item_description = (
    SELECT mode_val
    FROM (
        SELECT item_description AS mode_val
        FROM data_set
        WHERE item_description IS NOT NULL
        GROUP BY item_description
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE item_description IS NULL;

/***** Product_type *****/
UPDATE data_set
SET product_type= NULL
WHERE product_type = '-' ;
select count(*) from data_set where product_type IS NULL;

## *** Mode Imputation for product_type *** ##
UPDATE data_set
SET product_type = (
    SELECT mode_val
    FROM (
        SELECT product_type AS mode_val
        FROM data_set
        WHERE product_type IS NOT NULL
        GROUP BY product_type
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS temp
)
WHERE product_type IS NULL;

## *** Median Imputation *** ##
UPDATE data_set SET No_of_kits = 130
 WHERE No_of_kits IS NULL;

                          # ****** Handling Duplicates ****** #
SELECT customer_name,customer_code,kit_item,oem,item_description,product_type,item_code,Date,No_of_Kits, COUNT(*) as duplicate_count
FROM data_set
GROUP BY customer_name,customer_code,kit_item,oem,item_description,product_type,item_code,Date,No_of_Kits
HAVING COUNT(*) > 1;

## *** Drop duplicates *** ##
CREATE TABLE temp_unique AS
SELECT DISTINCT *
FROM data_set;

TRUNCATE TABLE data_set;

INSERT INTO data_set
SELECT * FROM temp_unique;

DROP TABLE temp_unique;

			/********************* Finding Outliers ************************/
SELECT *
FROM data_set
WHERE ABS(No_of_kits - (SELECT AVG(No_of_kits) FROM data_set)) / (SELECT STDDEV(No_of_kits) FROM data_set) > 3;
                    
/******** Mean and Standard Deviation of No_of_kits Column ********/
SET @mean = (SELECT AVG(No_of_kits) FROM data_set);
SET @stddev = (SELECT STDDEV(No_of_kits) FROM data_set);

					/**************** Zero & near Zero Variance ****************/
SELECT
VARIANCE(No_of_kits) AS Column1_variance
FROM data_set;

					/**************** Discretization ****************/
SELECT Customer_Code, NTILE(5) OVER (ORDER BY No_of_kits) AS No_of_kits_Bin 
FROM data_set;
 
				/********************* Label Encoding *********************/
/***** Assign numerical labels to categorical values using case statements *****/
SELECT
     CASE
     WHEN Product_type = "A" THEN 1
     WHEN Product_type = "B" THEN 2
     ELSE 3
   END AS Product_type_Label
FROM data_set;

				/********************* Dummy/ One Hot/ Binary Encoding *********************/ 
SELECT
     CASE WHEN Product_type = "A" THEN 1 ELSE 0  END AS Product_type_A,
     CASE WHEN Product_type = "B" THEN 1 ELSE 0 END AS Product_type_B,
	 CASE WHEN Product_type = "C" THEN 1 ELSE 0 END AS Product_type_C
FROM data_set;
   
SET SQL_SAFE_UPDATES = 0;

			/********************* Transformations of Linearization **********************/
UPDATE data_set 
SET No_of_kits = LOG(NULLIF(No_of_kits, 0));


			/********************** Normalization *********************/
SELECT 
    (LOG(No_of_kits + 1) - MIN_MAX.min_log_kits) / (MIN_MAX.max_log_kits - MIN_MAX.min_log_kits) AS Normalized_log_kits 
FROM    
    data_set,        
    (SELECT    
        MIN(LOG(No_of_kits + 1)) AS min_log_kits,    
        MAX(LOG(No_of_kits + 1)) AS max_log_kits    
    FROM data_set) AS MIN_MAX;
    
			/********************* EDA AFTER DATA PREPROCESSING  *********************/
/***** Mean *****/   
SELECT AVG(No_of_kits) AS mean_No_of_kits
FROM data_set;
    
/***** Median *****/   
SELECT No_of_kits AS median_No_of_kits
FROM (
    SELECT No_of_kits, ROW_NUMBER() OVER (ORDER BY No_of_kits) AS row_num,
           COUNT(*) OVER () AS total_count
    FROM data_set
) AS subquery
WHERE row_num = (total_count + 1) / 2 OR row_num = (total_count + 2) / 2; 
    
/***** Mode *****/
select Customer_Code, count(Customer_Code) as frequency from data_set
group by Customer_Code
order by frequency desc limit 1;

select Customer_Name, count(Customer_Name) as frequency from data_set
group by Customer_Name
order by frequency desc 
limit 1;

select KIT_ITEM, count(KIT_ITEM) as frequency from data_set
group by KIT_ITEM
order by frequency desc ;

select OEM, count(OEM) as frequency from data_set
group by OEM
order by frequency desc ;

select Item_Description, count(Item_Description) as frequency from data_set
group by Item_Description
order by frequency desc
limit 1 ;

select Product_type, count(Product_type) as frequency 
      from data_set
	  group by Product_type
order by frequency desc ;

select Item_Code, count(Item_Code) as frequency 
        from data_set
        group by Item_Code
        order by frequency desc
limit 1 ;

select No_of_kits, count(No_of_kits) as frequency from data_set
group by No_of_kits
order by frequency desc limit 1 ;

/***** Variance *****/
SELECT VARIANCE(No_of_kits) AS No_of_kits_variance
FROM data_set;

/***** Standard Deviation *****/
SELECT STDDEV(No_of_kits) AS No_of_kits_stddev
FROM data_set;

/***** Range *****/
select max(No_of_kits) as max_value, 
	   min(No_of_kits) as min_value,
	   max(No_of_kits) - min(No_of_kits)
 as range_value from data_set;

/***** Skewness *****/
SELECT
    (
        SUM(POWER(No_of_kits - (SELECT AVG(No_of_kits) FROM data_set), 3)) / 
        (COUNT(*) * POWER((SELECT STDDEV(No_of_kits) FROM data_set), 3))
    ) AS skewness
FROM data_set;


/*****Kurtosis *****/
SELECT 
    (
        (
            SUM(POWER(No_of_kits - (SELECT AVG(No_of_kits) FROM data_set), 4)) / 
            (COUNT(*) * POWER((SELECT STDDEV(No_of_kits) FROM data_set), 4))
        ) - 3
    ) AS Kurtosis
FROM data_set
LIMIT 0, 10000;    
