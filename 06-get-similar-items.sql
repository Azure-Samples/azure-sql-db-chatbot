-- Take a look at the vector
select top(1)
	json_query(response, '$.result.data[0].embedding') 
from 
	dbo.http_response
go

-- How many products overall?
select count(*) from dbo.[walmart_ecommerce_product_details]
go

-- Similarity Search
drop table if exists dbo.similar_items
declare @top int = 50
declare @min_similarity decimal(19,16) = 0.75
drop table if exists ##s;
declare @qv varbinary(8000) = (
	select top(1)
		json_array_to_vector(json_query(response, '$.result.data[0].embedding')) as query_vector
	from 
		dbo.http_response
)
select top(@top)    
    p.id,
    vector_distance('cosine', @qv, embedding) as distance,
    p.[product_name],
    p.[description],
    p.category
into
    dbo.similar_items
from 
    dbo.[walmart_ecommerce_product_details] p 
where
    vector_distance('cosine', @qv, embedding) <= 1-@min_similarity
order by    
    distance;
;

select 
	*,
	similarity = 1-distance 
from 
    dbo.similar_items
order by    
    distance;
go
