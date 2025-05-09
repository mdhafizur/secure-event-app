// src/utils/redisClient.ts
import { createClient } from 'redis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

export const redisClient = createClient({ url: redisUrl });

redisClient.on('error', (err) => {
    console.error('Redis Error:', err);
});

export const connectRedis = async (): Promise<void> => {
    if (!redisClient.isOpen) {
        await redisClient.connect();
    }

    const pong = await redisClient.ping();
    if (pong !== 'PONG') {
        throw new Error('Redis connection failed');
    }

    console.log('✅ Redis connected');
};
