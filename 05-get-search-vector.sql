/*
    Transform the search text into a vector using OpenAI's embeddings model
*/
declare @text nvarchar(max) = 'what are the best products for organizing a birthday party for a teenager girl?'

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

-- Call to OpenAI to get the embedding of the search text
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = 'https://<OPENAI_URL>.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<OPENAI_URL>.openai.azure.com],
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

drop table if exists dbo.http_response;
create table dbo.http_response (response nvarchar(max));
insert into dbo.http_response (response) values (@response);
select @response;
