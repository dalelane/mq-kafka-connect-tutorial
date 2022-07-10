package com.ibm.clientengineering.kafka.samples;

public class Config {

    public static final String TOPIC = "MQ.COMMANDS";

    public static final String BOOTSTRAP = "PLACEHOLDERBOOTSTRAP";
    public static final String CLIENT = "audit-app";
    public static final String GROUP = "audit";

    public static final String TRUSTSTORE = "./ca.p12";
    public static final String TRUSTSTORE_PASSWORD = "PLACEHOLDERTRUSTSTOREPASSWORD";

    public static final String SASL_MECHANISM = "SCRAM-SHA-512";

    public static final String USERNAME = "audit-app";
    public static final String PASSWORD = "PLACEHOLDERAPPPASSWORD";

}
