import { Request, Response } from 'express';
import { validationResult } from 'express-validator';
import createHttpError from 'http-errors';
import User, { IUser } from '../models/User';
import { redisClient } from '../utils/redisClient';
import { kafkaService } from '../utils/kafkaClient';
import { UserEvent } from '../types/events';
import logger from '../utils/logger';

// Create User
export const createUser = async (req: Request, res: Response): Promise<void> => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    throw createHttpError(422, { message: 'Validation failed', errors: errors.array() });
  }

  const { username, email, password, role } = req.body;

  const existing = await User.findOne({ email });
  if (existing) throw createHttpError(409, 'Email already exists');

  const user: IUser = await User.create({ username, email, password, role });
  
  // Publish user created event
  const event: UserEvent = {
    type: 'USER_CREATED',
    data: {
      userId: user._id.toString(),
      username: user.username,
      email: user.email,
      role: user.role,
      timestamp: new Date().toISOString()
    }
  };
  
  kafkaService.publishUserEvent(event).catch(err => logger.warn('Kafka fail:', err));
  res.status(201).json(user);
};

// Get All Users
export const getUsers = async (_req: Request, res: Response): Promise<void> => {
  const users = await User.find().select('-password');
  res.status(200).json(users);
};

// Get User By ID (with Redis caching)
export const getUserById = async (req: Request, res: Response): Promise<void> => {
  const userId = req.params.id;
  const cacheKey = `user:${userId}`;

  const cached = await redisClient.get(cacheKey);
  if (cached) {
    logger.info('Serving from Redis cache');
    res.status(200).json(JSON.parse(cached));
    return;
  }

  const user = await User.findById(userId).select('-password');
  if (!user) {
    logger.warn('User not found');
    throw createHttpError(404, 'User not found');
  }

  redisClient.setEx(cacheKey, 3600, JSON.stringify(user)).catch(err => logger.warn('Redis fail:', err));
  res.status(200).json(user);
};

// Delete User
export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  const user: IUser | null = await User.findById(req.params.id);
  if (!user) throw createHttpError(404, 'User not found');

  await User.findByIdAndDelete(req.params.id);
  
  // Publish user deleted event
  const event: UserEvent = {
    type: 'USER_DELETED',
    data: {
      userId: user._id.toString(),
      username: user.username,
      email: user.email,
      timestamp: new Date().toISOString()
    }
  };
  
  kafkaService.publishUserEvent(event).catch(err => logger.warn('Kafka fail:', err));
  res.status(200).json({ message: 'User deleted successfully' });
};
