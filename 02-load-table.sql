/*
	Cleanup if needed
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$w0rd!'
end
go
if exists(select * from sys.[external_data_sources] where name = 'openai_playground')
begin
	drop external data source [openai_playground];
end
go
if exists(select * from sys.[database_scoped_credentials] where name = 'openai_playground')
begin
	drop database scoped credential [openai_playground];
end
go

/*
	Create database scoped credential and external data source.
	File is assumed to be in a path like: 
	https://<myaccount>.blob.core.windows.net/playground/wikipedia/vector_database_wikipedia_articles_embedded.csv
*/
create database scoped credential [openai_playground]
with identity = 'SHARED ACCESS SIGNATURE',
secret = ''; -- make sure not to include the ? at the beginning
go
create external data source [openai_playground]
with 
( 
	type = blob_storage,
 	location = 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/playground',
 	credential = [openai_playground]
);
go

/*
    Import data
*/
bulk insert dbo.[walmart_ecommerce_product_details]
from 'walmart/walmart-product-with-embeddings-dataset-usa.csv'
with (
	data_source = 'openai_playground',
    format = 'csv',
    firstrow = 2,
    codepage = '65001',
	fieldterminator = ',',
	rowterminator = '0x0a',
    fieldquote = '"',
    batchsize = 1000,
    tablock
)
go

/*
	Add indexes
*/
create unique clustered index ixc on dbo.[walmart_ecommerce_product_details](id)
go