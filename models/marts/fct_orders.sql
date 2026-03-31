with orders as (

    select * from {{ ref('stg_jaffle_shop__orders') }}

),

order_payments as (

    select * from {{ ref('int_order_payments') }}

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.ordered_at,
        orders.status,
        order_payments.credit_card_amount,
        order_payments.coupon_amount,
        order_payments.bank_transfer_amount,
        order_payments.gift_card_amount,
        order_payments.total_amount as amount

    from orders

    left join order_payments on orders.order_id = order_payments.order_id

)

select * from final
