/*
    Store credentials to access the HTTP endpoint
*/ 

if not exists(select * from sys.database_scoped_credentials where [name] = 'https://infoasst-aoai-076mi.openai.azure.com/')
begin
    create database scoped credential [https://infoasst-aoai-076mi.openai.azure.com/]
    with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"6e3c3b174c754b65824d473e836a45a1"}';
end
go
