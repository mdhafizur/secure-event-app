import { Request, Response } from 'express';
import { validationResult } from 'express-validator';
import createHttpError from 'http-errors';
import User from '../models/User';
import { redisClient } from '../utils/redisClient';

// Create User
export const createUser = async (req: Request, res: Response): Promise<void> => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    throw createHttpError(422, { message: 'Validation failed', errors: errors.array() });
  }

  const { username, email, password, role } = req.body;

  const existing = await User.findOne({ email });
  if (existing) throw createHttpError(409, 'Email already exists');

  const user = await User.create({ username, email, password, role });
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
    console.log('Serving from Redis cache');
    res.status(200).json(JSON.parse(cached));
    return;
  }

  const user = await User.findById(userId).select('-password');
  if (!user) throw createHttpError(404, 'User not found');

  await redisClient.setEx(cacheKey, 3600, JSON.stringify(user));
  res.status(200).json(user);
};

// Delete User
export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  const result = await User.findByIdAndDelete(req.params.id);
  if (!result) throw createHttpError(404, 'User not found');
  res.status(200).json({ message: 'User deleted successfully' });
};
