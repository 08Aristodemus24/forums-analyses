
    
    

select
    payment_id as unique_field,
    count(*) as n_records

from DEV_PLAYGROUND.LARRY.stg_stripe__payments
where payment_id is not null
group by payment_id
having count(*) > 1


