declare @text nvarchar(max) = 'What are some good products to organize a birthday party for teenager boy?'
declare @top int = 50
declare @min_similarity decimal(19,16) = 0.75

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

-- Call to OpenAI to get the embedding of the search text
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '<OPENAI_URL>/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [<OPENAI_URL>],
        @payload = @payload,
        @response = @response output;
end try
begin catch
    select 
        'SQL' as error_source, 
        error_number() as error_code,
        error_message() as error_message
    return;
end catch

if (@retval != 0) begin
    select 
        'OPENAI' as error_source, 
        json_value(@response, '$.result.error.code') as error_code,
        json_value(@response, '$.result.error.message') as error_message,
        @response as error_response
    return;
end;

drop table if exists #r;
create table #r (response nvarchar(max));
insert into #r (response) values (@response);

-- Similarity Search
declare @qv varbinary(8000) = (
	select top(1)
		json_array_to_vector(json_query(response, '$.result.data[0].embedding')) as query_vector
	from 
		#r
)
drop table if exists #s;
select top(@top)    
    vector_distance('cosine', @qv, p.embedding) as distance,
    p.id,
    p.[Product_Name],
    p.[Description],
    p.Category
into
    #s
from
    dbo.[walmart_ecommerce_product_details] p 
where
    vector_distance('cosine', @qv, embedding) <= 1 - @min_similarity
order by    
    distance;
;

declare @payload2 nvarchar(max);
select 
    @payload2 = string_agg(cast(id as varchar(10)) +'=>' + [Product_Name] + '=>' + [Description], char(13) + char(10))
from 
    #s;

set @payload2 = 
json_object(
    'messages': json_array(
            json_object(
                'role':'system',
                'content':'
                    You as a system assistant who helps users find ideas to organize birthday parties using the products that are provided to you.
                    Products will be provided in an assistant message in the format of "Id=>Product=>Description". You can use this information to help you answer the user''s question.
                '
            ),
            json_object(
                'role':'user',
                'content': '## Source ##
                    ' + @payload2 + '
                    ## End ##

                    You answer needs to be a json object with the following format.
                    {
                        "answer": // the answer to the question, add a source reference to the end of each sentence. Source referece is the product Id.
                        "products": // a comma-separated list of product ids that you used to come up with the answer.
                        "thoughts": // brief thoughts on how you came up with the answer, e.g. what sources you used, what you thought about, etc.
                    }'
            ),
            json_object(
                'role':'user',
                'content': + @text
            )
    ),
    'max_tokens': 800,
    'temperature': 0.7,
    'frequency_penalty': 0,
    'presence_penalty': 0,
    'top_p': 0.95,
    'stop': null
);

exec @retval = sp_invoke_external_rest_endpoint
    @url = '<OPENAI_URL>/openai/deployments/gpt-4-32k/chat/completions?api-version=2023-07-01-preview',
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [<OPENAI_URL>],
    @timeout = 120,
    @payload = @payload2,
    @response = @response output;

drop table if exists #j;
select * into #j from openjson(@response, '$.result.choices') c;

select [key], [value] from openjson(( 
select t.value from #j c cross apply openjson(c.value, '$.message') t
where t.[key] = 'content'
))

