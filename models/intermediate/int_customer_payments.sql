with payments as (

    select * from {{ ref('stg_jaffle_shop__payments') }}

),

orders as (

    select * from {{ ref('stg_jaffle_shop__orders') }}

),

customer_payments as (

    select
        orders.customer_id,
        sum(payments.amount) as total_amount

    from payments

    left join orders on payments.order_id = orders.order_id

    group by orders.customer_id

)

select * from customer_payments
