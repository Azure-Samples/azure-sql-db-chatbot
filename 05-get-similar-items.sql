-- How many products overall?
select count(*) from dbo.[walmart_ecommerce_product_details]
go

-- Similarity Search
drop table if exists dbo.similar_items
declare @top int = 50
declare @min_similarity decimal(19,16) = 0.75
drop table if exists ##s;

declare @text nvarchar(max) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff'
declare @qv vector(1536) = ai_generate_embeddings(@text use model Ada2Embeddings)

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
