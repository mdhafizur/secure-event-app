import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import User from '../src/models/User';

let mongo: MongoMemoryServer;

beforeAll(async () => {
  mongo = await MongoMemoryServer.create();
  const uri = mongo.getUri();
  await mongoose.connect(uri);

  // Ensure User collection is created
  await User.createCollection();
});

afterEach(async () => {
  const db = mongoose.connection.db;
  if (!db) {
    throw new Error("Database connection is not established.");
  }
  const collections = await db.collections();
  for (let collection of collections) {
    await collection.deleteMany({});
  }
});

afterAll(async () => {
  await mongoose.connection.close();
  if (mongo) await mongo.stop();
});
