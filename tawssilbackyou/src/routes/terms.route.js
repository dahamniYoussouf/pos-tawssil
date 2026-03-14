import express from 'express';
import { getTerms } from '../controllers/terms.controller.js';

const router = express.Router();

router.get('/', getTerms);

export default router;
