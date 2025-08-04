/*
    Store credentials to access the HTTP endpoint
*/ 

if not exists(select * from sys.database_scoped_credentials where [name] = '<OPENAI_URL>')
begin
    create database scoped credential [<OPENAI_URL>]
    with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"<OPENAI_API_KEY>"}';
end
go

/*
    Even better, use Managed Identity if you can, as explained here:
    https://devblogs.microsoft.com/azure-sql/go-passwordless-when-calling-azure-openai-from-azure-sql-using-managed-identities/

if not exists(select * from sys.database_scoped_credentials where [name] = '<OPENAI_URL>')
begin
    create database scoped credential [<OPENAI_URL>]
    with identity = 'Managed Identity', secret = '{"resourceid":"https://cognitiveservices.azure.com"}';
end
go

*/

select * from sys.database_scoped_credentials where [name] = '<OPENAI_URL>'
go
