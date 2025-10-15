import json

from kafka import KafkaConsumer


if __name__ == "__main__":
    # Create a Kafka consumer instance
    consumer = KafkaConsumer(
        "subreddit-topic",
        bootstrap_servers=["localhost:9092"],
        # # Specify a consumer group
        # group_id='my-consumer-group',  
        
        # # Start reading from the earliest message
        # auto_offset_reset='earliest',  
        
        # Enable automatic offset committing
        # enable_auto_commit=True,       
        
        value_deserializer=lambda x: json.loads(x.decode('utf-8')) # Deserialize JSON messages
    )

    # Consume messages from the topic
    try:
        for message in consumer:
            print(message.value)
    except KeyboardInterrupt:
        print("Consumer stopped.")
    finally:
        consumer.close()



