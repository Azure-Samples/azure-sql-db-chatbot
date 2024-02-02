-- Take a look at the vector
select 
    cast([key] as int) as [vector_value_id],
    cast([value] as float) as [vector_value]
from 
    dbo.http_response
cross apply
    openjson(json_query(response, '$.result.data[0].embedding'))
go

-- Similarity Search
drop table if exists dbo.similar_items
declare @top int = 50
declare @min_similarity decimal(19,16) = 0.75
drop table if exists ##s;
with cteVector as
(
    select 
        cast([key] as int) as [vector_value_id],
        cast([value] as float) as [vector_value]
    from 
        dbo.http_response
    cross apply
        openjson(json_query(response, '$.result.data[0].embedding'))
),
cteSimilar as
(
    select 
        v2.[id],         
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_similarity
    from 
        cteVector v1
    inner join 
        dbo.[walmart_ecommerce_product_details_embeddings_vectors] v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.[id]
)
select top(@top)    
    p.id,
    r.cosine_similarity,
    p.[product_name],
    p.[description],
    p.category
into
    dbo.similar_items
from 
    cteSimilar r
inner join
    dbo.[walmart_ecommerce_product_details] p on r.[id] = p.[id]
where
    cosine_similarity >= @min_similarity
order by    
    r.cosine_similarity desc;
;

select * from 
    dbo.similar_items
order by    
    cosine_similarity desc;
go
