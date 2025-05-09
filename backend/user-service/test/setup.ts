import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';

import User from '../src/models/User';
import { redisClient } from '../src/utils/redisClient';

let mongo: MongoMemoryServer;

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
});

afterEach(async () => {
  const collections = await mongoose.connection.db.collections();
  for (const collection of collections) {
    await collection.deleteMany({});
  }
});

afterAll(async () => {
  await mongoose.connection.close();
  if (mongo) await mongo.stop();

  if (redisClient.isOpen) {
    await redisClient.quit();
  }
});
