// src/server.ts
import express from 'express';
import mongoose from 'mongoose';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import User from './models/User';
import app from './app';

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
                        name: { type: 'string' },
                        email: { type: 'string' },
                        createdAt: { type: 'string', format: 'date-time' },
                        updatedAt: { type: 'string', format: 'date-time' }
                    }
                },
                UserInput: {
                    type: 'object',
                    required: ['name', 'email'],
                    properties: {
                        name: { type: 'string' },
                        email: { type: 'string', format: 'email' }
                    }
                }
            }
        },
    },
    apis: ['./src/routes/*.ts']
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

mongoose.connect(MONGO_URI)
    .then(async () => {
        console.log('MongoDB connected');

        await User.createCollection().catch((err: unknown) => {
            if ((err as any)?.codeName !== 'NamespaceExists') {
                console.error('Error creating User collection:', err);
            }
        });

        app.listen(PORT, () => console.log(`User Service running on port ${PORT}`));
    })
    .catch((err: unknown) => console.error('MongoDB connection error:', err));
