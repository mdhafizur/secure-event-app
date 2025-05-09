// src/app.ts
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import userRoutes from './routes/user.routes';
import promBundle from 'express-prom-bundle';
import logger from './utils/logger';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Replace console.log with logger in middleware
app.use((req, res, next) => {
    logger.info(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
    next();
});

const metricsMiddleware = promBundle({ includeMethod: true });
app.use(metricsMiddleware);

// Health Check
app.get('/health', (_req, res) => {
    res.status(200).send('User Service is running!');
});

// API Routes
app.use('/api/users', userRoutes);

export default app;
