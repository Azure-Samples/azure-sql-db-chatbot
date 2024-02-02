/*
    Store credentials to access the HTTP endpoint
*/ 

if not exists(select * from sys.database_scoped_credentials where [name] = '<OPENAI_URL>')
begin
    create database scoped credential [<OPENAI_URL>]
    with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"<OPENAI_API_KEY>"}';
end
go
