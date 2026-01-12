
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_id
from DEV_PLAYGROUND.LARRY.stg_jaffle_shop__orders
where order_id is null



  
  
      
    ) dbt_internal_test