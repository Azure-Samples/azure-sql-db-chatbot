declare @request nvarchar(max) = 'what are the best products for organizing a birthday party for a teenager girl?'

declare @products json =
(
    select 
        json_arrayagg(
            json_object(
                'id': [id],
                'name': [product_name],
                'description' : [description]
            )
        )
    from 
        dbo.similar_items
)

declare @prompt nvarchar(max) = json_object(
    'messages': json_array(
        json_object(
            'role':'system',
            'content':'
                You as a system assistant who helps users find the best products available in the catalog to satesfy the requested ask.
                Products are provided in an assitant message using a JSON Array with the following format: [{id, name, description}].                 
                Use only the provided products to help you answer the question.        
                Use only the information available in the provided JSON to answer the question.
                Return the top ten products that best answer the question.
                Make sure to use details, notes, and description that are provided in each product are used only with that product.                
                If the question cannot be answered by the provided samples, don''t return any result.
                If asked question is about topics you don''t know, don''t return any result.
                If no products are provided, don''t return any result.                
            '
        ),
        json_object(
            'role':'assistant',
            'content': 'The available products are the following:'
            ),
        json_object(
            'role':'assistant',
            'content': coalesce(cast(@products as nvarchar(max)), '')
            ),
        json_object(
            'role':'user',
            'content': @request
        )
    ),    
    'temperature': 0.2,
    'frequency_penalty': 0,
    'presence_penalty': 0,    
    'stop': null
);


declare @js nvarchar(max) = N'{
    "type": "json_schema",
    "json_schema": {
        "name": "products",
        "strict": true,
        "schema": {
            "type": "object",
            "properties": {
                "products": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "result_position": {
                                "type": "number"
                            },
                            "id": {
                                "type": "number"
                            },
                            "description": {
                                "type": "string",
                                "description": "a brief and summarized description of the product, no more than ten words"
                            },                            
                            "thoughts": {
                                "type": "string",
                                "description": "explanation of why the product has been chosen"
                            }
                        },
                        "required": [
                            "result_position",
                            "id",                            
                            "description",                            
                            "thoughts"                            
                        ],
                        "additionalProperties": false
                    }
                }
            },
            "required": ["products"],
            "additionalProperties": false
        }        
    }        
}'

set @prompt = json_modify(@prompt, '$.response_format', json_query(@js))
---select @p

--select @payload
declare @retval int, @response nvarchar(max);
exec @retval = sp_invoke_external_rest_endpoint
    @url = '<OPENAI_URL>/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview',
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [<OPENAI_URL>],
    @timeout = 120,
    @payload = @prompt,
    @response = @response output
    with result sets none;

drop table if exists #r;
create table #r (response nvarchar(max));
insert into #r values (@response);
go

-- Get the structured results
select 
    sr.* 
from 
    #r
cross apply
    openjson(response, '$.result.choices[0].message') with (
        content nvarchar(max) '$.content'
    ) m
cross apply
    openjson(m.content, '$.products') with (
        result_position int,
        id int,        
        [description] nvarchar(max),
        thoughts nvarchar(max)
    ) as sr

-- Join back to original products table
select 
    p.[id], 
    p.[product_name], 
    p.[description],
    sr.[description] as genai_short_description,
    p.[category],
    sr.thoughts
from 
    openjson(@response, '$.result.choices[0].message') with (
        content nvarchar(max) '$.content'
    ) m
cross apply
    openjson(m.content, '$.products') with (
        result_position int,
        id int,        
        [description] nvarchar(max),
        thoughts nvarchar(max)
    ) as sr
inner join
    dbo.[walmart_ecommerce_product_details] p on sr.id = p.id
order by
    sr.result_position