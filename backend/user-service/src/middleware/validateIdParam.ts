// src/middleware/validateIdParam.ts
import { Request, Response, NextFunction } from 'express';
import mongoose from 'mongoose';

export const validateIdParam = (req: Request, res: Response, next: NextFunction): void => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    res.status(400).json({ message: 'Invalid ID format' });
    return;
  }
  next();
};
