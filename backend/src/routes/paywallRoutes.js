const express = require('express');
const router = express.Router();
const paywallEngine = require('../services/paywallEngine');

/**
 * @route GET /api/paywall/evaluate
 * @desc Evaluate if paywall should be shown for a specific context
 */
router.get('/evaluate', (req, res) => {
  try {
    const userId = req.query.userId || 'default';
    const context = req.query.context || 'app_open'; // "app_open", "savings_viewed", "action_completed"
    
    const evaluation = paywallEngine.evaluateTrigger(userId, context);
    
    res.json({
      success: true,
      ...evaluation
    });
  } catch (error) {
    console.error('[Paywall Routes] Evaluate Error:', error);
    res.status(500).json({ success: false, error: 'Failed to evaluate paywall' });
  }
});

/**
 * @route POST /api/paywall/interact
 * @desc Record a user's interaction with the paywall (dismiss or convert)
 */
router.post('/interact', (req, res) => {
  try {
    const { userId = 'default', action } = req.body;
    
    if (!action || !['dismiss', 'convert'].includes(action)) {
      return res.status(400).json({ success: false, error: 'Invalid action' });
    }
    
    const state = paywallEngine.recordInteraction(userId, action);
    
    res.json({
      success: true,
      state
    });
  } catch (error) {
    console.error('[Paywall Routes] Interact Error:', error);
    res.status(500).json({ success: false, error: 'Failed to record interaction' });
  }
});

module.exports = router;
