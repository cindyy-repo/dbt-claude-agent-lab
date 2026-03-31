with customers as (

    select * from {{ ref('stg_jaffle_shop__customers') }}

),

customer_orders as (

    select * from {{ ref('int_customer_orders') }}

),

customer_payments as (

    select * from {{ ref('int_customer_payments') }}

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_ordered_at,
        customer_orders.most_recent_ordered_at,
        customer_orders.number_of_orders,
        customer_payments.total_amount as customer_lifetime_value

    from customers

    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

    left join customer_payments
        on customers.customer_id = customer_payments.customer_id

)

select * from final
