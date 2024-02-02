/*
    Extract vectors from the JSON column into a columnstore table
*/
drop table if exists dbo.[walmart_ecommerce_product_details_embeddings_vectors];
go

select 
    p.id,
    cast(e.[key] as int) as [vector_value_id],
    cast(e.[value] as float) as [vector_value]
into
    dbo.[walmart_ecommerce_product_details_embeddings_vectors]
from 
    dbo.[walmart_ecommerce_product_details] p
cross apply 
    openjson(embedding) e
go

create clustered columnstore index ixcc on dbo.[walmart_ecommerce_product_details_embeddings_vectors]
order (id, vector_value_id)
--with (maxdop = 1)
go