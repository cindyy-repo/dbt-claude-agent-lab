with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        id as order_id,
        user_id as customer_id,
        order_date as ordered_at,
        status

    from source

)

select * from renamed
