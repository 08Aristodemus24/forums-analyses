{% macro get_sentiment_label(column_name) %}
    CASE
        WHEN {{ column_name }} < -0.5 THEN 'Highly Negative'
        WHEN {{ column_name }} < -0.5 THEN 'Negative'
        WHEN {{ column_name }} < -0.5 THEN 'Neutral'
        WHEN {{ column_name }} < -0.5 THEN 'Positive'
        ELSE 'Highly Positive'
    END
{% endmacro %}