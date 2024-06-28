/*
    Create a column to store the embeddings as a native vector format.
*/
alter table dbo.[walmart_ecommerce_product_details]
add embedding_vector varbinary(8000)
go

/*
    Convert the JSON array to a native vector format.
*/
update dbo.[walmart_ecommerce_product_details]
set embedding_vector = json_array_to_vector(embedding)
go

/*
    Drop the JSON column.
*/
alter table dbo.[walmart_ecommerce_product_details]
drop column [embedding]
go

/*
    Rename the new column to the original column name.
*/
exec sp_rename 'dbo.[walmart_ecommerce_product_details].embedding_vector', 'embedding', 'COLUMN'
go

/*
    Look at the first row to verify the conversion.
*/
select top (1) * from dbo.[walmart_ecommerce_product_details]