with orders as (

    select * from {{ ref('stg_jaffle_shop__orders') }}

),

customer_orders as (

    select
        customer_id,
        min(ordered_at) as first_ordered_at,
        max(ordered_at) as most_recent_ordered_at,
        count(order_id) as number_of_orders

    from orders

    group by customer_id

)

select * from customer_orders
