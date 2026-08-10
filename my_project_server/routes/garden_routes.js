const express = require('express');
const router = express.Router();
const GardenModel = require('../models/garden');

// GET: /api/gardens/user/:userId
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const gardens = await GardenModel.getGardensByUserId(userId);
    const summary = await GardenModel.getGardenSummary(userId);

    res.json({
      success: true,
      summary: summary,
      data: gardens
    });
  } catch (error) {
    console.error('Error fetching gardens:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;