create or alter procedure [dbo].[get_embedding]
@inputText nvarchar(max),
@embedding vector(1536) output,
@error nvarchar(max) = null output
as
declare @retval int;
declare @payload nvarchar(max) = json_object('input': @inputText);
declare @response nvarchar(max)
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '<OPENAI_URL>/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://<OPENAI_URL>.openai.azure.com],
        @payload = @payload,
        @response = @response output
        with result sets none;
end try
begin catch
    set @error = json_object('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    return -1
end catch

if @retval != 0 begin
    set @error = json_object('error':'Embedding:OpenAI', 'error_code':@retval, 'error_message':@response)
    return @retval
end

declare @re nvarchar(max) = json_query(@response, '$.result.data[0].embedding')
set @embedding = cast(@re as vector(1536));

return @retval
go

