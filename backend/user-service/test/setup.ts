import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import User from '../src/models/User';
import { redisClient } from '../src/utils/redisClient';
import { kafkaService } from '../src/utils/kafkaClient';
import logger from '../src/utils/logger';

let mongo: MongoMemoryServer;

// Mock Kafka service
jest.mock('../src/utils/kafkaClient', () => ({
  kafkaService: {
    initialize: jest.fn().mockResolvedValue(undefined),
    publishUserEvent: jest.fn().mockResolvedValue(undefined),
    disconnect: jest.fn().mockResolvedValue(undefined),
  },
}));

beforeAll(async () => {
  // MongoDB Setup
  mongo = await MongoMemoryServer.create();
  const uri = mongo.getUri();
  await mongoose.connect(uri);
  await User.createCollection();

  // Redis Setup
  if (!redisClient.isOpen) {
    await redisClient.connect();
  }

  const pong = await redisClient.ping();
  if (pong !== 'PONG') {
    throw new Error('Redis connection failed');
  }

  // Mock Kafka initialization
  try {
    await kafkaService.initialize();
    logger.info('Kafka mock initialized');
  } catch (error) {
    logger.error('Failed to initialize Kafka mock:', error);
    throw error;
  }
});

afterEach(async () => {
  const collections = await mongoose.connection.db.collections();
  for (const collection of collections) {
    await collection.deleteMany({});
  }
  
  // Clear all mocks
  jest.clearAllMocks();
});

afterAll(async () => {
  // Cleanup MongoDB
  await mongoose.connection.close();
  if (mongo) await mongo.stop();

  // Cleanup Redis
  if (redisClient.isOpen) {
    await redisClient.quit();
  }

  // Cleanup Kafka
  await kafkaService.disconnect();
});
