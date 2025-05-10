// src/utils/kafkaService.ts
import { Kafka, Producer, logLevel, Admin } from 'kafkajs';
import logger from './logger';
import { UserEvent, USER_EVENTS_TOPIC } from '../types/events';

const kafkaHost = process.env.KAFKA_BROKERS || 'localhost:9092';
const clientId = process.env.KAFKA_CLIENT_ID || 'user-service';

export const kafka = new Kafka({
    clientId,
    brokers: kafkaHost.split(','),
    logLevel: logLevel.ERROR,
    retry: {
        initialRetryTime: 100,
        retries: 3
    }
});

class KafkaService {
    private producer: Producer;
    private admin: Admin;
    private isConnected: boolean = false;

    constructor() {
        this.producer = kafka.producer();
        this.admin = kafka.admin();
    }

    async initialize(): Promise<void> {
        try {
            if (!this.isConnected) {
                await this.producer.connect();
                await this.admin.connect();
                this.isConnected = true;
                logger.info('✅ Kafka producer and admin connected');

                // Ensure the topic exists
                await this.ensureTopicExists(USER_EVENTS_TOPIC);

                this.producer.on('producer.connect', () => {
                    logger.info('Kafka producer connected');
                    this.isConnected = true;
                });

                this.producer.on('producer.disconnect', () => {
                    logger.warn('Kafka producer disconnected');
                    this.isConnected = false;
                });
            }
        } catch (error) {
            logger.error('Failed to connect to Kafka:', error);
            throw error;
        }
    }

    private async ensureTopicExists(topic: string): Promise<void> {
        try {
            const topics = await this.admin.listTopics();
            if (!topics.includes(topic)) {
                await this.admin.createTopics({
                    topics: [
                        {
                            topic,
                            numPartitions: 1,
                            replicationFactor: 1,
                        },
                    ],
                });
                logger.info(`✅ Kafka topic '${topic}' created`);
            } else {
                logger.info(`✅ Kafka topic '${topic}' already exists`);
            }
        } catch (error) {
            logger.error(`❌ Failed to ensure Kafka topic '${topic}' exists:`, error);
            throw error;
        }
    }

    async publishUserEvent(event: UserEvent): Promise<void> {
        try {
            if (!this.isConnected) await this.initialize();

            await this.producer.send({
                topic: USER_EVENTS_TOPIC,
                messages: [
                    {
                        value: JSON.stringify(event),
                        timestamp: Date.now().toString()
                    }
                ]
            });

            logger.info(`✅ Event published to Kafka topic '${USER_EVENTS_TOPIC}': ${event.type}`);
        } catch (err) {
            logger.error(`❌ Failed to publish Kafka event to '${USER_EVENTS_TOPIC}':`, err);
            throw err;
        }
    }

    async disconnect(): Promise<void> {
        try {
            if (this.isConnected) {
                await this.producer.disconnect();
                await this.admin.disconnect();
                logger.info('✅ Kafka producer and admin disconnected');
                this.isConnected = false;
            }
        } catch (err) {
            logger.error('❌ Kafka disconnect error:', err);
        }
    }
}

export const kafkaService = new KafkaService();

// Graceful shutdown
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.on(signal, async () => {
        logger.info(`🔌 Caught ${signal}, disconnecting Kafka...`);
        await kafkaService.disconnect();
        process.exit(0);
    });
}
