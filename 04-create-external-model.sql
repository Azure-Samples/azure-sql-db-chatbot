/*
    Create external model to point to existing embedding model
*/ 

if not exists(select * from sys.external_models where [name] = 'Ada2Embeddings')
begin
    create external model [Ada2Embeddings]
	with ( 
		location = 'https://<OPENAI_URL>.openai.azure.com/openai/deployments/<MODEL_DEPLOYMENT_NAME>/embeddings?api-version=2023-05-15',
		credential = [https://<OPENAI_URL>.openai.azure.com],
		api_format = 'Azure OpenAI',
		model_type = embeddings,
		model = 'embeddings'
	);
end
go

select * from sys.external_models where [name] = 'Ada2Embeddings'
go
