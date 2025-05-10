// utils/cache.ts
import logger from './logger';
import { redisClient } from './redisClient';

export const getCache = async (key: string) => {
  const data = await redisClient.get(key);
  return data ? JSON.parse(data) : null;
};

export const setCache = async (key: string, value: any, ttl = 3600) => {
  redisClient.setEx(key, ttl, JSON.stringify(value)).catch(err => logger.warn('Redis fail:', err));
};

export const clearCache = async (key: string) => {
  await redisClient.del(key);
};
