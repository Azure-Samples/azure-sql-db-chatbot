declare @text nvarchar(max) = 'what are the best products for organizing a birthday party for a teenager girl?'

declare @payload2 nvarchar(max);
select 
    @payload2 = string_agg(cast(id as varchar(10)) +'=>' + [product_name] + '=>' + [description], char(13) + char(10))
from 
    dbo.similar_items;

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

--select @payload
declare @retval int, @response nvarchar(max);
exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://infoasst-aoai-076mi.openai.azure.com/openai/deployments/gpt-4-32k/chat/completions?api-version=2023-07-01-preview',
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://infoasst-aoai-076mi.openai.azure.com/],
    @timeout = 120,
    @payload = @payload2,
    @response = @response output;

select @response;

drop table if exists #j;
select * into #j from openjson(@response, '$.result.choices') c;

select [key], [value] from openjson(( 
select t.value from #j c cross apply openjson(c.value, '$.message') t
where t.[key] = 'content'
))

