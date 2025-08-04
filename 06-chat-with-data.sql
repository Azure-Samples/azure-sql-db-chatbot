declare @request nvarchar(max) = 'anything for a teenager boy passionate about racing cars? he owns an XBOX, he likes to build stuff'

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
                For each returned produce add a short explanation of why the product has been suggested. Put the explanation in parentheis and start with "Thoughts:"
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

select @response;

select json_value(@response, '$.result.choices[0].message.content');


