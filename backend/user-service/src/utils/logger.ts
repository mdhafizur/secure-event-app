import winston from 'winston';
import 'winston-daily-rotate-file';
import path from 'path';

const logDir = 'logs';

const transport = new winston.transports.DailyRotateFile({
    dirname: logDir,
    filename: '%DATE%.log',
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d',
});

const customFormat = winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
        const error = new Error();
        Error.captureStackTrace(error);
        const stackInfo = error.stack?.split('\n')[3] || '';
        const match = stackInfo.match(/\((.*?):(\d+):(\d+)\)/);
        const filePath = match ? path.relative(process.cwd(), match[1]) : 'unknown';
        const lineNumber = match ? match[2] : 'unknown';
        const columnNumber = match ? match[3] : 'unknown';

        return JSON.stringify({
            timestamp,
            level,
            message,
            file: filePath,
            line: lineNumber,
            column: columnNumber,
        });
    })
);

const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.printf(({ level, message }) => {
        const error = new Error();
        Error.captureStackTrace(error);
        const stackInfo = error.stack?.split('\n')[3] || '';
        const match = stackInfo.match(/\((.*?):(\d+):(\d+)\)/);
        const filePath = match ? path.relative(process.cwd(), match[1]) : 'unknown';
        const lineNumber = match ? match[2] : 'unknown';

        return `${level}: ${message} (${filePath}:${lineNumber})`;
    })
);

const logger = winston.createLogger({
    level: 'info',
    format: customFormat,
    transports: [
        new winston.transports.Console({
            format: consoleFormat,
        }),
        transport,
    ],
});

export default logger;