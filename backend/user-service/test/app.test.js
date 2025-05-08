"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = __importDefault(require("../src/app"));
describe('GET /health', () => {
    it('should return service running', async () => {
        const res = await (0, supertest_1.default)(app_1.default).get('/health');
        expect(res.statusCode).toEqual(200);
        expect(res.text).toBe('User Service is running!');
    });
});
