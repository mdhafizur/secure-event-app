// src/server.ts
import mongoose from 'mongoose';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import User from './models/User';
import app from './app';
import logger from './utils/logger';
import { connectRedis } from './utils/redisClient';
import { kafkaService } from './utils/kafkaClient';

const PORT = parseInt(process.env.PORT || '3000', 10);
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/userdb';

const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'User Service API',
            version: '1.0.0',
            description: 'API documentation for the User Service'
        },
        servers: [
            {
                url: '/api',
                description: 'Base path for all APIs'
            }
        ],
        components: {
            schemas: {
                User: {
                    type: 'object',
                    properties: {
                        _id: { type: 'string' },
                        username: { type: 'string' },
                        email: { type: 'string' },
                        createdAt: { type: 'string', format: 'date-time' },
                        updatedAt: { type: 'string', format: 'date-time' }
                    }
                },
                UserInput: {
                    type: 'object',
                    required: ['username', 'name', 'email', 'role', 'password'],
                    properties: {
                        username: { type: 'string' },
                        email: { type: 'string', format: 'email' },
                        role: {
                            type: 'string',
                            enum: ['admin', 'user', 'moderator'],
                            description: 'Role of the user'
                        },
                        password: { type: 'string', format: 'password' }
                    }
                }
            }
        },
    },
    apis: ['./src/routes/*.ts']
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

mongoose.connect(MONGO_URI, {
    maxPoolSize: 20,               // Max concurrent socket connections (increase for high load)
    minPoolSize: 2,                // Minimum persistent sockets
    serverSelectionTimeoutMS: 5000, // Time to wait for MongoDB server selection
    socketTimeoutMS: 45000,        // Time before a socket times out if idle
    heartbeatFrequencyMS: 10000,   // How often to ping MongoDB for connection health
})
    .then(async () => {
        logger.info('MongoDB connected');

        try {
            // Initialize Kafka
            await kafkaService.initialize();

            // Initialize Redis
            await connectRedis();

            // Create User collection if not exists
            await User.createCollection().catch((err: unknown) => {
                if ((err as any)?.codeName !== 'NamespaceExists') {
                    logger.error('Error creating User collection:', err);
                }
            });

            app.listen(PORT, () => logger.info(`User Service running on port ${PORT}`));
        } catch (error) {
            logger.error('Service initialization failed:', error);
            process.exit(1);
        }
    })
    .catch((err: unknown) => {
        logger.error('MongoDB connection error:', err);
        process.exit(1);
    });
