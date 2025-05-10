// src/app.ts
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import userRoutes from './routes/user.routes';
import promBundle from 'express-prom-bundle';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const metricsMiddleware = promBundle({ includeMethod: true });
app.use(metricsMiddleware);

// Health Check
app.get('/health', (_req, res) => {
    res.status(200).send('User Service is running!');
});

// API Routes
app.use('/api/users', userRoutes);

export default app;
