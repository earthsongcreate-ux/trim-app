const express = require('express');
const router = express.Router();
const { 
  generateDailyCheckIn, 
  generateWeeklyDigest, 
  recordEngagement, 
  getEngagementLevel 
} = require('../services/engagementEngine');
const { getTransactions } = require('../services/transactionStore');
// In a real app we'd fetch actual insights/subscriptions here. Using mocks for now to integrate with engine.

router.get('/daily', (req, res) => {
  const userId = req.headers['x-user-id'] || 'user_123';
  const transactions = getTransactions();
  
  // Minimal mock data for engine calculation
  const payload = generateDailyCheckIn({
    transactions: transactions,
    subscriptions: [],
    insights: [],
    userId
  });

  if (!payload) {
    // Usually means rate-limited (already generated today)
    return res.status(200).json({ status: 'no_new_checkin' });
  }

  res.json(payload);
});

router.get('/weekly', (req, res) => {
  const userId = req.headers['x-user-id'] || 'user_123';
  const transactions = getTransactions();

  const payload = generateWeeklyDigest({
    transactions: transactions,
    subscriptions: [{ name: 'Netflix', amount: 15.99, isUnused: true }],
    insights: [],
    userId
  });

  if (!payload) {
    return res.status(200).json({ status: 'no_new_digest' });
  }

  res.json(payload);
});

router.post('/record', (req, res) => {
  const userId = req.headers['x-user-id'] || 'user_123';
  const { isAction } = req.body;

  recordEngagement(userId, isAction);
  const newLevel = getEngagementLevel(userId);

  res.json({ success: true, engagementLevel: newLevel });
});

module.exports = router;
