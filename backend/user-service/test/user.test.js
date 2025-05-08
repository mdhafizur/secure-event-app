"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = __importDefault(require("../src/app"));
const User_1 = __importDefault(require("../src/models/User"));
describe('User API', () => {
    it('should create a new user', async () => {
        const res = await (0, supertest_1.default)(app_1.default)
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
        await User_1.default.create({
            username: 'john',
            email: 'john@example.com',
            password: '123456',
            role: 'user'
        });
        const res = await (0, supertest_1.default)(app_1.default)
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
        await User_1.default.create({
            username: 'alice',
            email: 'alice@example.com',
            password: '123456',
            role: 'user'
        });
        const res = await (0, supertest_1.default)(app_1.default).get('/api/users');
        expect(res.statusCode).toBe(200);
        expect(res.body.length).toBe(1);
    });
    it('should return 404 for non-existing user', async () => {
        const id = '507f191e810c19729de860ea'; // valid ObjectId but not in DB
        const res = await (0, supertest_1.default)(app_1.default).get(`/api/users/${id}`);
        expect(res.statusCode).toBe(404);
    });
    it('should delete a user by ID', async () => {
        const user = await User_1.default.create({
            username: 'bob',
            email: 'bob@example.com',
            password: '123456',
            role: 'user'
        });
        const res = await (0, supertest_1.default)(app_1.default).delete(`/api/users/${user._id}`);
        expect(res.statusCode).toBe(200);
        expect(res.body.message).toBe('User deleted successfully');
    });
});
