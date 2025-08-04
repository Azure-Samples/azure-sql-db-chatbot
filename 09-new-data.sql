/*
    Add more data. Run the sample from file 04 again to see how the answer changes
*/
delete from [dbo].[walmart_ecommerce_product_details] where id >= 90000;
insert into [dbo].[walmart_ecommerce_product_details]    
values
(
    90000, 'test-product-1', sysdatetime(), 'https://www.xbox.com/en-US/games/store/f1-25/9NWPW7F19FS5', 'F1® 25 - XBOX', 'This Story is Yours. Leave your mark on the world of racing in F1® 25, the official video game of the 2025 FIA Formula One World Championship™',
    null, null, 'EA', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null    
),
(
    90001, 'test-product-2', sysdatetime(), 'https://store.playstation.com/en-us/product/UP0006-PPSA24662_00-F125DELUXEDITION', 'F1® 25 - PS5', 'This Story is Yours. Leave your mark on the world of racing in F1® 25, the official video game of the 2025 FIA Formula One World Championship™',
    null, null, 'EA', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null    
),
(
    90002, 'test-product-3', sysdatetime(), 'https://www.xbox.com/en-us/handhelds/rog-xbox-ally', 'ROG Xbox Ally', 'Handheld freedom for everyone. Power of Xbox. Freedom of Windows. Craftmanship of ROG. The portable console you always want to bring with you, wherever you go, wherever you are.',
    null, null, 'XBOX', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null   
)
go

select * from [dbo].[walmart_ecommerce_product_details] where id >= 90000
go

-- Quick and dirty loop to update embeddings;
declare @retval int;
declare @id int, @v vector(1536), @p nvarchar(max), @e nvarchar(max)
while (1=1) 
begin
    select @id = null, @v = null, @p = null;

    select top(1) 
        @id = id,
        @p = product_name || ' ' || [description] 
    from 
        [dbo].[walmart_ecommerce_product_details] 
    where 
        [embedding] is null;

    if (@id is null) break

    exec @retval = [dbo].[get_embedding] @p, @v output, @e output;
    if (@retval != 0) begin
        select @e
        break
    end

    update [dbo].[walmart_ecommerce_product_details] 
    set embedding = @v
    where id = @id
end

select * from [dbo].[walmart_ecommerce_product_details] where id >= 90000
go