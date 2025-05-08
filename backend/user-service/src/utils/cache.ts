// utils/cache.ts
import { redisClient } from './redisClient';

export const getCache = async (key: string) => {
  const data = await redisClient.get(key);
  return data ? JSON.parse(data) : null;
};

export const setCache = async (key: string, value: any, ttl = 3600) => {
  await redisClient.setEx(key, ttl, JSON.stringify(value));
};

export const clearCache = async (key: string) => {
  await redisClient.del(key);
};
