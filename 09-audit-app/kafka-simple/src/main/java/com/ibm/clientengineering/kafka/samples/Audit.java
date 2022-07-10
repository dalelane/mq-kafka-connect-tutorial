package com.ibm.clientengineering.kafka.samples;

import java.time.Duration;
import java.util.Collections;
import java.util.Date;
import java.util.Properties;

import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.security.auth.SecurityProtocol;
import org.apache.kafka.common.serialization.StringDeserializer;

public class Audit {

    public static void main(String[] args) {

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, Config.BOOTSTRAP);
        props.put(ConsumerConfig.CLIENT_ID_CONFIG, Config.CLIENT);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, Config.GROUP);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");

        props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, SecurityProtocol.SASL_SSL.name);

        props.put(SaslConfigs.SASL_MECHANISM, Config.SASL_MECHANISM);
        props.put(SaslConfigs.SASL_JAAS_CONFIG, "org.apache.kafka.common.security.scram.ScramLoginModule required " +
                "username=\"" + Config.USERNAME + "\" " +
                "password=\"" + Config.PASSWORD + "\";");

        props.put(SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, Config.TRUSTSTORE);
        props.put(SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, Config.TRUSTSTORE_PASSWORD);
        props.put(SslConfigs.SSL_TRUSTSTORE_TYPE_CONFIG, "PKCS12");
        props.put(SslConfigs.SSL_ENDPOINT_IDENTIFICATION_ALGORITHM_CONFIG, "");


        // create a consumer that can read messages from the topic
        KafkaConsumer<String, String> consumer = new KafkaConsumer<String, String>(props);

        // subscribe to the MQ commands topic
        consumer.subscribe(Collections.singletonList(Config.TOPIC));

        // wait until the client is assigned
        while (consumer.assignment().isEmpty()) {
            consumer.poll(Duration.ofMillis(0));
        }

        // rewind to the first message on the topic
        consumer.seekToBeginning(consumer.assignment());

        // read all of the messages on the topic
        ConsumerRecords<String, String> messages;
        while ((messages = consumer.poll(Duration.ofSeconds(2))).isEmpty() == false) {
            for (ConsumerRecord<String, String> message : messages) {
                Date timestamp = new Date(message.timestamp());
                String contents = message.value();

                System.out.println(timestamp.toString() + " : " + contents);
            }
        }

        // no messages remaining - close the consumer
        consumer.close();
    }
}
