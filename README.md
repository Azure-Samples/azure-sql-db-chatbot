# Azure SQL DB - Retrieval Augmented Generation (RAG) with OpenAI

In this repo you will find a step-by-step guide on how to use Azure SQL Database to do Retrieval Augmented Generation (RAG) using the data you have in Azure SQL and integrating with OpenAI, directly from the Azure SQL database itself. You'll be able to ask queries in natural language and get answers from the OpenAI GPT model, using the data you have in Azure SQL Database.

![Azure SQL DB - Retrieval Augmented Generation (RAG) with OpenAI](./assets/azure-sql-rag.png)

## Step-by-step guide

### Create the Azure SQL Database

Create an Azure SQL Database using the [Azure Portal](https://portal.azure.com/). You can follow the [Quickstart: Create a single database in Azure SQL Database using the Azure portal](https://docs.microsoft.com/azure/azure-sql/database/single-database-create-quickstart?tabs=azure-portal) guide to create a new Azure SQL Database.

Use a client tool like [Azure Data Studio](https://azure.microsoft.com/products/data-studio/) to connect to an Azure SQL database.

### Create Products table

Use the `./01-create-table.sql` to create the `walmart_ecommerce_product_details` table where the Walmart dataset will be imported.

### Download and import the public Walmart US Product dataset, enriched with Vector Embeddings

Download the [Walmart Dataset](https://www.kaggle.com/datasets/mauridb/product-data-from-walmart-usa-with-embeddings), unzip it and upload it (using [Azure Storage Explorer](https://learn.microsoft.com/azure/vs-azure-tools-storage-manage-with-storage-explorer?tabs=windows) for example) to an Azure Blob Storage container.

In the example the unzipped csv file `walmart-product-with-embeddings-dataset-usa.csv` is assumed to be uploaded to a blob container name `playground` and in a folder named `walmart`.

Once the file is uploaded, get the [SAS token](https://learn.microsoft.com/azure/storage/common/storage-sas-overview) to allow Azure SQL database to access it. (From Azure storage Explorer, right click on the `playground` container and than select `Get Shared Access Signature`. Set the expiration date to some time in future and then click on "Create". Copy the generated query string somewhere, for example into the Notepad, as it will be needed later)

and then use the `./02-load-table.sql` to load the csv file into the `walmart_ecommerce_product_details` table.

Make sure to replace the `<STORAGE_ACCOUNT>` and `<SAS_TOKEN>` placeholders with the value correct for your environment:

- `<STORAGE_ACCOUNT>` is the name of the storage account where the CSV file has been uploaded
- `<SAS_TOKEN>` is the Share Access Signature obtained before

Run each section (each section starts with a comment) separately. At the end of the process (will take up to a couple of minutes) you will have all the CSV data imported in the `walmart_ecommerce_product_details` table.

### Create OpenAI models.

Make sure you have an [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) resource created in your Azure subscription. Withi the OpenAI resource create two models:

- `embeddings`, using the `text-embedding-ada-002` model
- `gpt-4`, using the `gpt-4` model

Then get the OpenAI URL Endpoint and API Key as they will be needed in the next step.

### Create HTTP Credentials

Create a new HTTP Credential to access the OpenAI API. Use the `./03-create-credential.sql` to create the HTTP Credential. Replace the `<OPENAI_URL>` and `<OPENAI_API_KEY>` placeholders with the correct values for your environment:

- `<OPENAI_URL>` is the OpenAI URL endpoint from the previous step
- `<OPENAI_API_KEY>` is the OpenAI API Key from the previous step

Run the script to create the HTTP Credential.

The HTTP Crential will be safely stored in the Azure SQL Database and will be used to access the OpenAI API without exposing the API Key.

### Store vectors in a columnstore

To allow effienct searching of the vectors, create a columnstore index on the `embedding` column. Use the `./04-extract-vectors-into-columnstore.sql` to create the columnstore index. More details on this tecnique are explained here: [Vector Similarity Search with Azure SQL database and OpenAI](https://devblogs.microsoft.com/azure-sql/vector-similarity-search-with-azure-sql-database-and-openai/)

### Transform the search text into a vector using OpenAI

Now that the data is ready, you can use the OpenAI API to transform the search text into a vector. Use the `./05-get-search-vector.sql` to transform the search text into a vector. Replace the `<OPENAI_URL>` with the OpenAI URL endpoint used before and run the script to transform the search text into a vector.

### Find products related to the search text 

In order to send to GPT only the relevant products, so that it can provide better answers, you can use the vector similarity search to find the most similar products to the search text. Use the `./06-get-similar-item.sql` to find the most similar products to the search text. Run the script so that the most similar products to the search text are found.

### Use GPT to ask questions about the products

Now that the most similar products to the search text are found, you can use the GPT model to ask questions about the products. Use the `./07-chat-with-data.sql` to ask questions about the products. Azure SQL will connect to OpenAI via REST call, so replace the `<OPENAI_URL>` with the OpenAI URL endpoint used before. 

Note the how the prompt is telling the AI model how to behave and how it should expect the data to be structured. 

```
You as a system assistant who helps users find ideas to organize birthday parties using the products that are provided to you.
Products will be provided in an assistant message in the format of "Id=>Product=>Description". You can use this information to help you answer the user's question.
```

The prompt also clearly specifies what results are expected from the AI model. 

```
You answer needs to be a json object with the following format.
{
    "answer": // the answer to the question, add a source reference to the end of each sentence. Source referece is the product Id.
    "products": // a comma-separated list of product ids that you used to come up with the answer.
    "thoughts": // brief thoughts on how you came up with the answer, e.g. what sources you used, what you thought about, etc.
}
```

Run the script to ask questions about the products. Here's an example of a question and the answer from the AI model:

```
What are some good products to organize a birthday party for teenager boy?
```

and the asnwser (restructed from JSON format) is

```
Answer:
For a teenager boy's birthday party, some good products to consider might include the '2018 Megaloon Set' (ID: 1329) for decoration. This set includes large Mylar balloons that can be filled with helium. You can also consider the 'Red Plastic Party Tablecloth' (ID: 27782) for an easy and fuss-free table setting. The 'Birthdays For Him Luxury Topper Set, A4' (ID: 20133) would be a great addition for cake decoration. If the party is going to be held at night, the 'Stargazer Laser Light Show Projector' (ID: 11767) would be a fun way to create a festive atmosphere. Do not forget to send 'Teenage Mutant Ninja Turtles Thank-You Notes' (ID: 25453) to the guests after the party (source: ID: 25453).

Thoughts:
I selected products that would cater to a teenager's interests and that would help create a fun and festive atmosphere for the party. The balloons and laser light show projector add a fun element, while the tablecloth and cake topper set help with the practical aspects of party planning. The thank-you notes are a thoughtful touch for after the party.
```

Impressive! Everything happened on your own data, and right in the Azure SQL Database.

## Unified script

There is no need to keep all the steps separated as done in the step-by-step guide. The steps can be combined into a single script and run in a single go. The script with unified steps is available in the `./08-all-togehter.sql` file.

## Conclusion

This project demonstrates how to use Azure SQL Database to do Retrieval Augmented Generation (RAG) using the data you have in Azure SQL and integrating with OpenAI, directly from the Azure SQL database itself. With this approach you can easily create new applications and securely handle your data, or improve existing applications by enabling them to use the power of OpenAI's GPT.
