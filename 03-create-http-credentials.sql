/*
    Store credentials to access the HTTP endpoint
*/ 

if not exists(select * from sys.database_scoped_credentials where [name] = 'https://<OPENAI_URL>.openai.azure.com')
begin
    create database scoped credential [https://dm-open-ai-3.openai.azure.com]
    with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"<OPENAI_API_KEY>"}';
end
go
