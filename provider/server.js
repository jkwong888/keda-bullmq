

import express from 'express';
import { dataSchedule } from './queue.js';
import { createLogger, transports, format } from 'winston';

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();

const logger = createLogger({
  level: 'info',
  format: format.combine(
    format.timestamp({
      format: 'YYYY-MM-DD hh:mm:ss.SSS A', // 2022-01-25 03:23:10.350 PM
    }), 
    format.json(),
  ),
  transports: [new transports.Console()],
});


app.get('/', (req, res) => {
  res.send('Hello World');
});

app.post('/', async (req, res) => {
	logger.info(`Received request`);
	const job = await dataSchedule(Math.random()*100, Math.random(), 500);
	logger.info(`Scheduled job: ${job.id}`);
	res.json({jobId: job.id,});
	return;
});

app.listen(PORT, HOST, () => {
  logger.info(`Running on http://${HOST}:${PORT}`);
});