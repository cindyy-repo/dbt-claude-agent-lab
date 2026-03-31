with

stg_jaffle_shop__orders as (

    select * from {{ ref('stg_jaffle_shop__orders') }}

),

int_order_payments as (

    select * from {{ ref('int_order_payments') }}

),

orders_with_payments as (

    select
        stg_jaffle_shop__orders.order_id,
        stg_jaffle_shop__orders.ordered_at,
        int_order_payments.credit_card_amount,
        int_order_payments.coupon_amount,
        int_order_payments.bank_transfer_amount,
        int_order_payments.gift_card_amount

    from stg_jaffle_shop__orders

    inner join int_order_payments
        on stg_jaffle_shop__orders.order_id = int_order_payments.order_id

),

order_payment_methods as (

    select date_trunc('month', ordered_at) as month_start, 'credit_card'   as payment_method, credit_card_amount   as revenue from orders_with_payments
    union all
    select date_trunc('month', ordered_at),                'coupon',                          coupon_amount        as revenue from orders_with_payments
    union all
    select date_trunc('month', ordered_at),                'bank_transfer',                   bank_transfer_amount as revenue from orders_with_payments
    union all
    select date_trunc('month', ordered_at),                'gift_card',                       gift_card_amount     as revenue from orders_with_payments

),

monthly_revenue as (

    select
        month_start,
        payment_method,
        sum(revenue) as revenue

    from order_payment_methods

    group by month_start, payment_method

),

final as (

    select * from monthly_revenue

)

select * from final
