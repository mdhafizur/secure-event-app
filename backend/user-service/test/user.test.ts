import request from 'supertest';
import app from '../src/app';
import User from '../src/models/User';

jest.setTimeout(30000); // Increase timeout to 30 seconds

describe('User API', () => {
  it('should create a new user', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({
        username: 'hafizur',
        email: 'hafiz@example.com',
        password: 'secret123',
        role: 'admin'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.username).toBe('hafizur');
    expect(res.body.email).toBe('hafiz@example.com');
  });

  it('should fail to create a user with duplicate email', async () => {
    await User.create({
      username: 'john',
      email: 'john@example.com',
      password: '123456',
      role: 'user'
    });

    const res = await request(app)
      .post('/api/users')
      .send({
        username: 'doe',
        email: 'john@example.com',
        password: 'abcdef',
        role: 'admin'
      });

    expect(res.statusCode).toBe(409);
  });

  it('should fetch all users', async () => {
    await User.create({
      username: 'alice',
      email: 'alice@example.com',
      password: '123456',
      role: 'user'
    });

    const res = await request(app).get('/api/users');
    expect(res.statusCode).toBe(200);
    expect(res.body.length).toBe(1);
  });

  it('should return 404 for non-existing user', async () => {
    const id = '507f191e810c19729de860ea'; // valid ObjectId but not in DB
    const res = await request(app).get(`/api/users/${id}`);
    expect(res.statusCode).toBe(404);
  });

  it('should delete a user by ID', async () => {
    const user = await User.create({
      username: 'bob',
      email: 'bob@example.com',
      password: '123456',
      role: 'user'
    });

    const res = await request(app).delete(`/api/users/${user._id}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('User deleted successfully');
  });
});
